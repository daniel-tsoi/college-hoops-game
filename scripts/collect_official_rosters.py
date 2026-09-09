#!/usr/bin/env python3
"""Cache and extract official rosters. Never accept a page for another season.
Usage: PYTHONPATH=/private/tmp/hoops-research-python python3 scripts/collect_official_rosters.py
Requires beautifulsoup4. School URLs come from research/prospects/scope.json.
Missing/unsupported pages remain explicit errors in official/coverage.json.
"""
import concurrent.futures, hashlib, json, re, urllib.request
from pathlib import Path
from bs4 import BeautifulSoup
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'research/prospects/official'

def extract(html, year, url):
 s=BeautifulSoup(html,'html.parser'); title=s.title.get_text() if s.title else ''
 season=f'{year-1}-{str(year)[2:]}'
 if season not in title and f'{year-1}-{year}' not in title:
  raise ValueError(f'Season mismatch: {title}')
 rows=[];seen=set()
 for item in s.select('[data-test-id="s-person-details__root"]'):
  link=item.select_one('[data-test-id="s-person-details__personal-single-line-person-link"]')
  if not link or '/roster/' not in link.get('href',''):continue
  if any(segment in link['href'] for segment in ['/coaches/', '/staff/']):continue
  def field(key):
   e=item.select_one(f'[data-test-id="s-person-details__bio-stats-person-{key}"]')
   if e is None:return None
   for label in e.select('.sr-only'):label.decompose()
   return e.get_text(' ',strip=True) or None
  name=link.get_text(' ',strip=True)
  if name in seen:continue
  seen.add(name)
  label=link.get('aria-label',''); number=re.search(r'jersey number (.*?) full bio',label)
  rows.append({'name':name,'jersey':number.group(1) if number else None,'position':field('position-short'),
   'height':field('season'),'weight':field('weight'),'academicYear':field('title'),
   'bioUrl':urllib.parse.urljoin(url,link['href'])})
 if len(rows)<8:raise ValueError(f'Only {len(rows)} players parsed; manual review required')
 return rows,title

def collect(job):
 school,year=job;season=f'{year-1}-{str(year)[2:]}'
 url=school['rosterUrl'].format(season=season,year=year,start=year-1)
 path=OUT/f"{school['id']}-{year}.html"
 record={'school':school['name'],'schoolId':school['id'],'year':year,'season':season,'url':url}
 try:
  if not path.exists():
   request=urllib.request.Request(url,headers={'User-Agent':'Mozilla/5.0 (compatible; roster research)'})
   with urllib.request.urlopen(request,timeout=40) as response:
    content=response.read();path.write_bytes(content)
  content=path.read_bytes();rows,title=extract(content,year,url)
  record.update(status='verified-season-page',title=title,players=rows,count=len(rows),sha256=hashlib.sha256(content).hexdigest())
 except Exception as e:record.update(status='needs-review',error=str(e),players=[],count=0)
 print(school['name'],year,record['status'],record['count'],flush=True)
 return record

def main():
 OUT.mkdir(parents=True,exist_ok=True)
 scope=json.loads((ROOT/'research/prospects/scope.json').read_text())
 jobs=[(s,y) for s in scope['schools'] for y in scope['years']]
 with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool: records=list(pool.map(collect,jobs))
 (OUT/'coverage.json').write_text(json.dumps(records,indent=2,ensure_ascii=False)+'\n')
 print('Verified',sum(r['status']=='verified-season-page' for r in records),'of',len(records))
if __name__=='__main__':main()
