-- Stylized Roblox character design, not verified portraits of real people.
local Metadata = require(script.Parent.CardArt.JerseyMetadata)
local Appearance = {}
local skins = {"B8784F","8B5438","DDA77B","603C2B","F0C9A4","A36C48"}
local hairStyles = {"curls","fade","twists","swept","buzz"}
-- number, jersey, skin, hair style, hair color, aura. Special art is intentional.
local special = {
 ["Michael Jordan"]={"23","CE1141","8B5438","bald","211713","FF244B"},
 ["Magic Johnson"]={"32","552583","8B5438","buzz","171311","FDB927"},
 ["Shaquille O'Neal"]={"33","552583","805038","bald","171311","B783FF"},
 ["Oscar Robertson"]={"12","C8102E","805038","buzz","171311","FF673C"},
 ["Pete Maravich"]={"23","461D7C","E8BB94","swept","68402B","C8A2FF"},
 ["Jayson Tatum"]={"0","007A33","B8784F","fade","211713","50FF9B"},
 ["Derrick Rose"]={"1","CE1141","A36C48","twists","211713","FF3559"},
 ["Kyrie Irving"]={"11","00538C","A36C48","curls","211713","4CD7FF"},
 ["Kobe Bryant"]={"24","FDB927","A36C48","buzz","211713","B57AFF"},
 ["LeBron James"]={"23","552583","805038","fade","211713","FFC94A"},
 ["Luka Doncic"]={"77","00538C","E8BB94","swept","67432B","4CDBFF"},
 ["Nikola Jokic"]={"15","0E2240","F0C9A4","buzz","684A36","FFD36A"},
 ["Kevin Garnett"]={"21","246849","805038","bald","171311","69FF9B"},
 ["Victor Wembanyama"]={"1","8796A1","B8784F","curls","211713","9FEAFF"},
 ["Dirk Nowitzki"]={"41","00538C","F0C9A4","swept","B89150","67C9FF"},
 ["Giannis Antetokounmpo"]={"34","00471B","805038","fade","211713","B1FF75"},
}
local function hash(value)
 local h=17
 for i=1,#value do h=(h*31+string.byte(value,i))%2147483647 end
 return h
end
function Appearance.get(card)
 local key=table.concat({card.name or "",card.school or "",card.season or ""},"|")
 local seed=hash(card.name or card.id or "player")
 local recorded=Metadata.players[key]
 local design=special[card.name]
 local premium=card.rarity=="HOF" or string.sub(card.id or "",1,12)=="non-college-"
 local jersey=recorded and recorded[2] or Metadata.schools[card.school or ""] or "346FC2"
 local number=recorded and recorded[1]~="" and recorded[1] or tostring(seed%55)
 local result={number=number,jersey=jersey,skin=skins[seed%#skins+1],hair=hairStyles[seed%#hairStyles+1],
  hairColor="211713",premium=premium,aura=card.gold and "FFD35A" or jersey,seed=seed,
  jerseySource=recorded and "DATABASE" or "STYLIZED_FALLBACK"}
 if design then
  result.skin,result.hair,result.hairColor=design[3],design[4],design[5]
  if premium then
   result.number,result.jersey,result.aura=design[1],design[2],design[6]
   result.jerseySource="SPECIAL_CARD_ART"
  end
 end
 result.gold=card.gold==true
 result.extraTall=card.id=="non-college-victor-wembanyama"
 return result
end
return Appearance
