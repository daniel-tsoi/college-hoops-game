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
 local gold={HOF=0,NonCollege=0}
 for ticket=1,10000 do
  local random={NextInteger=function(_,low,high) return high==10000 and ticket or low end}
  local result=W.draw({HOF={{id="hof",position="C"}},NonCollege={{id="non-college",position="PG"}}},random,{hof=true,["non-college"]=true},tier.multiplier)
  for _,kind in ipairs({"HOF","NonCollege"}) do
   assert(result[kind])
   if T.isGoldRoll(result[kind].goldRoll) then gold[kind]+=1 end
  end
 end
 for _,kind in ipairs({"HOF","NonCollege"}) do
  assert(gold[kind]==500*tier.multiplier,kind.." must use the same gold odds at every luck level")
 end
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

-- Exhaust every weighted OVR ticket; equal OVRs remain equally likely.
local cards={{id='low',overall=60},{id='mid',overall=75},{id='high',overall=90}}
for _,tier in ipairs(L.Tiers) do
 local m=tier.multiplier
 local total=m==1 and 3 or 3000+1500*(m-1)
 local counts={low=0,mid=0,high=0}
 for ticket=1,total do
  local card=P.chooseOverall(cards,{NextInteger=function(_,a,b) assert(a==1 and b==total);return ticket end},m)
  counts[card.id]+=1
 end
 if m==1 then assert(counts.low==1 and counts.mid==1 and counts.high==1)
 else assert(counts.low==1000 and counts.mid==1000+500*(m-1) and counts.high==1000*m) end
 for _,kind in ipairs({'HOF','NonCollege'}) do
  local hits=0
  for ticket=1,W.Denominator do if W.hit(kind,ticket,m) then hits+=1 end end
  assert(hits==math.floor(W.Tickets[kind]*m),'Exact independent rare wheel odds at every tier')
 end
end
local tied={{id='a',overall=80},{id='b',overall=80}}
assert(P.chooseOverall(tied,{NextInteger=function(_,a,b) assert(a==1 and b==2);return 2 end},3).id=='b')
-- Exercise drawTeam, including refresh exclusions, distinct players, and gold.
local database={ById={}}
for _,pos in ipairs(C.Positions) do
 for i,overall in ipairs({60,75,90}) do
  local id=pos..i
  database.ById[id]={id=id,playerId=id,position=pos,school='Test',season='2025-26',rarity='Common',overall=overall}
 end
end
local pools=P.build(database,C)
for _,tier in ipairs(L.Tiers) do
 for _,goldTicket in ipairs({500*tier.multiplier,500*tier.multiplier+1}) do
  local random={NextInteger=function(_,a,b)
   if b==10000 then return goldTicket end
   return b
  end}
  local draws,team=P.drawTeam(pools,{},random,C,nil,false,nil,false,tier.multiplier)
  local refreshed,sameTeam=P.drawTeam(pools,{},random,C,team.key,true,draws,false,tier.multiplier)
  assert(sameTeam.key==team.key)
  for _,pos in ipairs(C.Positions) do
   assert(draws[pos].id==pos..'3' and refreshed[pos].id==pos..'2')
   assert(T.isGoldRoll(draws[pos].goldRoll)==(goldTicket==500*tier.multiplier))
   assert(T.isGoldRoll(refreshed[pos].goldRoll)==T.isGoldRoll(draws[pos].goldRoll))
  end
 end
end
print('Luck: exact OVR weights, tied OVR fairness, both rare odds, team/refresh restrictions and college gold boundaries passed')
