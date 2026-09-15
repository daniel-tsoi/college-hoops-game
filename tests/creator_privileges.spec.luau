local Creator=require('../src/ServerScriptService/Shop/CreatorPrivileges')
local T=require('../src/ServerScriptService/Shop/Transactions')
local L=require('../src/shared/Luck')
local W=require('../src/ServerScriptService/Roll/RareWheel')
local P=require('../src/ServerScriptService/Roll/Pool')
local C=require('../src/ServerScriptService/Config/SummonConfig')
local serde=require('@lune/serde')
local fs=require('@lune/fs')
local luau=require('@lune/luau')
local original=T.startSession(T.newProfile(123),'first',0)
local creator=Creator.apply(original,1123697419)
assert(not original.infiniteMoney and creator.infiniteMoney and L.multiplier(creator,false)==50)
for i=1,100 do
 local before=creator.balance
 local code
 creator,code=T.purchase(creator,{id='card'..i,price=100000000})
 assert(code=='PURCHASED' and creator.balance==before and creator.shopUnlocked['card'..i])
end
local rejoined=Creator.apply(T.startSession(serde.decode('json',serde.encode('json',creator)),'second',1),1123697419)
assert(rejoined.infiniteMoney and L.multiplier(rejoined,true)==50 and rejoined.balance==123)
assert(select(2,L.upgrade(rejoined,'Cash'))=='LUCK_MAX')
rejoined.luckCredit2=1
assert(L.redeemAvailable(rejoined)==rejoined and rejoined.luckCredit2==1)
for _,id in ipairs({1,1123697420,-1}) do
 local normal=Creator.apply(rejoined,id)
 assert(not normal.infiniteMoney and normal.creatorLuck==nil and L.multiplier(normal,true)==1)
 assert(select(2,T.purchase(normal,{id='expensive',price=1000}))=='INSUFFICIENT')
 local bought,code=T.purchase(normal,{id='cheap',price=100})
 assert(code=='PURCHASED' and bought.balance==23)
end
assert(not Creator.apply(original,'1123697419').infiniteMoney)
local counts={}
for ticket=1,C.Denominator do local tier=P.tier(ticket,C,50);counts[tier]=(counts[tier] or 0)+1 end
assert(counts.HOF==3750 and counts.NonCollege==4000 and counts['All-Star']==30000)
for _,kind in ipairs({'HOF','NonCollege'}) do
 local hits=0
 for ticket=1,W.Denominator do if W.hit(kind,ticket,50) then hits+=1 end end
 assert(hits==W.Tickets[kind]*50)
end
local gold=0
for ticket=1,10000 do
 local random={NextInteger=function(_,a,b) return b==10000 and ticket or a end}
 local draw=W.draw({HOF={{id='hof',position='C'}},NonCollege={{id='nc',position='PG'}}},random,{hof=true,nc=true},50)
 assert(draw.HOF and draw.NonCollege)
 if T.isGoldRoll(draw.HOF.goldRoll) and T.isGoldRoll(draw.NonCollege.goldRoll) then gold+=1 end
end
-- Gold is the one 50x perk that stays capped at the public 3x rate, so a
-- creator's pulls are not every one of them gold.
assert(gold==1500,'50x luck still caps gold at the 3x rate of 15%')
local strong=0
for ticket=1,51000 do
 local card=P.chooseOverall({{id='weak',overall=60},{id='strong',overall=90}},{NextInteger=function(_,a,b) assert(a==1 and b==51000);return ticket end},50)
 if card.id=='strong' then strong+=1 end
end
assert(strong==50000,'50x must not silently clamp to the normal 3x maximum')
for _,file in ipairs({'src/ServerScriptService/ShopServer.server.luau','src/StarterPlayer/StarterPlayerScripts/ShopUI.client.luau','src/StarterPlayer/StarterPlayerScripts/LuckView.luau'}) do luau.compile(fs.readFile(file)) end
print('Creator: exact user ID authorization, unlimited cash spending, rejoin, normal account isolation, credit preservation, 50x tier/rare/OVR odds, gold capped at the 3x rate and UI compilation passed')
-- Guaranteed rare tickets use authenticated identity, not the luck multiplier.
for _,kind in ipairs({'HOF','NonCollege'}) do
 for ticket=1,W.Denominator do
  assert(W.hit(kind,ticket,50,1123697419))
  assert(W.hit(kind,ticket,3,1)==W.hit(kind,ticket,3))
 end
 assert(not W.hit(kind,W.Denominator,50,'1123697419'))
end
local lastTicket={NextInteger=function(_,a,b) return b end}
local rarePools={HOF={{id='h',position='C'}},NonCollege={{id='n',position='PG'}}}
local guaranteed=W.draw(rarePools,lastTicket,{h=true,n=true},50,1123697419)
assert(guaranteed.HOF.id=='h' and guaranteed.NonCollege.id=='n')
assert(next(W.draw(rarePools,lastTicket,{h=true,n=true},3,1))==nil)
assert(next(W.draw(rarePools,lastTicket,{},50,1123697419))==nil,'Shop eligibility is still required')
assert(not W.HOFTest100 and not W.NonCollegeTest100,'Global odds overrides must stay off')
luau.compile(fs.readFile('src/StarterPlayer/StarterPlayerScripts/RareWheelView.luau'))
print('Creator-only guaranteed HOF + non-college: every ticket hits, real draw path, ordinary odds unchanged, strict identity, eligibility and global flags passed')
