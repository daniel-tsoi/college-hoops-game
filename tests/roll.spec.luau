local T=require("../src/ServerScriptService/Shop/Transactions")
local Pool=require("../src/ServerScriptService/Roll/Pool")
local Config=require("../src/ServerScriptService/Config/SummonConfig")
local counts={HOF=0,NonCollege=0,["All-Star"]=0,Ordinary=0}
for i=1,Config.Denominator do counts[Pool.tier(i,Config)]+=1 end
assert(counts.HOF/Config.Denominator==1/800 and counts.NonCollege/Config.Denominator==1/750)
assert(counts["All-Star"]==600 and counts.Ordinary==59245)
local old={version=4,balance=123,owned={hof=true,college=true},goldOwned={hof=true},equippedCardId="hof"}
local migrated=T.migrateShopOwnership(old,{hof={}})
assert(migrated.shopUnlocked.hof and not migrated.owned.hof and migrated.owned.college)
assert(migrated.legacyShopGold.hof and migrated.equippedCardId==nil and old.owned.hof)
assert(T.migrateShopOwnership(migrated,{hof={}})==migrated)
local p=T.startSession(T.newProfile(1000),"test")
p=T.purchase(p,{id="hof",price=100})
assert(p.shopUnlocked.hof and not p.owned.hof and p.sessionUnlocks==0)
local draws={}
for _,pos in ipairs(Config.Positions) do draws[pos]={id=pos.."-real",goldRoll=pos=="PG" and 5 or 100,prospectNumber=750} end
p=T.rollAction(p,"RollState",nil,draws)
assert(next(p.owned)==nil)
local original=p
p=T.rollAction(p,"RollPlayer","PG")
assert(p.owned["PG-real"] and p.goldOwned["PG-real"] and p.sessionUnlocks==1)
assert(not original.owned["PG-real"] and not original.rollDraft.squad.PG)
local repeated,code=T.rollAction(p,"RollPlayer","PG")
assert(code=="FILLED" and repeated==p)
local invalid,invalidCode=T.rollAction(p,"RollPlayer","BOGUS")
assert(invalidCode=="INVALID" and invalid==p)
local blocked,blockedCode=T.rollAction(p,"RollPlayer","SG")
assert(blocked==p and blockedCode=="ROLL_REQUIRED", "Only one pick per roll")
local blockedRefresh,refreshCode=T.rollAction(p,"RefreshRoll",nil,draws)
assert(blockedRefresh==p and refreshCode=="ROLL_REQUIRED")
local nextDraw={}
for _,pos in ipairs(Config.Positions) do nextDraw[pos]={id=pos.."-next",goldRoll=100,prospectNumber=500} end
local blockedReroll,rerollCode=T.rollAction(p,"RerollPlayer","PG",nextDraw)
assert(blockedReroll==p and rerollCode=="ROLL_REQUIRED")
assert(p.freeRollRerolls==1 and p.sessionRerolls==0 and p.rollDraft.squad.PG.id=="PG-real")
p=T.rollAction(p,"NextRoll",nil,draws)
local beforeReroll=p
local rerolledTeam={key="new-team",school="New School",season="2024-25"}
local rerolledRare={HOF={id="legend"}}
p,code=T.rollAction(p,"RerollPlayer",nil,nextDraw,rerolledTeam,rerolledRare)
assert(p.rollDraft.team==rerolledTeam and p.rollDraft.rare==rerolledRare)
assert(p.rollDraft.rareRoll==beforeReroll.rollDraft.rareRoll+1)
assert(code=="REROLLED" and p.rollDraft.candidates.SG.id=="SG-next")
assert(p.rollDraft.squad.PG.id=="PG-real" and not p.owned["PG-next"] and not p.owned["SG-next"])
assert(p.rollDraft.pickAvailable and p.freeRollRerolls==0 and p.sessionRerolls==1)
assert(beforeReroll.freeRollRerolls==1 and beforeReroll.rollDraft.candidates.SG.id=="SG-real")
local empty,emptyCode=T.rollAction(p,"RerollPlayer",nil,draws)
assert(emptyCode=="EMPTY" and empty==p)
p.rerolls=3; p.refreshes=4
p=T.rollAction(p,"RerollPlayer",nil,draws)
assert(p.rerolls==2 and p.sessionRerolls==2)
p=T.rollAction(p,"RefreshRoll",nil,nextDraw)
assert(p.freeRollRefreshes==0 and p.refreshes==4)
p=T.rollAction(p,"RefreshRoll",nil,draws)
assert(p.refreshes==3)
local beforeRestart=p
p=T.rollAction(p,"RestartRoll",nil,draws)
assert(p.freeRollRerolls==1 and p.freeRollRefreshes==1 and p.rerolls==2 and p.refreshes==3)
assert(p.owned["PG-real"] and next(p.rollDraft.squad)==nil and p.sessionRerolls==2)
assert(beforeRestart.freeRollRerolls==0 and beforeRestart.freeRollRefreshes==0)
p=T.rollAction(p,"RestartRoll",nil,draws)
assert(p.freeRollRerolls==1 and p.freeRollRefreshes==1 and p.rerolls==2 and p.refreshes==3)
p=T.rollAction(p,"RerollPlayer",nil,draws)
p=T.rollAction(p,"RefreshRoll",nil,draws)
assert(p.freeRollRerolls==0 and p.freeRollRefreshes==0 and p.rerolls==2 and p.refreshes==3)
for i,pos in ipairs(Config.Positions) do
 if i>1 then p=T.rollAction(p,"NextRoll",nil,draws) end
 p=T.rollAction(p,"RollPlayer",pos)
