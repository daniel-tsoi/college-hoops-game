local Rules={}
local names={RestartRoll="restart",RerollPlayer="reroll"}
function Rules.warning(action,draft)
 if not names[action] or not draft then return nil end
 local squad=draft.squad or {}
 local selected={}
 local acceptedRare=false
 for _,card in pairs(squad) do
  if card.id then selected[card.id]=true end
  if card.rarity=="HOF" or card.rarity=="NonCollege" or card.rarity=="Non-College"
   or card.sourceType=="NON_COLLEGE" then acceptedRare=true end
 end
 local unselected=false
 for _,kind in ipairs({"HOF","NonCollege"}) do
  local card=(draft.rare or {})[kind]
  if card then
   if card.id and selected[card.id] then acceptedRare=true
   else unselected=true end
  end
 end
 -- Reroll preserves the accepted squad. Refresh preserves both squad and hits.
 -- Restart clears the squad even when it has already been completed.
 if not unselected and not (action=="RestartRoll" and acceptedRare) then return nil end
 local detail=action=="RestartRoll"
  and "Restart clears your current squad and replaces the HOF and non-college wheel results."
  or "Reroll replaces the unselected HOF and non-college wheel results."
 if unselected then detail ..= " Select any result you want to keep first." end
 return "Are you sure you want to "..names[action].."?",detail.." Players already accepted into your collection stay owned."
end
-- Consume a confirmation once. A different snapshot means the player must
-- review the new state rather than accidentally confirming an older warning.
function Rules.consume(ticket,current,yes)
 if not ticket or ticket.used then return false end
 ticket.used=true
 return yes==true and ticket.snapshot==current
end
return Rules
