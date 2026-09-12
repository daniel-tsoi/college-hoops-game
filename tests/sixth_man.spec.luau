local T=require("../src/ServerScriptService/Shop/Transactions")
local Sixth=require("../src/ServerScriptService/Roll/SixthMan")
local Chemistry=require("../src/shared/TeamChemistry")
local random={NextInteger=function(_,lo) return lo end}
local db,draft={}, {team={school="A",season="2025"},candidates={},squad={}}
for i=1,9 do db[tostring(i)]={id=tostring(i),playerId=tostring(i),school="A",season="2025",overall=80} end
for i,pos in ipairs(Chemistry.Positions) do draft.candidates[pos]={id=tostring(i),goldRoll=100} end
draft.squad.PG={id="6"}
db.other={id="other",school="B",season="2025"};db.year={id="year",school="A",season="2024"}
db.duplicate={id="duplicate",playerId="1",school="B",season="2024"}
db.squadDuplicate={id="squadDuplicate",playerId="6",school="B",season="2024"}
for i=7,9 do db[tostring(i)].school="B";db[tostring(i)].season="2024" end
for i=1,3 do db["z"..i]={id="z"..i,school="C",season="2023"} end
db.hof={id="hof",school="B",season="2024",rarity="HOF"}
db.nonCollege={id="nonCollege",school="B",season="2024",sourceType="NON_COLLEGE"}
local offers=Sixth.draw(db,draft,random)
assert(#offers==3)
for i,offer in ipairs(offers) do assert(offer.id==tostring(i+6)) end
local last=Sixth.draw(db,draft,{NextInteger=function(_,_,hi) return hi end})
assert(#last==3)
for _,offer in ipairs(last) do assert(db[offer.id].school=="C" and db[offer.id].season=="2023") end
assert(#Sixth.draw({other=db.other,year=db.year},draft,random)==0)
assert(#Sixth.draw(db,{},random)==0)
local p=T.startSession(T.newProfile(100),"sixth-test")
p=T.rollAction(p,"RestartRoll",nil,draft.candidates,draft.team)
local same,code=T.rollAction(p,"ChooseSixth",1)
assert(same==p and code=="INCOMPLETE")
for i,pos in ipairs(Chemistry.Positions) do
 if i>1 then p=T.rollAction(p,"NextRoll",nil,draft.candidates,draft.team) end
 p,code=T.rollAction(p,"RollPlayer",pos,nil,nil,nil,offers)
end
assert(p.rollDraft.finished and code=="FINISHED" and not p.owned["7"])
for _,bad in ipairs({0,4,1.5,"1"}) do same,code=T.rollAction(p,"ChooseSixth",bad);assert(same==p and code=="INVALID") end
local declined,declineCode=T.rollAction(p,"DeclineSixth")
assert(declineCode=="SIXTH_DECLINED" and declined.rollDraft.finished and declined.rollDraft.sixthDeclined)
assert(not p.rollDraft.sixthDeclined and #p.rollDraft.sixthOffers==3)
local retry,retryCode=T.rollAction(declined,"DeclineSixth")
assert(retry==declined and retryCode=="SIXTH_DECLINED")
retry,retryCode=T.rollAction(declined,"ChooseSixth",1)
assert(retry==declined and retryCode=="SIXTH_DECLINED" and not retry.owned["7"])
local before=p
p,code=T.rollAction(p,"ChooseSixth",2)
assert(code=="SIXTH_ADDED" and p.owned["8"] and p.goldOwned["8"])
assert(p.rollDraft.squad.SIXTH.id=="8" and p.rollDraft.finished and not p.rollDraft.pickAvailable)
assert(not before.rollDraft.squad.SIXTH and not before.owned["8"])
same,code=T.rollAction(p,"ChooseSixth",1);assert(same==p and code=="SIXTH_TAKEN" and not p.owned["7"])
-- A paid replacement revokes only this draft's grant, even after saving/rejoining.
local serde=require("@lune/serde")
local replace=serde.decode("json",serde.encode("json",p))
replace.sixthCredits=1;replace.equippedCardId="8";replace.rollDraft.bestTeamRecordedCount=6
local outgoing=replace
replace,code=T.rollAction(replace,"ChooseSixth",1)
assert(code=="SIXTH_ADDED" and not replace.owned["8"] and not replace.goldOwned["8"] and replace.owned["7"])
assert(replace.equippedCardId==nil and replace.sixthCredits==0 and replace.rollDraft.bestTeamRecordedCount==nil)
assert(outgoing.owned["8"] and outgoing.goldOwned["8"] and outgoing.equippedCardId=="8")
-- A normal copy owned before the choice remains; its temporary gold upgrade is revoked.
local preowned=T.migrate(before);preowned.owned=table.clone(before.owned);preowned.owned["8"]=true
preowned=T.rollAction(preowned,"ChooseSixth",2)
assert(preowned.goldOwned["8"])
preowned.sixthCredits=1
preowned=T.rollAction(preowned,"ChooseSixth",1)
assert(preowned.owned["8"] and not preowned.goldOwned["8"] and preowned.owned["7"])
local squad={}
for _,pos in ipairs(Chemistry.Positions) do squad[pos]={overall=80,school="A",season="2025"} end
assert(Chemistry.evaluate(squad).overall==91)
squad.SIXTH={overall=86,school="A",season="2025"}
local rating=Chemistry.evaluate(squad)
assert(rating.count==6 and rating.baseOverall==81 and rating.overall==94 and rating.cards.SIXTH.bonus==13)
squad.SIXTH={overall=86,school="B",season="2024"}
rating=Chemistry.evaluate(squad)
assert(rating.cards.SIXTH.bonus==0 and rating.cards.PG.bonus==11 and rating.count==6)
p=T.rollAction(p,"RestartRoll",nil,draft.candidates,draft.team)
assert(not p.rollDraft.squad.SIXTH and not p.rollDraft.sixthChoice and p.owned["8"])
assert(#Sixth.draw({},draft,random)==0)
print("Sixth man: fresh random school/year, roster exclusions, optional finish, atomic ownership, invalid/repeated picks, restart, six-player chemistry passed")

-- An accepted, unresolved choice blocks destructive squad actions server-side.
local T2=require("../src/ServerScriptService/Shop/Transactions")
local locked={rollDraft={finished=true,squad={},sixthOffers={{id="offer"}},rareRoll=5}}
local accepted,code=T2.rollAction(locked,"AcceptSixth")
assert(code=="SIXTH_ACCEPTED" and accepted.rollDraft.sixthAccepted)
assert(not locked.rollDraft.sixthAccepted)
for _,action in ipairs({"RestartRoll","NextRoll"}) do
 local same,result=T2.rollAction(accepted,action)
 assert(result=="CHOOSE_SIXTH" and same==accepted)
end
local declined=T2.rollAction(accepted,"DeclineSixth")
assert(select(2,T2.rollAction(declined,"RestartRoll",nil,{},{}))=="READY")
print("Accepted sixth-man server lock passed")
