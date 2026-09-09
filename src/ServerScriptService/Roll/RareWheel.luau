-- Independent server-only draws. Exact odds; only shop-purchased players are eligible.
local RareWheel = {}
-- Temporary user-requested 100% HOF test. Disable only when the user requests restoration.
RareWheel.HOFTest100 = true
RareWheel.Denominator = 200000
RareWheel.Tickets = { HOF = 250, NonCollege = 260 }
function RareWheel.hit(kind, ticket)
 assert(RareWheel.Tickets[kind] and ticket >= 1 and ticket <= RareWheel.Denominator)
 if kind == "HOF" and RareWheel.HOFTest100 then return true end
 return ticket <= RareWheel.Tickets[kind]
end
function RareWheel.build(database)
 local pools = { HOF = {}, NonCollege = {} }
 for _,card in pairs(database.ById) do
  local kind = card.sourceType == "NON_COLLEGE" and "NonCollege" or card.rarity == "HOF" and "HOF"
  if kind then table.insert(pools[kind], card) end
 end
 for _,cards in pairs(pools) do table.sort(cards,function(a,b) return a.id < b.id end) end
 return pools
end
function RareWheel.draw(pools, random, shopUnlocked)
 local result = {}
 -- Take both independent tickets before selecting cards or rolling gold.
 local tickets = {HOF=random:NextInteger(1,RareWheel.Denominator), NonCollege=random:NextInteger(1,RareWheel.Denominator)}
 for _,kind in ipairs({"HOF", "NonCollege"}) do
  local cards = {}
  for _,card in ipairs(pools[kind]) do
   if (shopUnlocked or {})[card.id] == true then table.insert(cards,card) end
  end
  if RareWheel.hit(kind,tickets[kind]) and #cards > 0 then
   local card = cards[random:NextInteger(1,#cards)]
   result[kind] = {id=card.id,position=card.position,goldRoll=random:NextInteger(1,100)}
  end
 end
 return result
end
return RareWheel
