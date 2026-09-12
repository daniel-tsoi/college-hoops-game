-- Permanent sequential upgrades. Wallet changes are committed by the profile server.
local Luck = {}
Luck.Tiers = table.freeze({
 table.freeze({ multiplier=1, cash=0, robux=0 }),
 table.freeze({ multiplier=1.5, cash=250000, robux=149 }),
 table.freeze({ multiplier=2, cash=1000000, robux=399 }),
 table.freeze({ multiplier=2.5, cash=5000000, robux=799 }),
 table.freeze({ multiplier=3, cash=10000000, robux=1099 }),
})
function Luck.level(profile)
 return math.clamp(math.floor(tonumber(profile.luckLevel) or 1), 1, #Luck.Tiers)
end
function Luck.multiplier(profile, paidAllowed)
 local level = Luck.level(profile)
 if paidAllowed == false then level = math.min(level, profile.cashLuckLevel or 1) end
 return Luck.Tiers[level].multiplier
end
function Luck.upgrade(profile, payment)
 local nextLevel = Luck.level(profile) + 1
 local tier = Luck.Tiers[nextLevel]
 if not tier then return profile, "LUCK_MAX" end
 if payment ~= "Cash" and payment ~= "Credit" then return profile, "INVALID" end
 local field = "luckCredit" .. nextLevel
 local credit = (profile[field] or 0) > 0
 if not credit and payment == "Credit" then return profile, "NO_CREDIT" end
 if not credit and profile.balance < tier.cash then return profile, "INSUFFICIENT" end
 local updated = table.clone(profile)
 updated.luckLevel = nextLevel
 if credit then updated[field] -= 1
 else
  updated.balance -= tier.cash
  updated.cashLuckLevel = nextLevel
 end
 return updated, "LUCK_UPGRADED"
end
function Luck.redeemAvailable(profile)
 local updated=profile
 while Luck.level(updated)<#Luck.Tiers and (updated["luckCredit"..(Luck.level(updated)+1)] or 0)>0 do
  updated=Luck.upgrade(updated,"Credit")
 end
 return updated
end
return Luck
