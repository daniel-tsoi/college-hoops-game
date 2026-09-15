-- Gate actual GUI input, including controller selection; never clone/reparent
-- gameplay buttons or change the gameplay controller's Active state.
local Gate={}
function Gate.new(playerGui)
 local tracked={}
 local view={}
 local function restore(button,record)
  for _,connection in ipairs(record.connections) do connection:Disconnect() end
  if button.Parent then
   button.Interactable=record.Interactable
   button.Selectable=record.Selectable
  end
  tracked[button]=nil
 end
 function view.clear()
  for button,record in pairs(tracked) do restore(button,record) end
 end
 function view.update(allowed)
  for button,record in pairs(tracked) do
   if not button.Parent or allowed[button] then restore(button,record) end
  end
  for _,button in ipairs(playerGui:GetDescendants()) do
   if button:IsA("GuiButton") and not allowed[button] and not tracked[button] then
    local record={Interactable=button.Interactable,Selectable=button.Selectable,connections={},writing=false}
    tracked[button]=record
    for _,property in ipairs({"Interactable","Selectable"}) do
     table.insert(record.connections,button:GetPropertyChangedSignal(property):Connect(function()
      if record.writing then return end
      record[property]=button[property]
      record.writing=true;button[property]=false;record.writing=false
     end))
    end
    record.writing=true;button.Interactable=false;button.Selectable=false;record.writing=false
   end
  end
 end
 return view
end
return Gate
