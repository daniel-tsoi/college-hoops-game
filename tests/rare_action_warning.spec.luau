local T=require('../src/ServerScriptService/Shop/Transactions')
local Rules=require('../src/StarterPlayer/StarterPlayerScripts/RareActionRules')
local serde=require('@lune/serde')
local roundtrip=function(p) return serde.decode('json',serde.encode('json',p)) end
local draws={PG={id='college',goldRoll=100}}
local team={school='Test',season='2025'}
for _,kind in ipairs({'HOF','NonCollege'}) do
 local rare={[kind]={id=kind,position='PG',goldRoll=1}}
 local p=T.startSession(T.newProfile(100),'s',1)
 p.shopUnlocked[kind]=true
 p=T.rollAction(p,'RollState',nil,draws,team,rare)
 for _,action in ipairs({'RerollPlayer','RestartRoll'}) do
  assert(Rules.warning(action,p.rollDraft),'Rare hit must prompt before '..action)
  local no={snapshot=p.rollDraft}
  assert(not Rules.consume(no,p.rollDraft,false),'No cancels')
  assert(not Rules.consume(no,p.rollDraft,true),'Cancelled warning cannot later execute')
  local yes={snapshot=p.rollDraft}
  assert(Rules.consume(yes,p.rollDraft,true))
  assert(not Rules.consume(yes,p.rollDraft,true),'Double Yes executes once')
  assert(not Rules.consume({snapshot=p.rollDraft},roundtrip(p).rollDraft,true),'Changed draft invalidates consent')
 end
 for _,action in ipairs({'RefreshRoll','NextRoll'}) do
  assert(not Rules.warning(action,p.rollDraft),action..' must proceed without confirmation')
 end
 local refreshed,code=T.rollAction(p,'RefreshRoll',nil,{PG={id='different',goldRoll=99}},team,{})
 assert(code=='REFRESHED' and refreshed.freeRollRefreshes==p.freeRollRefreshes-1)
 local loaded=roundtrip(refreshed)
 assert(loaded.rollDraft.rare[kind].id==kind and loaded.rollDraft.rare[kind].goldRoll==1)
 assert(loaded.rollDraft.rareRoll==p.rollDraft.rareRoll and not loaded.owned[kind])
 local accepted=T.rollAction(loaded,'ChooseRare',kind)
 assert(accepted.owned[kind] and accepted.goldOwned[kind],'Preserved result is still claimable')
 assert(not Rules.warning('RerollPlayer',accepted.rollDraft),'Accepted wheel result must not trigger reroll warning')
 assert(not Rules.warning('RefreshRoll',accepted.rollDraft),'Accepted wheel result must not trigger refresh warning')
 assert(Rules.warning('RestartRoll',accepted.rollDraft),'Restart clears the selected rare card')
 assert(not Rules.warning('RerollPlayer',roundtrip(accepted).rollDraft),'Selected identity matching survives serialization')
 -- The client receives card metadata, not the stored gold-roll entries.
 for _,withSixth in ipairs({false,true}) do
  local squad={PG={id=kind,rarity=kind}}
  for _,pos in ipairs({'SG','SF','PF','C'}) do squad[pos]={id=pos,school='Test'} end
  if withSixth then squad.SIXTH={id='sixth',school='Test'} end
  local completed={finished=true,squad=squad,rare=rare,sixthDeclined=not withSixth}
  assert(Rules.warning('RestartRoll',completed),'Restart warns before clearing a completed rare squad')
  assert(Rules.warning('RestartRoll',roundtrip(completed)),'Selected rare warning survives reload')
  completed.finished=false
  assert(Rules.warning('RestartRoll',completed),'Unfinished rare drafts still require confirmation')
  assert(not Rules.warning('RerollPlayer',completed),'Matching selected wheel card does not warn')
  completed.rare={}
  assert(not Rules.warning('RerollPlayer',completed),'Rare squad alone never warns on reroll')
  assert(Rules.warning('RestartRoll',completed),'Accepted rare squad cards still warn before completion')
 end
 for _,action in ipairs({'RerollPlayer','RestartRoll'}) do
  local replaced=T.rollAction(p,action,nil,draws,team,{})
  assert(next(replaced.rollDraft.rare)==nil and replaced.rollDraft.rareRoll==p.rollDraft.rareRoll+1)
  assert(p.rollDraft.rare[kind].id==kind,'No mutation of old rare results')
 end
 for _,action in ipairs({'NextRoll','RestartRoll'}) do
  local replaced=T.rollAction(accepted,action,nil,draws,team,{})
  assert(next(replaced.rollDraft.rare)==nil and replaced.owned[kind] and replaced.goldOwned[kind])
 end
 -- Rejected refresh spends nothing and preserves the rare hit.
 p.freeRollRefreshes=0;p.refreshes=0;p.paidRefreshes=0
 local rejected,status=T.rollAction(p,'RefreshRoll',nil,draws,team,{})
 assert(rejected==p and status=='EMPTY' and rejected.rollDraft.rare[kind])
end
assert(not Rules.warning('RestartRoll',{rare={},squad={}}))
assert(not Rules.warning('ChooseRare',{rare={HOF={id='h'}}}))
assert(not Rules.consume(nil,{},true))
print('PASS: HOF/non-college Restart/Reroll Yes/No; Refresh/Roll without prompts, duplicate/stale consent, Refresh retains claimable gold results across serde, Roll/Reroll/Restart replace results, ownership survives, failed Refresh preserves state')

local mixed={squad={PG={id='h',rarity='HOF'}},rare={HOF={id='h'},NonCollege={id='n'}}}
assert(Rules.warning('RerollPlayer',mixed),'An unselected second rare hit still warns')
assert(not Rules.warning('RefreshRoll',mixed),'Refresh retains the unselected second hit')
mixed.squad.SG={id='n',sourceType='NON_COLLEGE',rarity='All-Star'}
assert(not Rules.warning('RerollPlayer',mixed),'Both selected hits suppress reroll warning')
mixed.rare={}
assert(Rules.warning('RestartRoll',mixed),'Source metadata identifies accepted non-college cards')
assert(Rules.warning('RestartRoll',{squad={PG={id='n',sourceType='NON_COLLEGE',rarity='All-Star'}}}))
assert(not Rules.warning('RestartRoll',{squad={PG={id='ordinary',rarity='Common'}}}),'Missing school alone does not make a card rare')
print('PASS: selected rare results skip Reroll/Refresh; Restart warns for selected rares including completed squads; mixed hits and non-college metadata handled')
