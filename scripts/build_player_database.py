#!/usr/bin/env python3
"""Rebuild game-owned ratings from pinned, attributed SportsDataverse box scores.
Requires Python 3.9+ and duckdb==1.4.4. No network or gameplay operations.
"""
import bisect
import collections
import hashlib
import json
import math
from pathlib import Path
import duckdb

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / 'research/data'
SHARED = ROOT / 'src/shared'
SHARDS = SHARED / 'PlayerData'
MODEL = 'boxscore-five-attributes-v1'
YEARS = range(2022, 2027)
EXPECTED_TEAMS = {2022:358, 2023:363, 2024:362, 2025:364, 2026:365}
KEYS = {
    'minutes':'minutes', 'field_goals_made':'fgm', 'field_goals_attempted':'fga',
    'three_point_field_goals_made':'threeMade', 'three_point_field_goals_attempted':'threeAttempted',
    'free_throws_made':'ftm', 'free_throws_attempted':'fta',
    'offensive_rebounds':'offensiveRebounds', 'defensive_rebounds':'defensiveRebounds',
    'rebounds':'rebounds', 'assists':'assists', 'steals':'steals', 'blocks':'blocks',
    'turnovers':'turnovers', 'fouls':'fouls', 'points':'points',
}
ATTRS = ['shooting','dribbling','defense','speed','stamina']
WEIGHTS = {'PG':[.25,.30,.15,.15,.15], 'SG':[.35,.20,.20,.15,.10],
           'SF':[.25,.15,.30,.15,.15], 'PF':[.20,.10,.40,.10,.20], 'C':[.15,.05,.50,.10,.20]}
MULTIPLIERS = {'Common':1,'Rare':1.05,'Epic':1.10,'Legendary':1.15,'All-Star':1.20,'HOF':1.25}
SPEED_PRIOR = {'PG':82,'SG':78,'SF':73,'PF':66,'C':58}


def dump(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2, allow_nan=False)+'\n')


def integer(v):
    return math.floor(v + .5)


def percentile(values, v):
    return (bisect.bisect_left(values,v)+bisect.bisect_right(values,v)) / (2*len(values))


def luau(value):
    if value is None: return 'nil'
    if isinstance(value,bool): return 'true' if value else 'false'
    if isinstance(value,str): return json.dumps(value,ensure_ascii=False)
    if isinstance(value,(int,float)): return str(value)
    if isinstance(value,list): return '{ '+', '.join(luau(v) for v in value)+' }'
    return '{ '+', '.join(f'[{luau(k)}] = {luau(v)}' for k,v in value.items() if v is not None)+' }'


def rows(query, con):
    out=con.execute(query)
    keys=[d[0] for d in out.description]
    return [dict(zip(keys,row)) for row in out.fetchall()]


