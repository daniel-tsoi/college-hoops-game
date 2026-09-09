local fs=require('@lune/fs')
local luau=require('@lune/luau')
local files={'src/shared/PlayerSettings.luau','src/ServerScriptService/Customization/Jersey.luau','src/ServerScriptService/PlayerSettings.server.luau','src/StarterPlayer/StarterPlayerScripts/SettingsState.luau','src/StarterPlayer/StarterPlayerScripts/SettingsUI.client.luau','src/StarterPlayer/StarterPlayerScripts/RollSounds.luau','src/StarterPlayer/StarterPlayerScripts/RareRevealFX.client.luau'}
for _,path in files do luau.compile(fs.readFile(path)) end
local settings=luau.load(fs.readFile(files[1]))()
for color=1,#settings.colors do
 for number=0,99 do
  for volume=0,5 do
   local data=settings.defaults(); data.color=color; data.number=string.format('%02d',number); data.sfx=volume
   assert(settings.validate(data))
  end
 end
end
for key,values in pairs({color={0,9,-1,1.5,0/0,math.huge,'1'},number={'','100','-1','1.5','abc',23},sfx={-1,6,1.5,0/0,math.huge,'5'},hofVFX={0,'true'},nonCollegeVFX={1,'false'}}) do
 for _,value in values do local data=settings.defaults(); data[key]=value; assert(settings.validate(data)==nil,key) end
end
local data=settings.defaults(); data.username='Injected'; local clean=settings.validate(data)
assert(clean.username==nil and clean~=data)
assert(settings.validate(nil)==nil)
print('PASS: seven scripts compile; all 4,800 color/number/volume combinations accepted; invalid settings and injected fields rejected')
