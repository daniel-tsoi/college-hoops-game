local T=require("../src/ServerScriptService/Shop/Transactions")
local R=require("../src/ServerScriptService/Shop/RobuxRewards")
local quests=require("../src/ReplicatedStorage/QuestConfig")
local products=require("../src/ServerScriptService/Config/DeveloperProducts")
local serde=require("@lune/serde")
local prices={49,99,199,49,99,49,99}
for i,q in ipairs(quests) do
 local product=products["Quest_"..q.id]
 assert(q.doublePrice==prices[i] and product.price==prices[i] and product.id>0)
 local before=T.startSession(T.newProfile(0),"first",100)
 local purchased,code=R.grant(before,"receipt"..i,product,q)
 assert(code=="GRANTED" and before.balance==0 and not before.sessionClaimed[q.id])
 assert(purchased.balance==2*q.cash and purchased.rerolls==2*q.rerolls and purchased.refreshes==2*q.refreshes)
 assert(purchased.sessionCash==2*q.cash and purchased.sessionClaimed[q.id] and purchased.sessionDoubled[q.id])
 assert(purchased[q.metric]==0,"Paying grants rewards without manufacturing quest progress")
 local duplicate,duplicateCode=R.grant(purchased,"receipt"..i,product,q)
 assert(duplicateCode=="ALREADY_GRANTED" and duplicate.balance==purchased.balance)
 assert(select(2,T.claim(purchased,q))=="CLAIMED","No extra free claim after buying")
 local saved=serde.decode("json",serde.encode("json",purchased))
 local rejoined=T.startSession(saved,"next",200)
 local retried=R.grant(rejoined,"receipt"..i,product,q)
 assert(retried.balance==2*q.cash and not retried.sessionClaimed[q.id])
 local late=R.grant(rejoined,"late"..i,product,q)
 assert(late.balance==4*q.cash and late.sessionClaimed[q.id])
 -- A distinct paid purchase always delivers, even after an earned free claim.
 local earned=T.startSession(T.newProfile(0),"earned",300)
 earned[q.metric]=q.target
 earned=T.claim(earned,q)
 local paid=R.grant(earned,"after-free"..i,product,q)
 assert(paid.balance==3*q.cash and paid.rerolls==3*q.rerolls and paid.refreshes==3*q.refreshes)
end
print("Instant quest purchases: exact products/prices, all doubled rewards at zero progress, receipt replay, rejoin, late delivery, post-claim purchases passed")
