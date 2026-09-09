-- Independent server-only draws. Exact odds, with no purchase prerequisite.
local RareWheel = {}
RareWheel.Denominator = 200000
RareWheel.Tickets = { HOF = 250, NonCollege = 260 }
function RareWheel.hit(kind, ticket)
 assert(RareWheel.Tickets[kind] and ticket >= 1 and ticket <= RareWheel.Denominator)
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
function RareWheel.draw(pools, random)
 local result = {}
 -- Take both independent tickets before selecting cards or rolling gold.
 local tickets = {HOF=random:NextInteger(1,RareWheel.Denominator), NonCollege=random:NextInteger(1,RareWheel.Denominator)}
 for _,kind in ipairs({"HOF", "NonCollege"}) do
  local cards = pools[kind]
  assert(#cards > 0, "Missing rare player pool")
  if RareWheel.hit(kind,tickets[kind]) then
   local card = cards[random:NextInteger(1,#cards)]
   result[kind] = {id=card.id,position=card.position,goldRoll=random:NextInteger(1,100)}
  end
 end
 return result
end
return RareWheel
