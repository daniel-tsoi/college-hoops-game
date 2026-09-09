local T=require("../src/ServerScriptService/Shop/Transactions")
local positions={"PG","SG","SF","PF","C"}
for _,rareLast in ipairs({false,true}) do
 local p=T.startSession(T.newProfile(100),"finish-test")
 p=T.purchase(p,{id="rare",price=1})
 local draws={}
 for _,pos in ipairs(positions) do draws[pos]={id=pos,goldRoll=100} end
 p=T.rollAction(p,"RestartRoll",nil,draws)
 for i,pos in ipairs(positions) do
  if i>1 then p=T.rollAction(p,"NextRoll",nil,draws,nil,{HOF={id="rare",position="C",goldRoll=5}}) end
  local before=p
  local code
  p,code=T.rollAction(p,rareLast and i==5 and "ChooseRare" or "RollPlayer",rareLast and i==5 and "HOF" or pos)
  assert(not before.rollDraft.finished, "Must not mutate the saved input")
  assert(p.rollDraft.finished==(i==5))
  assert(code==(i==5 and "FINISHED" or "ROLLED"))
 end
 assert(not p.rollDraft.pickAvailable)
 if rareLast then assert(p.owned.rare and p.goldOwned.rare) end
 local same,code=T.rollAction(p,"NextRoll",nil,draws)
 assert(same==p and code=="FINISHED")
end
print("Automatic completion: normal and gold rare fifth picks, immutability, ownership, and completion lock passed")
