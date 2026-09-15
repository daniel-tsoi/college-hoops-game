local T=require('../src/ServerScriptService/Shop/Transactions')
local serde=require('@lune/serde')
local fs=require('@lune/fs')
local luau=require('@lune/luau')
for _,kind in ipairs({'HOF','NonCollege'}) do
 local p=T.startSession(T.newProfile(100),'s',0)
 p.shopUnlocked.rare=true
 local draws={PG={id='pg',goldRoll=100},SG={id='sg',goldRoll=100}}
 p=T.rollAction(p,'RollState',nil,draws,{key='team'})
 p=T.rollAction(p,'RollPlayer','PG')
 p=T.rollAction(p,'NextRoll',nil,draws,{key='team'},{[kind]={id='rare',position='PG',goldRoll=1}})
 p=serde.decode('json',serde.encode('json',p))
 local before=serde.encode('json',p)
 for _=1,3 do
  local rejected,code=T.rollAction(p,'ChooseRare',kind)
  assert(code=='FILLED' and rejected==p)
  assert(p.rollDraft.squad.PG.id=='pg' and not p.owned.rare and not p.goldOwned.rare)
  assert(p.rollDraft.pickAvailable and p.sessionUnlocks==1)
  local blocked,status=T.rollAction(p,'NextRoll',nil,draws,{key='next'})
  assert(status=='CHOOSE_FIRST' and blocked==p)
 end
 assert(serde.encode('json',p)==before,'Rejected actions must preserve draft, balances and ownership')
 p=T.rollAction(p,'RollPlayer','SG')
 assert(p.rollDraft.squad.SG.id=='sg' and p.rollDraft.squad.PG.id=='pg')
 assert(not p.rollDraft.pickAvailable and not p.owned.rare)
 local nextRoll,code=T.rollAction(p,'NextRoll',nil,draws,{key='next'})
 assert(code=='READY' and nextRoll.rollDraft.pickAvailable)
 -- A rare card remains selectable when its position is actually free.
 p=T.rollAction(nextRoll,'RerollPlayer',nil,draws,{key='third'},{[kind]={id='rare',position='C',goldRoll=1}})
 p,code=T.rollAction(p,'ChooseRare',kind)
 assert(code=='ROLLED' and p.rollDraft.squad.C.id=='rare' and p.owned.rare and p.goldOwned.rare)
end
for _,path in ipairs({'src/StarterPlayer/StarterPlayerScripts/RareWheelView.luau','src/StarterPlayer/StarterPlayerScripts/RollController.luau'}) do luau.compile(fs.readFile(path)) end
print('PASS: both rare kinds reject occupied slots, grant no ownership, preserve pending pick, block Roll until normal selection, and still accept open positions')
