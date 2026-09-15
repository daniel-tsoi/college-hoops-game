-- Claims happen in a different panel. Observe the server's saved balances so
-- the builder's counts and zero-balance purchase checks update immediately.
local Sync = {}
function Sync.bind(player, getState, render)
 local connections = {}
 for attribute, field in pairs({QuestRerolls="rerolls", QuestRefreshes="refreshes"}) do
  local function update()
   local state = getState()
   local value = player:GetAttribute(attribute)
   if state and type(value) == "number" then
    state[field] = value
    render()
   end
  end
  table.insert(connections, player:GetAttributeChangedSignal(attribute):Connect(update))
  update()
 end
 return function()
  for _, connection in ipairs(connections) do connection:Disconnect() end
 end
end
return Sync
