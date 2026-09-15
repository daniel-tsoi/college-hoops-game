-- Roll a fresh school-season first; keep its three offers hidden until claimed.
local SixthMan = {}
function SixthMan.draw(database, draft, random, luck)
 if not draft.team then return {} end
 local excluded, teams, cards = {}, {}, {}
 for _,field in ipairs({"candidates","squad"}) do
  for _,entry in pairs(draft[field] or {}) do
   local card=database[entry.id]
   if card then excluded[card.playerId or card.id]=true end
  end
 end
 for _,card in pairs(database) do table.insert(cards,card) end
 table.sort(cards,function(a,b) return a.id<b.id end)
 for _,card in ipairs(cards) do
  local identity=card.playerId or card.id
  if card.school and card.season and card.school~=draft.team.school and card.season~=draft.team.season
   and card.sourceType~="NON_COLLEGE" and card.rarity~="HOF" and not excluded[identity] then
   local key=card.school.." | "..card.season
   local team=teams[key]
   if not team then team={key=key,cards={},seen={}};teams[key]=team end
   if not team.seen[identity] then
    team.seen[identity]=true;table.insert(team.cards,card)
   end
  end
 end
 local choices={}
 for _,team in pairs(teams) do table.insert(choices,team) end
 table.sort(choices,function(a,b) return a.key<b.key end)
 -- Never fall back to the original school or year if no fresh roster exists.
 if #choices==0 then return {} end
 local available=choices[random:NextInteger(1,#choices)].cards
 local offers={}
 for i=1,math.min(3,#available) do
  local card=table.remove(available,random:NextInteger(1,#available))
  offers[i]={id=card.id,goldRoll=luck and (random:NextInteger(1,10000)<=500*math.clamp(luck,1,3) and 1 or 100) or random:NextInteger(1,100)}
 end
 return offers
end
return SixthMan
