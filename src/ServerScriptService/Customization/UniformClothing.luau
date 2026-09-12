-- Only changes this experience's character; never modifies the Roblox outfit.
local Clothing={}
local covered={TShirt=true,Shirt=true,Sweater=true,Jacket=true,Pants=true,Shorts=true,DressSkirt=true,
 Front=true,Back=true,Waist=true,Shoulder=true}
function Clothing.prepare(character)
 for _,item in ipairs(character:GetChildren()) do
  if item:IsA("Accessory") and covered[item.AccessoryType.Name] then
   for _,part in ipairs(item:GetDescendants()) do
    if part:IsA("BasePart") or part:IsA("Decal") or part:IsA("Texture") then
     if part:GetAttribute("HoopsOriginalTransparency")==nil then part:SetAttribute("HoopsOriginalTransparency",part.Transparency) end
     part.Transparency=1
    end
   end
  elseif item:IsA("Shirt") or item:IsA("Pants") or item:IsA("ShirtGraphic") then
   local property=item:IsA("Shirt") and "ShirtTemplate" or item:IsA("Pants") and "PantsTemplate" or "Graphic"
   if item:GetAttribute("HoopsOriginalTemplate")==nil then item:SetAttribute("HoopsOriginalTemplate",item[property]) end
   item[property]=""
  end
 end
end
return Clothing
