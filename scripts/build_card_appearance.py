"""Import existing jersey metadata; visual fallbacks are explicit in CardAppearance."""
import json
from pathlib import Path
root=Path(__file__).resolve().parents[1]
rows=json.loads((root/'research/prospects/catalog.json').read_text())
meta={}; schools={}
for row in rows:
 a=row.get('appearance',{}); color=a.get('teamColor','').strip().lstrip('#')
 if len(color)!=6: continue
 key='|'.join([row['name'],row['school'],row['season']])
 number=a.get('jersey','').strip()
 meta[key]=[number,color]
 schools[row['school']]=color
q=lambda v:json.dumps(v,ensure_ascii=False)
lines=['-- Generated from existing prospect appearance metadata. Do not hand edit.','return { players = {']
for key,val in sorted(meta.items()): lines.append(f' [{q(key)}] = {{{q(val[0])}, {q(val[1])}}},')
lines.append('}, schools = {')
for key,val in sorted(schools.items()): lines.append(f' [{q(key)}] = {q(val)},')
lines.append('} }')
(root/'src/shared/CardArt/JerseyMetadata.luau').write_text('\n'.join(lines)+'\n')
print(f'Imported {len(meta)} player-season jerseys and {len(schools)} school colors')