end
assert(p.rollDraft.finished and not p.rollDraft.pickAvailable, "Fifth pick automatically finishes")
local db={ById={}}
for _,pos in ipairs(Config.Positions) do db.ById[pos]={id=pos,position=pos,name="Real "..pos,rarity="Common",sourceType="COLLEGE"} end
db.ById.hof={id="hof",position="PG",name="Legend",rarity="HOF"}
db.ById.non={id="non",position="PG",name="Non-college",sourceType="NON_COLLEGE"}
local pools=Pool.build(db,Config)
local function rng(ticket) local n=0; return {NextInteger=function(_,lo,hi) n+=1; return n==1 and ticket or lo end} end
assert(Pool.draw(pools,{},"PG",rng(1),Config).id=="PG")
assert(Pool.draw(pools,{hof=true},"PG",rng(1),Config).id=="hof")
assert(Pool.draw(pools,{non=true},"PG",rng(76),Config).id=="non")
assert(Pool.draw(pools,{hof=true},"C",rng(1),Config).id=="C")
local first=Pool.draw(pools,{},"PG",rng(1000),Config)
assert(first.prospectNumber==Pool.draw(pools,{},"PG",rng(1000),Config).prospectNumber)
print("Rolls: exact odds, shop migration, roll-only ownership, gold, position validation, costs, immutable retries, eligibility and stable prospect numbers passed")

-- Reroll changes both school and year; Refresh keeps both and the wheel.
local teamPools={teams={},numbers={}}
for i,info in ipairs({{"A","2023"},{"A","2024"},{"B","2023"},{"B","2024"}}) do
 local team={key=tostring(i),school=info[1],season=info[2],positions={}}
 for _,pos in ipairs(Config.Positions) do
  local id=tostring(i)..pos
  team.positions[pos]={{id=id,rarity="Common"}}
  teamPools.numbers[pos]=teamPools.numbers[pos] or {}
  teamPools.numbers[pos][id]=i
 end
 table.insert(teamPools.teams,team)
end
local _,different=Pool.drawTeam(teamPools,{},rng(1),Config,"1",false,nil,true)
assert(different.school=="B" and different.season=="2024")
local refreshedDraws,same=Pool.drawTeam(teamPools,{},rng(1),Config,"1",true)
assert(same.school=="A" and same.season=="2023")
local refreshProfile=T.startSession(T.newProfile(0),"refresh-check")
refreshProfile=T.rollAction(refreshProfile,"RestartRoll",nil,draws,rerolledTeam,rerolledRare)
local refreshed=T.rollAction(refreshProfile,"RefreshRoll",nil,refreshedDraws,same)
assert(refreshed.rollDraft.team==rerolledTeam and refreshed.rollDraft.rare==rerolledRare)
assert(refreshed.rollDraft.rareRoll==refreshProfile.rollDraft.rareRoll)
print("Reroll changes school/year/wheel; Refresh preserves school/year/wheel")