def main():
    con=duckdb.connect()
    cards=[]; schools=[]; audit=[]; roster_only=[]; fingerprints=[]; corrections=[]
    overrides=json.loads((DATA/'official_overrides.json').read_text())
    for year in YEARS:
        path=DATA/f'player_box_{year}.parquet'
        fingerprints.append({'season':year,'file':str(path.relative_to(ROOT)),
            'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),
            'sourceUrl':f'https://github.com/sportsdataverse/sportsdataverse-data/releases/download/espn_mens_college_basketball_player_boxscores/player_box_{year}.parquet'})
        con.execute(f"create or replace view raw as select * from '{path}'")
        # Season-length schedules identify candidates; transitions and expected totals
        # are audited in research. This is not an independent membership certification.
        teams=rows('select team_id, mode(team_location) school, mode(team_display_name) teamName, count(distinct game_id) games from raw group by team_id having games >= 20 order by team_id',con)
        assert len(teams)==EXPECTED_TEAMS[year],(year,len(teams))
        team_ids={t['team_id'] for t in teams}
        membership=','.join(str(i) for i in sorted(team_ids))
        # Never reinterpret the present-day "active" flag as historical participation.
        con.execute(f'create or replace view valid as select * from raw where team_id in ({membership}) and athlete_id is not null and athlete_display_name is not null')
        assert con.sql('select count(*)-count(distinct (game_id,team_id,athlete_id)) from valid').fetchone()[0]==0
        for source_col in KEYS:
            assert con.sql(f'select count(*) from valid where not did_not_play and ({source_col} is null or {source_col}<0)').fetchone()[0]==0, (year,source_col)
        sums=', '.join(f'sum({src}) as "{dest}"' for src,dest in KEYS.items())
        aggregates=rows(f'''select athlete_id, team_id, mode(athlete_display_name) player_name,
            mode(athlete_position_abbreviation) source_position, count(*) gamesPlayed,
            sum(case when starter then 1 else 0 end) gamesStarted, {sums}
            from valid where did_not_play=false group by athlete_id,team_id order by team_id,athlete_id''',con)
        no_appearance=rows('''select athlete_id,team_id,mode(athlete_display_name) player_name
            from valid group by athlete_id,team_id having count(*) filter(where did_not_play=false)=0''',con)
        roster_only.extend(dict(r,season=year,reason='NO_RECORDED_APPEARANCE') for r in no_appearance)
        per_team=collections.defaultdict(list)
        for row in aggregates: per_team[row['team_id']].append(row)
        for team in teams:
            season=f'{year-1}-{str(year)[2:]}'
            sid=f"espn-{team['team_id']}-{season}"
            school={'id':sid,'school':team['school'],'teamName':team['teamName'],'season':season,
                'sourceTeamId':str(team['team_id']),'recordedGames':team['games'],'rosterCardIds':[],
                'allStarCardIds':[], 'coverageStatus':'BOX_SCORES_IMPORTED_NOT_FULLY_AUDITED'}
            schools.append(school)
            for row in per_team[team['team_id']]:
                stats={k:row[k] for k in ['gamesPlayed','gamesStarted',*KEYS.values()]}
                for k,v in stats.items():
                    if isinstance(v,float) and v.is_integer(): stats[k]=int(v)
                assert stats['fgm']<=stats['fga'] and stats['threeMade']<=stats['threeAttempted'] and stats['ftm']<=stats['fta']
                card_id=f"college-{row['athlete_id']}-{team['team_id']}-{year}"
                override=overrides.get(card_id)
                if override:
                    for key,value in override['stats'].items():
                        if stats[key]!=value:
                            corrections.append({'cardId':card_id,'field':key,'feedValue':stats[key],
                                'officialValue':value,'sourceUrl':override['sourceUrl']})
                        stats[key]=value
                src=row['source_position'] or 'UNKNOWN'
                if src in WEIGHTS: pos=src; confidence='SOURCE'
                elif src=='G':
                    pos='PG' if stats['assists']/max(stats['gamesPlayed'],1)>=2.5 else 'SG';confidence='ESTIMATED'
                elif src=='F':
                    pos='SF' if stats['threeAttempted']/max(stats['fga'],1)>=.25 else 'PF';confidence='ESTIMATED'
                else: pos='SF';confidence='LOW'
                card={'id':f"college-{row['athlete_id']}-{team['team_id']}-{year}",
                    'playerId':f"espn-{row['athlete_id']}",'name':row['player_name'],
                    'position':pos,'sourcePosition':src,'positionConfidence':confidence,
                    'sourceType':'COLLEGE','acquisition':'SCHOOL_SEASON','ratingStatus':'DERIVED_ESTIMATE',
                    'ratingModelVersion':MODEL,'dataConfidence':'LOW' if stats['minutes']<200 else 'MEDIUM',
                    'schoolSeasonId':sid,'school':team['school'],'season':season,
                    'sourceId':f'sdv-box-{year}','sourceStats':stats,'variant':'BASE',
                    'speedBasis':'POSITION_PRIOR_NOT_MEASURED','eligiblePositions':[pos]}
                if override: card['sourceUrls']=[override['sourceUrl']]
                school['rosterCardIds'].append(card['id']);cards.append(card)
        audit.append({'season':year,'schoolSeasons':len(teams),'playerSeasons':len(aggregates),
            'rawRows':con.sql('select count(*) from raw').fetchone()[0],
            'missingIdentityRows':con.sql(f'select count(*) from raw where team_id in ({membership}) and (athlete_id is null or athlete_display_name is null)').fetchone()[0],
            'rosterOnlyExcluded':len(no_appearance),
            'lastGame':str(con.sql('select max(game_date) from raw').fetchone()[0]),
            'membershipMethod':'20+ recorded games, expected counts and transition audit; full independent membership audit pending'})
    # Empirical rank model, separately within season/position; low-minute rate
    # estimates shrink toward group priors. A role prior is not measured speed.
    groups=collections.defaultdict(list)
    for card in cards: groups[(card['season'],card['position'])].append(card)
    school_by_id={s['id']:s for s in schools}
    for group in groups.values():
        totals={k:sum(c['sourceStats'][k] for c in group) for k in KEYS.values()}
        def pct_prior(num,den):return totals[num]/max(totals[den],1)
        for c in group:
            s=c['sourceStats'];m=s['minutes'];gp=s['gamesPlayed'];tg=school_by_id[c['schoolSeasonId']]['recordedGames']
            reliability=m/(m+200)
            def rate(stat):return reliability*s[stat]*40/max(m,1)+(1-reliability)*totals[stat]*40/max(totals['minutes'],1)
            three=(s['threeMade']+50*pct_prior('threeMade','threeAttempted'))/(s['threeAttempted']+50)
            ft=(s['ftm']+30*pct_prior('ftm','fta'))/(s['fta']+30)
            efg=(s['fgm']+.5*s['threeMade']+100*(totals['fgm']+.5*totals['threeMade'])/max(totals['fga'],1))/(s['fga']+100)
            # Raw feature units are combined only after normalization below.
            c['_features']={'threePct':three,'threeVolume':rate('threeAttempted'),'ftPct':ft,'efg':efg,
                'assists':rate('assists'),'assistTurnover':(s['assists']+10)/(s['turnovers']+10),
                'ballSecurity':-(s['turnovers']+10)/(s['fga']+.44*s['fta']+s['assists']+s['turnovers']+50),
                'steals':rate('steals'),'blocks':rate('blocks'),'dreb':rate('defensiveRebounds'),
                'discipline':-rate('fouls'),'workload':min(m/max(gp,1)/40,1),'availability':gp/tg,
                'production':(s['points']+1.2*s['rebounds']+1.5*s['assists']+2*s['steals']+2*s['blocks']-s['turnovers']-(s['fga']-s['fgm'])-.5*(s['fta']-s['ftm']))/tg}
        sorted_features={k:sorted(c['_features'][k] for c in group) for k in group[0]['_features']}
        for c in group:
            f={k:percentile(sorted_features[k],v) for k,v in c['_features'].items()}
            scores={'shooting':.35*f['threePct']+.30*f['threeVolume']+.20*f['ftPct']+.15*f['efg'],
                'dribbling':.40*f['assists']+.35*f['assistTurnover']+.25*f['ballSecurity'],
                'defense':.30*f['steals']+.30*f['blocks']+.25*f['dreb']+.15*f['discipline'],
                'stamina':.75*c['_features']['workload']+.25*c['_features']['availability']}
            c['attributes']={k:integer(40+59*v) for k,v in scores.items()}
            c['attributes']['speed']=SPEED_PRIOR[c['position']]
            weighted=sum(c['attributes'][a]*w for a,w in zip(ATTRS,WEIGHTS[c['position']]))
            c['_appraisal']=.65*weighted+.35*(40+59*f['production'])
        appraisal=sorted(c['_appraisal'] for c in group)
        for c in group:
            c['overall']=min(99,max(40,integer(40+59*percentile(appraisal,c['_appraisal']))))
            # Sparse appearances cannot imply elite ability from normalized priors.
            c['overall']=min(c['overall'],64 if c['sourceStats']['minutes']<200 else 79 if c['sourceStats']['minutes']<500 else 99)
            c['rarity']='Common' if c['overall']<=64 else 'Rare' if c['overall']<=79 else 'Epic' if c['overall']<=89 else 'Legendary'
            c['statMultiplier']=MULTIPLIERS[c['rarity']]
            del c['_features'];del c['_appraisal']
    # Explicit season-performance All-Star variants, not retrospective prospect
    # potential. Eligibility is conservative and recorded, never every roster member.
    all_stars=[]
    for c in cards:
        if c['overall']>=97 and c['sourceStats']['minutes']>=500 and c['sourceStats']['gamesPlayed']>=15:
            star=dict(c,id='all-star-'+c['id'],baseCardId=c['id'],rarity='All-Star',variant='ALL_STAR_SEASON',
                overall=100+c['overall']-97,statMultiplier=MULTIPLIERS['All-Star'],
                eligibilityBasis='SEASON_OVR_97_PLUS_500_MINUTES_15_GAMES')
            all_stars.append(star);school_by_id[c['schoolSeasonId']]['allStarCardIds'].append(star['id'])
    # Preserve the exact research-backed identity whitelist, with explicitly manual
    # special-card ceilings. These are game balance appraisals, not historical stats.
    specials=json.loads((DATA/'special_players.json').read_text())
    for c in specials['hof']+specials['nonCollege']:
        c['ratingModelVersion']='manual-special-archetypes-v1'
        c['ratingStatus']='MANUAL_ESTIMATE';c['dataConfidence']='LOW'
        c['speedBasis']='MANUAL_ARCHETYPE_NOT_MEASURED'
        c['playerId']='legacy-'+c['id'].replace('hof-','').replace('non-college-','')
        c['variant']='HOF' if c['sourceType']=='LEGACY_HOF' else 'NON_COLLEGE'
        c['eligiblePositions']=c.get('eligiblePositions',[c['position']])
        c['positionConfidence']='ESTIMATED'
        if c['sourceType']=='NON_COLLEGE': c['rarity']='All-Star';c['defaultUnlocked']=False
    cards.sort(key=lambda c:c['id']);all_stars.sort(key=lambda c:c['id'])
    all_cards=cards+all_stars+specials['hof']+specials['nonCollege']
    assert len({c['id'] for c in all_cards})==len(all_cards)
    byid={c['id']:c for c in cards}
    # Legal lineup coverage by bipartite matching. Do not fabricate secondary roles
    # to force a school-season into the release pool.
    def legal_lineup(school):
        assigned={}
        def match(pos,seen):
            for ident in school['rosterCardIds']:
                if pos not in byid[ident]['eligiblePositions'] or ident in seen:continue
                seen.add(ident)
                if ident not in assigned or match(assigned[ident],seen):assigned[ident]=pos;return True
            return False
        return all(match(pos,set()) for pos in WEIGHTS)
    for school in schools:
        school['hasLegalLineup']=legal_lineup(school)
        school['hasAllStarPool']=bool(school['allStarCardIds'])
        school['releaseReady']=False # source coverage, positions and ratings still need review
    # Committed aggregates keep the transformation independently inspectable.
    dump(DATA/'rated_player_seasons.json',cards)
    dump(DATA/'school_seasons.json',schools)
    dump(DATA/'all_star_variants.json',all_stars)
    dump(DATA/'roster_only_exclusions.json',roster_only)
    dump(DATA/'applied_corrections.json',corrections)
    dump(DATA/'source_manifest.json',{'modelVersion':MODEL,'attribution':'SportsDataverse / hoopR.mbb authors, upstream ESPN',
        'license':'CC BY 4.0','licenseUrl':'https://creativecommons.org/licenses/by/4.0/',
        'changes':'Deduplication checks, D1 candidate filtering, player-school-season aggregation, game-owned estimates and Luau generation.',
        'files':fingerprints})
    summary={'modelVersion':MODEL,'seasons':audit,'baseCards':len(cards),'allStarVariants':len(all_stars),
        'hofCards':len(specials['hof']),'nonCollegeCards':len(specials['nonCollege']),
        'schoolSeasons':len(schools),'completeIndividualVerification':False,
        'schoolsWithoutAllStar':sum(not s['hasAllStarPool'] for s in schools),
        'schoolsWithoutLegalLineup':sum(not s['hasLegalLineup'] for s in schools),
        'ratingCounts':dict(collections.Counter(c['rarity'] for c in cards))}
    dump(DATA/'coverage_summary.json',summary)
    # Small shards avoid Luau constant/instruction limits and giant single modules.
    SHARDS.mkdir(exist_ok=True)
    for f in SHARDS.glob('Generated*.luau'): f.unlink()
    def emit_pool(prefix,pool):
        names=[]
        for start in range(0,len(pool),200):
            name=f'Generated{prefix}{start//200+1:03d}';names.append(name)
            text='--!strict\n-- Generated by scripts/build_player_database.py; see research/data/source_manifest.json.\nlocal Types = require(script.Parent.Parent.PlayerTypes)\nlocal Rarity = Types.Rarity\nlocal entries: { Types.Player } = {\n'
            for c in pool[start:start+200]:
                rendered=luau(c)
                rendered=rendered.replace('["rarity"] = '+luau(c['rarity']),'["rarity"] = Rarity.'+('AllStar' if c['rarity']=='All-Star' else c['rarity']))
                text+='    '+rendered+',\n'
            text+='}\nreturn entries\n';(SHARDS/(name+'.luau')).write_text(text)
        return names
    pools={name:emit_pool(name,pool) for name,pool in [('College',cards),('AllStar',all_stars),('HOF',specials['hof']),('NonCollege',specials['nonCollege'])]}
    imports='--!strict\n-- Generated shard index.\nlocal Types = require(script.Parent.PlayerTypes)\n'
    for name,names in pools.items():
        imports+=f'local {name}: {{ {{ Types.Player }} }} = {{\n'+''.join(f'    require(script.Parent.PlayerData.{n}),\n' for n in names)+'}\n'
    imports+='return { '+', '.join(f'{n} = {n}' for n in pools)+' }\n'
    (SHARED/'PlayerDataIndex.luau').write_text(imports)
    # School records are compact enough to shard by season, with one typed index.
    for year in YEARS:
        season=f'{year-1}-{str(year)[2:]}'
        pool=[s for s in schools if s['season']==season]
        (SHARDS/f'GeneratedSchools{year}.luau').write_text('--!strict\nlocal Types = require(script.Parent.Parent.PlayerTypes)\nlocal entries: { Types.SchoolSeason } = {\n'+''.join('    '+luau(s)+',\n' for s in pool)+'}\nreturn entries\n')
    print(json.dumps(summary,indent=2))

if __name__=='__main__': main()
