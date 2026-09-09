local Reveal=require("../src/ServerScriptService/Roll/RareReveal")
local db={h={name="Michael Jordan"},n={name="Non-college player"}}
local p={shopUnlocked={h=true,n=true},rollDraft={rareRoll=2,rare={HOF={id="h",goldRoll=5},NonCollege={id="n",goldRoll=6}}}}
local hits=Reveal.events(1,p,db)
assert(#hits==2 and hits[1].kind=="HOF" and hits[1].gold and not hits[2].gold)
assert(#Reveal.events(2,p,db)==0, "Same roll cannot repeat its announcement")
p.shopUnlocked={}
assert(#Reveal.events(1,p,db)==0, "Unpurchased hits cannot announce")
p.shopUnlocked={h=true}; p.rollDraft.rare={}
assert(#Reveal.events(1,p,db)==0, "Misses cannot announce")
assert(#Reveal.events(0,{},db)==0)
print("Rare reveal: new roll only, both categories, gold, purchase gating, misses and repeat suppression passed")
