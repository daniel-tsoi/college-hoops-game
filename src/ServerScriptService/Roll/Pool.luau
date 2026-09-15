local Pool = {}
function Pool.build(database, config)
 local pools = { ordinary = {}, allStar = {}, hof = {}, nonCollege = {} }
 for _, pos in ipairs(config.Positions) do
  for _, group in pairs(pools) do group[pos] = {} end
 end
 for _, card in pairs(database.ById) do
  local group = card.sourceType == "NON_COLLEGE" and pools.nonCollege
   or (card.rarity == "HOF" and pools.hof or (card.rarity == "All-Star" and pools.allStar or pools.ordinary))
  for _, pos in ipairs(card.eligiblePositions or {card.position}) do
   if group[pos] then table.insert(group[pos],card) end
  end
 end
 for _, group in pairs(pools) do
  for _, cards in pairs(group) do table.sort(cards,function(a,b) return a.id < b.id end) end
 end
 local numbers={}
 for _,pos in ipairs(config.Positions) do
  local cards={}
  for _,group in pairs(pools) do for _,card in ipairs(group[pos]) do table.insert(cards,card) end end
  table.sort(cards,function(a,b) return a.id<b.id end)
  numbers[pos]={}
  for index,card in ipairs(cards) do numbers[pos][card.id]=index end
 end
 pools.teams={}
 local teams={}
 for _,card in pairs(database.ById) do
  if card.school and card.season and card.sourceType~="NON_COLLEGE" and card.rarity~="HOF" then
   local key=card.school.." | "..card.season
   if not teams[key] then teams[key]={key=key,school=card.school,season=card.season,positions={}} end
   for _,pos in ipairs(card.eligiblePositions or {card.position}) do
    teams[key].positions[pos]=teams[key].positions[pos] or {}
    table.insert(teams[key].positions[pos],card)
   end
  end
 end
 for _,team in pairs(teams) do
  local complete=true
  for _,pos in ipairs(config.Positions) do
   if not team.positions[pos] then complete=false
   else table.sort(team.positions[pos],function(a,b) return a.id<b.id end) end
  end
  if complete then table.insert(pools.teams,team) end
 end
 table.sort(pools.teams,function(a,b) return a.key<b.key end)
 pools.numbers=numbers
 return pools
end
function Pool.tier(ticket, config, luck)
 if luck and luck > 1 then
  local ceiling = 0
  for _, tier in ipairs({"HOF", "NonCollege", "All-Star"}) do
   ceiling += math.floor(config.Tickets[tier].count * math.clamp(luck, 1, 50))
   if ticket >= 1 and ticket <= ceiling then return tier end
  end
  if ticket >= 1 and ticket <= config.Denominator then return "Ordinary" end
  error("Invalid roll ticket")
 end
 for _, tier in ipairs({"HOF","NonCollege","All-Star","Ordinary"}) do
  local range=config.Tickets[tier]
  if ticket >= range.first and ticket <= range.last then return tier end
 end
 error("Invalid roll ticket")
end
function Pool.draw(pools, unlocked, position, random, config, luck)
 assert(pools.ordinary[position] and #pools.ordinary[position]>0,"Position has no college players")
 local tier=Pool.tier(random:NextInteger(1,config.Denominator),config,luck)
 local source=tier=="HOF" and pools.hof[position] or (tier=="NonCollege" and pools.nonCollege[position]
  or (tier=="All-Star" and pools.allStar[position] or pools.ordinary[position]))
 local available={}
 for _,card in ipairs(source) do
  if (tier~="HOF" and tier~="NonCollege") or unlocked[card.id]==true then table.insert(available,card) end
 end
 if #available==0 then available=pools.ordinary[position] end
 local card=available[random:NextInteger(1,#available)]
 return { id=card.id, prospectNumber=pools.numbers[position][card.id], goldRoll=luck and (random:NextInteger(1,10000)<=500*math.clamp(luck,1,3) and 1 or 100) or random:NextInteger(1,100) }
end
-- Team rolls keep every offered player in the displayed college season.
-- At 1x selection is uniform. Higher luck gives higher OVR cards more
-- tickets, up to luck:1 for the strongest versus weakest eligible candidate.
function Pool.chooseOverall(cards, random, luck)
 local multiplier=math.clamp(luck or 1,1,50)
 local low,high=math.huge,-math.huge
 for _,card in ipairs(cards) do
  local overall=card.overall or 0
  low=math.min(low,overall); high=math.max(high,overall)
 end
 if multiplier==1 or low==high then return cards[random:NextInteger(1,#cards)] end
 local weights,total={},0
 for i,card in ipairs(cards) do
  weights[i]=1000+math.floor(1000*(multiplier-1)*((card.overall or 0)-low)/(high-low))
  total+=weights[i]
 end
 local ticket=random:NextInteger(1,total)
 for i,card in ipairs(cards) do
  ticket-=weights[i]
  if ticket<=0 then return card end
 end
 error("Invalid overall ticket")
end
function Pool.drawTeam(pools, unlocked, random, config, currentKey, keepTeam, previous, changeSchoolAndYear, luck)
 local choices={}
 local current
 for _,team in ipairs(pools.teams) do
  if team.key==currentKey then current=team; break end
 end
 for _,team in ipairs(pools.teams) do
  if keepTeam and team.key==currentKey then choices={team}; break end
  if not keepTeam and team.key~=currentKey
   and (not changeSchoolAndYear or not current or (team.school~=current.school and team.season~=current.season)) then
   table.insert(choices,team)
  end
 end
 if #choices==0 then choices=pools.teams end
 assert(#choices>0,"No complete college rosters")
 local team=choices[random:NextInteger(1,#choices)]
 local draws={}
 local used={}
 for _,pos in ipairs(config.Positions) do
  local available={}
  for _,card in ipairs(team.positions[pos]) do
   if not used[card.playerId or card.id] and (card.rarity~="HOF" or unlocked[card.id]) then table.insert(available,card) end
  end
  assert(#available>0,"Team roster needs five distinct players")
  local tier=Pool.tier(random:NextInteger(1,config.Denominator),config,luck)
  local tierCards,ordinary={},{}
  for _,card in ipairs(available) do
   if card.rarity~="HOF" and card.rarity~="All-Star" then table.insert(ordinary,card) end
   if card.rarity==tier then table.insert(tierCards,card) end
  end
  if #tierCards>0 then available=tierCards elseif #ordinary>0 then available=ordinary end
  local alternatives={}
  for _,card in ipairs(available) do
   if not previous or not previous[pos] or previous[pos].id~=card.id then table.insert(alternatives,card) end
  end
  if #alternatives>0 then available=alternatives end
  local card=Pool.chooseOverall(available,random,luck)
  used[card.playerId or card.id]=true
  draws[pos]={id=card.id,prospectNumber=pools.numbers[pos][card.id],goldRoll=luck and (random:NextInteger(1,10000)<=500*math.clamp(luck,1,3) and 1 or 100) or random:NextInteger(1,100)}
 end
 return draws,{key=team.key,school=team.school,season=team.season}
end
return Pool
