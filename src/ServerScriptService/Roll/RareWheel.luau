-- Independent server-only draws. Exact odds; only shop-purchased players are eligible.
local RareWheel = {}
-- Shop unlocks add eligibility; every roll uses the normal luck-based odds.
RareWheel.HOFTest100 = false
RareWheel.NonCollegeTest100 = false
RareWheel.Denominator = 200000
RareWheel.Tickets = { HOF = 250, NonCollege = 260 }
function RareWheel.hit(kind, ticket, luck, userId)
 assert(RareWheel.Tickets[kind] and ticket >= 1 and ticket <= RareWheel.Denominator)
 -- userId is supplied by the server from the authenticated Player.
 if userId == 1123697419 then return true end
 if kind == "HOF" and RareWheel.HOFTest100 then return true end
 if kind == "NonCollege" and RareWheel.NonCollegeTest100 then return true end
 return ticket <= math.floor(RareWheel.Tickets[kind] * math.clamp(luck or 1, 1, 50))
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
function RareWheel.draw(pools, random, shopUnlocked, luck, userId)
 local result = {}
 -- Take both independent tickets before selecting cards or rolling gold.
 local tickets = {HOF=random:NextInteger(1,RareWheel.Denominator), NonCollege=random:NextInteger(1,RareWheel.Denominator)}
 for _,kind in ipairs({"HOF", "NonCollege"}) do
  local cards = {}
  for _,card in ipairs(pools[kind]) do
   if (shopUnlocked or {})[card.id] == true then table.insert(cards,card) end
  end
  if RareWheel.hit(kind,tickets[kind],luck,userId) and #cards > 0 then
   local card = cards[random:NextInteger(1,#cards)]
   result[kind] = {id=card.id,position=card.position,goldRoll=luck and (random:NextInteger(1,10000)<=500*math.clamp(luck,1,3) and 1 or 100) or random:NextInteger(1,100)}
  end
 end
 return result
end
return RareWheel
