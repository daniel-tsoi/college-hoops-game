-- Receipt history and entitlement change must be saved in the SAME UpdateAsync.
local Rewards = {}
function Rewards.grant(profile, purchaseId, product, quest)
 if (profile.robuxReceipts or {})[purchaseId] then return profile, "ALREADY_GRANTED" end
 local updated = table.clone(profile)
 updated.robuxReceipts = table.clone(profile.robuxReceipts or {})
 updated.robuxReceipts[purchaseId] = true
 if product.questId then
  assert(quest and quest.id == product.questId, "Missing trusted quest reward")
  -- Payment grants the entire double bundle immediately, even at zero progress.
  -- Receipt ID, wallet, and claim flags are saved in the same transaction.
  updated.balance = (profile.balance or 0) + quest.cash * 2
  updated.rerolls = (profile.rerolls or 0) + quest.rerolls * 2
  updated.refreshes = (profile.refreshes or 0) + quest.refreshes * 2
  updated.sessionCash = (profile.sessionCash or 0) + quest.cash * 2
  updated.sessionClaimed = table.clone(profile.sessionClaimed or {})
  updated.sessionDoubled = table.clone(profile.sessionDoubled or {})
  updated.sessionClaimed[quest.id] = true
  updated.sessionDoubled[quest.id] = true
 else
  updated[product.field] = (profile[product.field] or 0) + product.amount
 end
 return updated, "GRANTED"
end
function Rewards.canOffer(profile, kind)
 local draft = profile.rollDraft
 if kind == "Rerolls" then
  return (profile.freeRollRerolls or 0)+(profile.rerolls or 0)+(profile.paidRerolls or 0)==0
 elseif kind == "Refreshes" then
  return (profile.freeRollRefreshes or 0)+(profile.refreshes or 0)+(profile.paidRefreshes or 0)==0
 elseif kind == "Sixth" then
  if not draft or not draft.squad.SIXTH or (profile.sixthCredits or 0)>0 then return false end
  for i,card in pairs(draft.sixthOffers or {}) do
   if card and not (draft.sixthRevealed or {})[i] and draft.sixthChoice~=i then return true end
  end
 end
 return false
end
-- The generic 400-Robux product buys a durable unlock credit, not a rare roll.
-- Redemption is separate so delayed receipts cannot unlock the wrong card.
function Rewards.unlockPlayer(profile, cardId)
 if (profile.shopUnlocked or {})[cardId] then return profile,"ELIGIBLE" end
 if (profile.shopUnlockCredits or 0)<1 then return profile,"NO_CREDIT" end
 local updated=table.clone(profile)
 updated.shopUnlockCredits-=1
 updated.shopUnlocked=table.clone(profile.shopUnlocked or {})
 updated.shopUnlocked[cardId]=true
 return updated,"PURCHASED"
end
return Rewards
