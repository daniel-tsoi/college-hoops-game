local Rare=require("../src/ServerScriptService/Roll/RareWheel")
local T=require("../src/ServerScriptService/Shop/Transactions")
local totals={HOF=0,NonCollege=0}
for ticket=1,Rare.Denominator do
 for kind in pairs(totals) do if Rare.hit(kind,ticket) then totals[kind]+=1 end end
end
assert(totals.HOF==250 and totals.NonCollege==260)
assert(totals.HOF/Rare.Denominator==0.00125 and totals.NonCollege/Rare.Denominator==0.0013)
local pools=Rare.build({ById={
 h={id="h",position="PG",rarity="HOF"},
 n={id="n",position="C",sourceType="NON_COLLEGE"},
 c={id="c",position="SG",rarity="Common"},
}})
local function rng(a,b)
 local i=0
 return {NextInteger=function(_,lo,hi) i+=1; return i==1 and a or i==2 and b or lo end}
end
local both=Rare.draw(pools,rng(250,260))
assert(both.HOF.id=="h" and both.NonCollege.id=="n")
assert(next(Rare.draw(pools,rng(251,261)))==nil)
assert(Rare.draw(pools,rng(250,261)).NonCollege==nil)
assert(Rare.draw(pools,rng(251,260)).HOF==nil)
local draws={PG={id="normal",goldRoll=100}}
local team={key="team",school="Test",season="2025-26"}
local p=T.startSession(T.newProfile(0),"rare-test")
p=T.rollAction(p,"RollState",nil,draws,team,both)
assert(not p.owned.h and p.rollDraft.rareRoll==1)
local reopened=T.rollAction(p,"RollState",nil,draws,team,{})
assert(reopened==p and reopened.rollDraft.rare.HOF.id=="h")
local refreshed=T.rollAction(p,"RefreshRoll",nil,draws,team,{})
assert(refreshed.rollDraft.rare==p.rollDraft.rare and refreshed.rollDraft.rareRoll==1)
local chosen,code=T.rollAction(p,"ChooseRare","HOF")
assert(code=="ROLLED" and chosen.owned.h and chosen.goldOwned.h and chosen.rollDraft.squad.PG.id=="h")
assert(not p.owned.h and p.rollDraft.pickAvailable)
local repeatPick,repeatCode=T.rollAction(chosen,"ChooseRare","NonCollege")
assert(repeatPick==chosen and repeatCode=="ROLL_REQUIRED" and not chosen.owned.n)
local normal,normalCode=T.rollAction(chosen,"RollPlayer","PG")
assert(normal==chosen and normalCode=="FILLED")
local nextRoll=T.rollAction(chosen,"NextRoll",nil,draws,team,{})
assert(next(nextRoll.rollDraft.rare)==nil and nextRoll.rollDraft.rareRoll==2)
local invalid,invalidCode=T.rollAction(nextRoll,"ChooseRare","HOF")
assert(invalid==nextRoll and invalidCode=="INVALID")
local normalPicked=T.rollAction(p,"RollPlayer","PG")
local denied,deniedCode=T.rollAction(normalPicked,"ChooseRare","HOF")
assert(denied==normalPicked and deniedCode=="ROLL_REQUIRED")
print("Rare wheel: exact independent odds, both hits, no hits, persistence, refresh, reset, ownership, gold and one-pick enforcement passed")
