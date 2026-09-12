local D=require("../src/ServerScriptService/Shop/DailySpin")
local C=require("../src/shared/DailySpinConfig")
local T=require("../src/ServerScriptService/Shop/Transactions")
local serde=require("@lune/serde")
local counts={0,0,0,0,0}
for i=1,1000 do counts[D.index(i)]+=1 end
for i,reward in ipairs(C.Rewards) do assert(counts[i]==reward.tickets and counts[i]/10==reward.chance) end
assert(C.Cooldown==43200 and D.Cooldown==C.Cooldown)
for i,reward in ipairs(C.Rewards) do
 local profile=T.startSession(T.newProfile(0),"login",100)
 local card=not reward.cash and {id=reward.id.."-card",name="Daily player"} or nil
 local result,code=D.grant(profile,100,reward,i,card)
 assert(code=="DAILY_SPUN" and result.nextDailySpinAt==43300 and profile.nextDailySpinAt==nil)
 if reward.cash then assert(result.balance==reward.cash and result.sessionCash==reward.cash)
 else assert(result.owned[card.id] and result.sessionUnlocks==1 and not profile.owned[card.id]) end
 assert(not D.available(result,43299) and D.available(result,43300))
 local retry,retryCode=D.grant(result,100,reward,i,card)
 assert(retry==result and retryCode=="DAILY_COOLDOWN")
 local rejoined=T.startSession(serde.decode("json",serde.encode("json",result)),"again",200)
 assert(not D.available(rejoined,200),"Rejoining cannot refill the spin")
 local afterWeek=D.grant(rejoined,604800,reward,i,card)
 assert(afterWeek.nextDailySpinAt==648000 and not D.available(afterWeek,604800),"Missed spins never accumulate")
 if card then assert(afterWeek.sessionUnlocks==0,"Duplicate cards do not count as new unlocks") end
end
local empty=T.newProfile(0)
assert(select(2,D.grant(empty,10,C.Rewards[1],1,nil))=="DAILY_UNAVAILABLE" and D.available(empty,10))
for _,ticket in ipairs({0,1001,1.5}) do assert(not pcall(D.index,ticket)) end
print("Daily spin: exact exhaustive odds, all rewards, first login, 12-hour boundary, receipt/save retries, rejoin, no accumulation, missing rewards and duplicate ownership passed")
