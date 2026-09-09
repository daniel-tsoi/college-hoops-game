--!strict
-- Permanent direct-purchase entitlements. All four start locked.
-- Real game-pass/product identifiers and a verified server purchase handler are
-- required before enabling checkout. Nil IDs are deliberate, never dummy products.
export type Product = {
    cardId: string, displayName: string, acquisition: "DIRECT_PURCHASE",
    defaultUnlocked: boolean, randomEligible: boolean,
    productId: number?, enabled: boolean,
}
local Products: { Product } = {
    { cardId = "non-college-kobe-bryant", displayName = "Kobe Bryant", acquisition = "DIRECT_PURCHASE", defaultUnlocked = false, randomEligible = false, enabled = false },
    { cardId = "non-college-lebron-james", displayName = "LeBron James", acquisition = "DIRECT_PURCHASE", defaultUnlocked = false, randomEligible = false, enabled = false },
    { cardId = "non-college-luka-doncic", displayName = "Luka Doncic", acquisition = "DIRECT_PURCHASE", defaultUnlocked = false, randomEligible = false, enabled = false },
    { cardId = "non-college-nikola-jokic", displayName = "Nikola Jokic", acquisition = "DIRECT_PURCHASE", defaultUnlocked = false, randomEligible = false, enabled = false },
}
for _, product in Products do table.freeze(product) end
return table.freeze({ Products = table.freeze(Products), RequireVerifiedServerEntitlement = true })
