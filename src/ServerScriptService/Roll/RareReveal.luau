-- Build announcements only from a newly committed roll, never from save retries.
local Reveal = {}
function Reveal.events(beforeSerial, profile, database)
 local draft=profile and profile.rollDraft
 if not draft or (draft.rareRoll or 0)==beforeSerial then return {} end
 local events={}
 for _,kind in ipairs({"HOF","NonCollege"}) do
  local entry=(draft.rare or {})[kind]
  local card=entry and database[entry.id]
  if card and (profile.shopUnlocked or {})[entry.id]==true then
   table.insert(events,{kind=kind,cardName=card.name,gold=type(entry.goldRoll)=="number" and entry.goldRoll>=1 and entry.goldRoll<=5})
  end
 end
 return events
end
return Reveal
