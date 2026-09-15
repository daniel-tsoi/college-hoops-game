local G=require('../src/ServerScriptService/Shop/CreatorGifts')
local C=require('../src/ServerScriptService/Shop/CreatorPrivileges')
local T=require('../src/ServerScriptService/Shop/Transactions')
local R=require('../src/ServerScriptService/Shop/RobuxRewards')
local serde=require('@lune/serde')
local fs=require('@lune/fs')
local luau=require('@lune/luau')
local id=1123697419
local request={username='Recipient',requestId='12345678-1234-1234-1234-123456789abc',cash=10000,rerolls=25,refreshes=30}
local p=T.startSession(T.newProfile(100),'one',0)
p.rerolls=4;p.refreshes=5
assert(select(2,G.grant(p,1,request))=='FORBIDDEN')
for _,value in ipairs({-1,0.5,math.huge,0/0,'100',1000000000001}) do
 local bad=table.clone(request);bad.cash=value
 assert(select(2,G.grant(p,id,bad))=='INVALID')
end
local empty=table.clone(request);empty.cash=0;empty.rerolls=0;empty.refreshes=0
assert(not G.valid(id,empty))
local saved,code=G.grant(p,id,request)
assert(code=='GIFTED' and saved.balance==10100 and saved.rerolls==29 and saved.refreshes==35)
assert(p.balance==100 and p.rerolls==4 and p.refreshes==5 and not p.creatorGiftReceipts)
local retry=G.grant(p,id,request)
assert(retry.balance==saved.balance,'Retried save callback must not accumulate')
local rejoin=T.startSession(serde.decode('json',serde.encode('json',saved)),'two',1)
local duplicate,duplicateCode=G.grant(rejoin,id,request)
assert(duplicateCode=='ALREADY_GIFTED' and duplicate.rerolls==29 and duplicate.refreshes==35)
local nextRequest=table.clone(request);nextRequest.requestId='22345678-1234-1234-1234-123456789abc'
local stacked=G.grant(rejoin,id,nextRequest)
assert(stacked.balance==20100 and stacked.rerolls==54 and stacked.refreshes==65)
local draws={PG={id='p',goldRoll=100}}
local creator=C.apply(T.rollAction(p,'RollState',nil,draws,{key='team'}),id)
creator.freeRollRerolls=0;creator.freeRollRefreshes=0
for _=1,100 do
 local status
 creator,status=T.rollAction(creator,'RerollPlayer',nil,draws,{key='team'})
 assert(status=='REROLLED')
 creator,status=T.rollAction(creator,'RefreshRoll',nil,draws,{key='team'})
 assert(status=='REFRESHED')
end
assert(creator.rerolls==4 and creator.refreshes==5 and creator.freeRollRerolls==0 and creator.freeRollRefreshes==0)
assert(not R.canOffer(creator,'Rerolls') and not R.canOffer(creator,'Refreshes'))
local normal=C.apply(creator,1)
normal.rerolls=0;normal.refreshes=0
assert(not normal.unlimitedActions)
assert(select(2,T.rollAction(normal,'RerollPlayer',nil,draws,{key='team'}))=='EMPTY')
assert(select(2,T.rollAction(normal,'RefreshRoll',nil,draws,{key='team'}))=='EMPTY')
for _,path in ipairs({'src/ServerScriptService/ShopServer.server.luau','src/StarterPlayer/StarterPlayerScripts/CreatorSettings.client.luau','src/StarterPlayer/StarterPlayerScripts/RollController.luau'}) do luau.compile(fs.readFile(path)) end
print('Creator gifts: authorization, validation, additive saved wallet, save retry, rejoin/replay protection, stacking, 100 unlimited actions, normal account isolation and integration compilation passed')
