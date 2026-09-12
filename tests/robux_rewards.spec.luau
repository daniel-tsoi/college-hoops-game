local T=require("../src/ServerScriptService/Shop/Transactions")
local R=require("../src/ServerScriptService/Shop/RobuxRewards")
local Products=require("../src/ServerScriptService/Config/DeveloperProducts")
local p=T.startSession(T.newProfile(0),"purchase-test")
p.freeRollRerolls=0;p.freeRollRefreshes=0
local original=p
local code
p,code=R.grant(p,"receipt-1",Products.Rerolls)
assert(code=="GRANTED" and p.paidRerolls==10 and not original.paidRerolls)
local same;same,code=R.grant(p,"receipt-1",Products.Rerolls)
assert(same==p and code=="ALREADY_GRANTED" and p.paidRerolls==10)
for i=2,101 do p=R.grant(p,"receipt-"..i,Products.Rerolls) end
assert(p.paidRerolls==1010)
p=R.grant(p,"refresh",Products.Refreshes);assert(p.paidRefreshes==10)
local team={key="test",school="A",season="2025"}
local cards={};for _,pos in ipairs({"PG","SG","SF","PF","C"}) do cards[pos]={id=pos,goldRoll=100} end
p=T.rollAction(p,"RollState",nil,cards,team,{})
p=T.rollAction(p,"RerollPlayer",nil,cards,team,{})
assert(p.paidRerolls==1009 and p.paidRefreshes==10)
p=T.rollAction(p,"RefreshRoll",nil,cards,team,{})
assert(p.paidRefreshes==9 and p.paidRerolls==1009)
local pools={HOF={{id="hof"}},NonCollege={{id="nc"}}}
local beforeShop=p
p=R.grant(p,"shop-unlock",Products.ShopPlayer)
assert(p.shopUnlockCredits==1 and not p.shopUnlocked.hof and not p.owned.hof)
p,code=R.unlockPlayer(p,"hof")
assert(code=="PURCHASED" and p.shopUnlocked.hof and p.shopUnlockCredits==0)
assert(not p.owned.hof and p.rollDraft==beforeShop.rollDraft and p.balance==beforeShop.balance)
same,code=R.unlockPlayer(p,"hof");assert(same==p and code=="ELIGIBLE")
same,code=R.unlockPlayer(p,"nc");assert(same==p and code=="NO_CREDIT")
p=R.grant(p,"another-shop-unlock",Products.ShopPlayer)
same,code=R.unlockPlayer(p,"hof");assert(same==p and p.shopUnlockCredits==1)
p=R.unlockPlayer(p,"nc");assert(p.shopUnlocked.nc and not p.owned.nc)
local Rare=require("../src/ServerScriptService/Roll/RareWheel")
assert(not Rare.HOFTest100 and not Rare.NonCollegeTest100)
local rarePools=Rare.build({ById={h={id="hof",position="PG",rarity="HOF"},n={id="nc",position="C",sourceType="NON_COLLEGE"}}})
local misses=Rare.draw(rarePools,{NextInteger=function(_,lo,hi) return hi end},p.shopUnlocked)
assert(next(misses)==nil,"Robux Shop unlocks must still miss on losing tickets")
local offers={{id="extra1",goldRoll=100},{id="extra2",goldRoll=1},{id="extra3",goldRoll=100}}
for i,pos in ipairs({"PG","SG","SF","PF","C"}) do
 if i>1 then p=T.rollAction(p,"NextRoll",nil,cards,team,{}) end
 p=T.rollAction(p,"RollPlayer",pos,nil,nil,nil,offers)
