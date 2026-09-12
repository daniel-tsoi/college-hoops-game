local L=require("../src/shared/Luck")
local R=require("../src/ServerScriptService/Shop/RobuxRewards")
local T=require("../src/ServerScriptService/Shop/Transactions")
local W=require("../src/ServerScriptService/Roll/RareWheel")
local P=require("../src/ServerScriptService/Roll/Pool")
local C=require("../src/ServerScriptService/Config/SummonConfig")
local products=require("../src/ServerScriptService/Config/DeveloperProducts")
local p=T.newProfile(16250000)
for i=2,5 do
 local previous=p
 p=L.upgrade(p,"Cash")
 assert(L.level(p)==i and p.balance==previous.balance-L.Tiers[i].cash)
 assert(L.multiplier(p,false)==L.Tiers[i].multiplier)
 local m=L.multiplier(p,true)
 assert(W.hit("HOF",math.floor(250*m),m) and not W.hit("HOF",math.floor(250*m)+1,m))
 local counts={}
 for ticket=1,C.Denominator do local tier=P.tier(ticket,C,m);counts[tier]=(counts[tier] or 0)+1 end
 assert(counts["All-Star"]==600*m and counts.HOF==math.floor(75*m))
end
assert(p.balance==0 and select(2,L.upgrade(p,"Cash"))=="LUCK_MAX")
assert(select(2,L.upgrade(T.newProfile(0),"Cash"))=="INSUFFICIENT")
p=T.newProfile(0)
-- A later tier receipt cannot skip the earlier tier or disappear on rejoin.
p=R.grant(p,"late",products.Luck_3)
assert(select(2,L.upgrade(p,"Credit"))=="NO_CREDIT")
p=R.grant(p,"first",products.Luck_2)
p=T.startSession(p,"rejoin",100)
p=L.upgrade(p,"Credit")
assert(L.multiplier(p,true)==1.5 and L.multiplier(p,false)==1)
p=L.upgrade(p,"Credit")
assert(L.level(p)==3 and p.luckCredit2==0 and p.luckCredit3==0)
local retry=R.grant(p,"first",products.Luck_2)
assert(retry.luckCredit2==0 and L.level(retry)==3)
print("Luck: exact tier costs, sequential cash/receipt upgrades, rejoin, retries, policy fallback, exact All-Star and rare odds passed")
-- Verify actual gold draw boundaries, including the fractional 7.5% and 12.5% tiers.
for _,tier in ipairs(L.Tiers) do
 local gold=0
 for ticket=1,10000 do
  local random={NextInteger=function(_,low,high) return high==10000 and ticket or low end}
  local result=W.draw({HOF={{id="hof",position="C"}},NonCollege={}},random,{hof=true},tier.multiplier)
  assert(result.HOF)
  if T.isGoldRoll(result.HOF.goldRoll) then gold+=1 end
 end
 assert(gold==500*tier.multiplier)
end
print("Actual boosted gold draws: exact 5%, 7.5%, 10%, 12.5%, and 15% passed")
local instant=T.newProfile(0)
for level=2,5 do
 local old=instant
 instant=R.grant(instant,"instant"..level,products["Luck_"..level])
 instant=L.redeemAvailable(instant)
 assert(L.level(instant)==level and instant["luckCredit"..level]==0)
 assert(L.level(old)==level-1)
 local retry=L.redeemAvailable(R.grant(instant,"instant"..level,products["Luck_"..level]))
 assert(L.level(retry)==level and retry["luckCredit"..level]==0)
end
print("Paid luck activates immediately and idempotently through maximum 3x")
