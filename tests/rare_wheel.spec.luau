local Rare=require("../src/ServerScriptService/Roll/RareWheel")
local T=require("../src/ServerScriptService/Shop/Transactions")
local nonCollegeOverride=Rare.NonCollegeTest100
if nonCollegeOverride then assert(Rare.hit("NonCollege",Rare.Denominator)) end
Rare.NonCollegeTest100=false
local testOverride=Rare.HOFTest100
if testOverride then assert(Rare.hit("HOF",Rare.Denominator)) end
Rare.HOFTest100=false -- Verify the baseline odds independently of the temporary test override.
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
local both=Rare.draw(pools,rng(250,260),{h=true,n=true})
assert(both.HOF.id=="h" and both.NonCollege.id=="n")
assert(next(Rare.draw(pools,rng(251,261),{h=true,n=true}))==nil)
assert(Rare.draw(pools,rng(250,261),{h=true,n=true}).NonCollege==nil)
assert(Rare.draw(pools,rng(251,260),{h=true,n=true}).HOF==nil)
assert(next(Rare.draw(pools,rng(1,1),{}))==nil, "Unpurchased hits must be hidden")
assert(next(Rare.draw(pools,rng(1,1)))==nil, "Missing purchases fail closed")
local onlyHOF=Rare.draw(pools,rng(1,1),{h=true})
assert(onlyHOF.HOF.id=="h" and onlyHOF.NonCollege==nil)
local onlyNon=Rare.draw(pools,rng(1,1),{n=true})
assert(onlyNon.HOF==nil and onlyNon.NonCollege.id=="n")
Rare.HOFTest100=true
Rare.NonCollegeTest100=true
local guaranteed=Rare.draw(pools,rng(200000,200000),{h=true,n=true})
assert(guaranteed.HOF.id=="h" and guaranteed.NonCollege.id=="n", "Both test wheels guarantee eligible hits")
assert(next(Rare.draw(pools,rng(200000,200000),{}))==nil, "100% test does not bypass purchases")
Rare.HOFTest100=false
Rare.NonCollegeTest100=false
local goldCounts={HOF=0,NonCollege=0}
for goldTicket=1,100 do
 local count=0
 local random={NextInteger=function(_,lo,hi)
  count+=1
  if count<=2 then return 1 end
  return hi==100 and goldTicket or lo
 end}
 local hits=Rare.draw(pools,random,{h=true,n=true})
 for kind,entry in pairs(hits) do
  if T.isGoldRoll(entry.goldRoll) then goldCounts[kind]+=1 end
 end
end
assert(goldCounts.HOF==5 and goldCounts.NonCollege==5, "Each rare hit has a separate 5% gold chance")
local draws={PG={id="normal",goldRoll=100}}
local team={key="team",school="Test",season="2025-26"}
local p=T.startSession(T.newProfile(20),"rare-test")
local locked=T.rollAction(p,"RollState",nil,draws,team,both)
for _,kind in ipairs({"HOF","NonCollege"}) do
 local denied,code=T.rollAction(locked,"ChooseRare",kind)
 assert(denied==locked and code=="LOCKED" and next(denied.owned)==nil and denied.rollDraft.pickAvailable)
end
p=T.purchase(p,{id="h",price=10})
p=T.purchase(p,{id="n",price=10})
assert(next(p.owned)==nil, "Purchase grants eligibility, not ownership")
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
Rare.HOFTest100=testOverride
print("Rare wheel: exact independent odds, both hits, no hits, persistence, refresh, reset, ownership, gold and one-pick enforcement passed")
