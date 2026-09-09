-- Pure validation shared by the menu and server. No client-supplied names or assets.
local Settings = {}
Settings.colors = {
 {name="Mint", rgb={64,205,151}}, {name="Blue", rgb={48,112,225}},
 {name="Red", rgb={215,55,72}}, {name="Purple", rgb={143,77,211}},
 {name="Gold", rgb={240,184,52}}, {name="White", rgb={235,239,245}},
 {name="Black", rgb={29,34,45}}, {name="Pink", rgb={235,113,203}},
}
function Settings.defaults()
 return {color=1, number="23", hofVFX=true, nonCollegeVFX=true, sfx=5}
end
function Settings.validate(value)
 if type(value)~="table" then return nil end
 if type(value.color)~="number" or value.color%1~=0 or not Settings.colors[value.color] then return nil end
 if type(value.number)~="string" or not value.number:match("^%d%d?$") then return nil end
 if type(value.hofVFX)~="boolean" or type(value.nonCollegeVFX)~="boolean" then return nil end
 if type(value.sfx)~="number" or value.sfx%1~=0 or value.sfx<0 or value.sfx>5 then return nil end
 return {color=value.color, number=value.number, hofVFX=value.hofVFX, nonCollegeVFX=value.nonCollegeVFX, sfx=value.sfx}
end
return Settings
