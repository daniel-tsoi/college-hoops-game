#!/usr/bin/env python3
"""Curated 20-year catalog. 50 schools x 3 real player-seasons =150/year.
Source: SportsDataverse/hoopR.mbb (CC BY4.0), upstream ESPN. Ratings are estimates.
Requires duckdb==1.4.4. Raw archives stay in research; only 3,000 selected rows ship.
"""
import collections, hashlib, json, math, bisect
from pathlib import Path
import duckdb
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'src/shared/ProspectData'; OUT.mkdir(exist_ok=True)
R=ROOT/'research/prospects'
def lua(v):
 if isinstance(v,str):return json.dumps(v,ensure_ascii=False)
 if isinstance(v,bool):return 'true' if v else 'false'
 if isinstance(v,(int,float)):return str(v)
 if isinstance(v,list):return '{'+','.join(map(lua,v))+'}'
 return '{'+','.join('['+lua(k)+']='+lua(x) for k,x in v.items())+'}'
def rounded(v):return max(40,min(99,int(v+.5)))
counts=collections.Counter(); catalog=[]; audit=[]; manifest=[]
con=duckdb.connect()
for year in range(2007,2027):
 path=ROOT/f'research/data/player_box_{year}.parquet' if year>=2022 else R/f'raw/player_box_{year}.parquet'
 manifest.append({'season':year,'file':str(path.relative_to(ROOT)),'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'url':f'https://github.com/sportsdataverse/sportsdataverse-data/releases/download/espn_mens_college_basketball_player_boxscores/player_box_{year}.parquet'})
 con.execute(f'create or replace view raw as select * from "{path}"')
 # Candidate D1 teams have season-length schedules; avoids occasional lower-division opponents.
 # A fixed source threshold is disclosed, not claimed to be full NCAA membership certification.
 cols={'minutes':'min','points':'pts','rebounds':'reb','assists':'ast','steals':'stl','blocks':'blk','turnovers':'tov','fouls':'pf','field_goals_made':'fgm','field_goals_attempted':'fga','free_throws_made':'ftm','free_throws_attempted':'fta','three_point_field_goals_made':'tpm','three_point_field_goals_attempted':'tpa'}
 fields=','.join(f'sum(coalesce({k},0)) as {v}' for k,v in cols.items())
 sql=f'''with teams as (select team_id,count(distinct game_id) teamGames from raw group by team_id having teamGames>=20),
 clean as (select r.* from raw r join teams t on r.team_id=t.team_id where r.athlete_id is not null and r.athlete_display_name is not null and r.did_not_play=false qualify row_number() over(partition by game_id,r.team_id,athlete_id order by minutes desc)=1)
 select athlete_id,team_id,mode(athlete_display_name) as playerName,mode(team_location) school,
 mode(athlete_position_abbreviation) as "position",mode(athlete_jersey) jersey,mode(team_color) color,
 count(*) gp,{fields} from clean group by athlete_id,team_id having gp>=5 and min>=50'''
 q=con.execute(sql);keys=[x[0] for x in q.description];allrows=[dict(zip(keys,row)) for row in q.fetchall()]
 for x in allrows:
  m=x['min'];gp=x['gp']; rel=m/(m+200)
  x['impact']=(x['pts']+1.2*x['reb']+1.5*x['ast']+2*x['stl']+2*x['blk']-x['tov']-(x['fga']-x['fgm']))/gp
  pos=x['position']
  if pos=='G':pos='PG' if x['ast']/gp>=2.5 else 'SG'
  elif pos=='F':pos='SF' if x['tpa']/max(x['fga'],1)>=.25 else 'PF'
  if pos not in ['PG','SG','SF','PF','C']:pos='SF'
  x['gamePosition']=pos
  two=(x['fgm']-x['tpm']+25)/(x['fga']-x['tpa']+50)
  ft=(x['ftm']+21)/(x['fta']+30);three=(x['tpm']+17)/(x['tpa']+50)
  x['features']={'midRange':.65*two+.35*ft,'threePoint':.65*three+.35*min(1,x['tpa']/max(m,1)*40/8),
    'drivingDunk':rel*(x['blk']+x['reb']*.12+x['fta']*.12)*40/max(m,1)+(1-rel)*2,
    'perimeterDefense':rel*(x['stl']*2+x['blk']*.3-x['pf']*.12)*40/max(m,1)+(1-rel)*1.5,
    'ballHandle':rel*(x['ast']*1.5-x['tov']*.5)*40/max(m,1)+(1-rel)*3,
    'stamina':min(1,m/gp/40),'impact':x['impact']}
 featureRanks={k:sorted(x['features'][k] for x in allrows) for k in allrows[0]['features']}
 def pct(k,val):
  values=featureRanks[k];return (bisect.bisect_left(values,val)+bisect.bisect_right(values,val))/(2*len(values))
 teams=collections.defaultdict(list)
 for x in allrows: teams[x['team_id']].append(x)
 teams={k:sorted(v,key=lambda x:(-x['impact'],-x['min'],x['athlete_id'])) for k,v in teams.items() if len(v)>=3}
 merit=sorted(teams,key=lambda k:(-teams[k][0]['impact'],k))[:25]
 rotation=sorted((k for k in teams if k not in merit),key=lambda k:(counts[k],-teams[k][0]['impact'],k))[:25]
 assert len(merit+rotation)==50
 chosen=[]
 for tid in merit+rotation:
  counts[tid]+=1;pool=teams[tid]
  # One impact leader, one median rotation player, one lower-workload player.
  selected=[pool[0],pool[len(pool)//2],pool[-1]]
  assert len({x['athlete_id'] for x in selected})==3
  for x in selected:
   ratings={k:rounded(40+59*pct(k,v)) for k,v in x['features'].items() if k not in ['stamina','impact']}
   ratings['stamina']=rounded(40+59*x['features']['stamina'])
   ratings['speed']={'PG':84,'SG':80,'SF':75,'PF':67,'C':59}[x['gamePosition']]
   overall=rounded(40+59*pct('impact',x['impact']))
   if x['min']<200:overall=min(overall,64)
   rarity='Common' if overall<65 else 'Rare' if overall<80 else 'Epic' if overall<90 else 'Legendary'
   season=f'{year-1}-{str(year)[2:]}'
   color=str(x['color'] or '405bc8').lstrip('#')
   if len(color)!=6:color='405bc8'
   try:int(color,16)
   except ValueError:color='405bc8'
   card={'id':f"prospect-{year}-{tid}-{x['athlete_id']}",'playerId':str(x['athlete_id']),
     'name':x['playerName'],'school':x['school'],'schoolId':str(tid),'season':season,'year':year,
     'position':x['gamePosition'],'sourcePosition':x['position'] or 'Unknown','overall':overall,'rarity':rarity,
     'ratings':ratings,'attributes':{'shooting':rounded((ratings['midRange']+ratings['threePoint'])/2),'dribbling':ratings['ballHandle'],'defense':ratings['perimeterDefense'],'speed':ratings['speed'],'stamina':ratings['stamina']},
     'appearance':{'jersey':str(x['jersey'] or '?'),'teamColor':color,'style':x['athlete_id']%3,'kind':'STYLIZED_NOT_VERIFIED_LIKENESS'},
     'stats':{'gamesPlayed':x['gp'],'minutes':x['min'],'points':x['pts'],'ppg':round(x['pts']/x['gp'],1),'fgPercent':round(x['fgm']/max(x['fga'],1)*100,1),'threePercent':round(x['tpm']/max(x['tpa'],1)*100,1),'freeThrowPercent':round(x['ftm']/max(x['fta'],1)*100,1)},
     'ratingStatus':'ESTIMATED','sourceId':f'sdv-box-{year}'}
   chosen.append(card)
 chosen.sort(key=lambda c:(-c['overall'],c['name'],c['id']))
 assert len(chosen)==150
 assert set(collections.Counter(c['schoolId'] for c in chosen).values())=={3}
 catalog+=chosen
 audit.append({'year':year,'season':season,'players':150,'schools':50,'playersPerSchool':3,'sourceCandidates':len(allrows)})
 (OUT/f'Season{year}.luau').write_text('--!strict\n-- SportsDataverse / hoopR.mbb, CC BY4.0. Derived game ratings, not scouting measurements.\nlocal Types = require(script.Parent.Parent.ProspectTypes)\nlocal rows: {Types.Prospect} = {\n'+''.join(' '+lua(c)+',\n' for c in chosen)+'}\nreturn rows\n')
 print(year,'selected',len(chosen),'candidate players',len(allrows),flush=True)
(R/'catalog.json').write_text(json.dumps(catalog,ensure_ascii=False,indent=2)+'\n')
(R/'manifest.json').write_text(json.dumps({'license':'CC BY4.0','attribution':'SportsDataverse / hoopR.mbb authors, upstream ESPN','licenseUrl':'https://creativecommons.org/licenses/by/4.0/','sources':manifest},indent=2)+'\n')
(R/'coverage.json').write_text(json.dumps({'total':len(catalog),'uniqueSchools':len(counts),'seasons':audit,'schoolAppearances':dict(counts)},indent=2)+'\n')
