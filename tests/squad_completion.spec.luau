local fs=require("@lune/fs")
local luau=require("@lune/luau")
local roblox=require("@lune/roblox")
local objects={}
local instance={new=function(class)
 local object={ClassName=class,Activated={}}
 function object.Activated:Connect(callback) self.fire=callback end
 table.insert(objects,object)
 return object
end}
local viewModule=luau.load(fs.readFile("src/StarterPlayer/StarterPlayerScripts/SquadCompletion.luau"),{environment={
 Instance=instance,UDim2=roblox.UDim2,UDim=roblox.UDim,Vector2=roblox.Vector2,Color3=roblox.Color3,
 Enum=roblox.Enum,script={Parent={WaitForChild=function() return "Focus" end}},
 require=function() return {select=function() end} end,
}})()
local ui={canvas={FindFirstChild=function() return {} end},buttons={Roll={}},background={Visible=true},build={Visible=false}}
local draft,pending,view,action
local function redraw() return view.render(draft,pending) end
view=viewModule.mount(ui,function(value) action=value; if value=="AcceptSixth" then draft.sixthAccepted=true end end,redraw)
local function find(name)
 for _,object in ipairs(objects) do if object.Name==name then return object end end
 error(name)
end
local function expect(modal,pick)
 local actualModal,actualPick=redraw()
 assert(actualModal==modal and not not actualPick==pick,"Unexpected completion state")
end
draft={finished=false,rareRoll=1,squad={}}
expect(false,false);view.finish();expect(false,false)
draft={finished=true,rareRoll=5,squad={},sixthAvailable={true,true,false}}
expect(false,false) -- Filling five alone must never open a screen.
view.finish();expect(true,false)
pending=true;expect(true,false);find("TrySixth").Activated.fire();expect(true,false)
pending=false;redraw();find("TrySixth").Activated.fire();expect(false,true)
assert(ui.background.Visible,"Yes must return to the builder")
draft.squad.SIXTH={id="sixth"};expect(false,false)
view.finish();assert(not ui.background.Visible and ui.build.Visible)
-- A new draft must require a new decision; No stays open on a failed request.
ui.background.Visible=true;ui.build.Visible=false
draft={finished=false,rareRoll=6,squad={}};expect(false,false)
draft={finished=true,rareRoll=10,squad={},sixthAvailable={true}};expect(false,false)
view.finish();find("KeepTeam").Activated.fire()
assert(action=="DeclineSixth");expect(true,false)
draft.sixthDeclined=true;expect(false,false)
assert(not ui.background.Visible and ui.build.Visible)
-- Legacy/empty offers finish without trapping the player.
ui.background.Visible=true;draft={finished=true,rareRoll=11,squad={},sixthAvailable={}}
redraw();view.finish();assert(not ui.background.Visible)
for _,path in ipairs({"RollController.luau","SixthManView.luau","SquadCompletion.luau"}) do
 luau.compile(fs.readFile("src/StarterPlayer/StarterPlayerScripts/"..path))
end
print("Completion flow: explicit Finish, Yes, No, pending/retry, sixth reveal, restart, empty offers, and UI compilation passed")