end
p=T.rollAction(p,"ChooseSixth",1)
assert(R.canOffer(p,"Sixth",pools) and p.owned.extra1)
same,code=T.rollAction(p,"ChooseSixth",2);assert(same==p and code=="SIXTH_TAKEN")
p=R.grant(p,"sixth-1",Products.Sixth)
same,code=T.rollAction(p,"ChooseSixth",1);assert(same==p and p.sixthCredits==1)
p=T.rollAction(p,"ChooseSixth",2)
assert(p.sixthCredits==0 and not p.owned.extra1 and p.owned.extra2 and p.goldOwned.extra2 and p.rollDraft.squad.SIXTH.id=="extra2")
p=R.grant(p,"sixth-2",Products.Sixth);p=T.rollAction(p,"ChooseSixth",3)
assert(not p.owned.extra1 and not p.owned.extra2 and not p.goldOwned.extra2 and p.owned.extra3 and p.sixthCredits==0 and not R.canOffer(p,"Sixth",pools))
assert(p.rollDraft.sixthRevealed[1] and p.rollDraft.sixthRevealed[2] and p.rollDraft.sixthRevealed[3])
p=R.grant(p,"delayed",Products.Sixth)
p=T.rollAction(p,"RestartRoll",nil,cards,team,{})
assert(p.sixthCredits==1 and not p.owned.extra1 and not p.owned.extra2 and p.owned.extra3)
-- Delayed purchases grant durable credits even when the original offer has gone.
p=R.grant(p,"shop-after-restart",Products.ShopPlayer);assert(p.shopUnlockCredits==1)
-- Persist -> disconnect -> reload -> new login, using the same serialization as saved profiles.
local serde=require("@lune/serde")
local saved=serde.encode("json",p)
local rejoined=T.startSession(serde.decode("json",saved),"purchase-rejoin",2000)
assert(rejoined.paidRerolls==1009 and rejoined.paidRefreshes==9 and rejoined.shopUnlockCredits==1)
assert(rejoined.shopUnlocked.hof and rejoined.shopUnlocked.nc and rejoined.owned.extra3)
-- Receipts already acknowledged before disconnect must not grant again after rejoin.
rejoined,code=R.grant(rejoined,"receipt-1",Products.Rerolls)
assert(code=="ALREADY_GRANTED" and rejoined.paidRerolls==1009)
rejoined=R.grant(rejoined,"stack-after-rejoin",Products.Rerolls)
rejoined=R.grant(rejoined,"refresh-after-rejoin",Products.Refreshes)
assert(rejoined.paidRerolls==1019 and rejoined.paidRefreshes==19)
rejoined=T.rollAction(rejoined,"RestartRoll",nil,cards,team,{})
assert(rejoined.paidRerolls==1019 and rejoined.paidRefreshes==19)
-- Restart's free actions must be consumed before touching paid balances.
rejoined=T.rollAction(rejoined,"RerollPlayer",nil,cards,team,{})
rejoined=T.rollAction(rejoined,"RefreshRoll",nil,cards,team,{})
assert(rejoined.paidRerolls==1019 and rejoined.paidRefreshes==19)
rejoined=T.rollAction(rejoined,"RerollPlayer",nil,cards,team,{})
rejoined=T.rollAction(rejoined,"RefreshRoll",nil,cards,team,{})
assert(rejoined.paidRerolls==1018 and rejoined.paidRefreshes==18)
local stable=serde.decode("json",serde.encode("json",rejoined))
stable=T.startSession(stable,"purchase-rejoin-2",3000)
assert(stable.paidRerolls==1018 and stable.paidRefreshes==18)
local ids={}
for _,product in pairs(Products) do assert(product.id>0 and not ids[product.id]);ids[product.id]=true end
-- All changed scripts compile without relying on Roblox globals.
local fs=require("@lune/fs");local luau=require("@lune/luau")
for _,file in ipairs({"src/ServerScriptService/ShopServer.server.luau","src/StarterPlayer/StarterPlayerScripts/RollController.luau","src/StarterPlayer/StarterPlayerScripts/RareWheelView.luau","src/StarterPlayer/StarterPlayerScripts/SixthManView.luau","src/StarterPlayer/StarterPlayerScripts/ShopUI.client.luau"}) do
 luau.compile(fs.readFile(file))
end
local controller=fs.readFile("src/StarterPlayer/StarterPlayerScripts/RollController.luau")
assert(not controller:find("PurchaseOffer") and not controller:find("ChemistryHover") and not controller:find("GuaranteedRare"))
print("Robux rewards: receipt idempotency, unlimited packs, separate balances, consumption, two serialized rejoins, Shop eligibility without ownership or guaranteed hits, sixth-man replacement, delayed grants and compilation passed")
