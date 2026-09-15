local Daily = {}
Daily.Cooldown = 43200
function Daily.available(profile,now)
 return now >= (profile.nextDailySpinAt or 0)
end
function Daily.index(ticket)
 assert(type(ticket)=="number" and ticket%1==0 and ticket>=1 and ticket<=1000)
 if ticket<=25 then return 1 elseif ticket<=50 then return 2 elseif ticket<=250 then return 3 elseif ticket<=600 then return 4 else return 5 end
end
-- Inputs are sampled once by the trusted server, outside UpdateAsync retries.
function Daily.grant(profile,now,reward,index,card,pool,choice)
 if not Daily.available(profile,now) then return profile,"DAILY_COOLDOWN" end
 local cash=reward.cash
 local complete=false
 if not cash and pool then
  if #pool==0 then return profile,"DAILY_UNAVAILABLE" end
  -- Resolve ownership against the profile being saved, including on retries.
  local unowned={}
  for _,candidate in ipairs(pool) do
   if not (profile.owned or {})[candidate.id] then table.insert(unowned,candidate) end
  end
  if #unowned==0 then
   cash=1000000;complete=true;card=nil
  else
   card=unowned[math.min(#unowned,math.floor((choice or 0)*#unowned)+1)]
  end
 end
 if not cash and not card then return profile,"DAILY_UNAVAILABLE" end
 local updated=table.clone(profile)
 updated.nextDailySpinAt=now+Daily.Cooldown
 if cash then
  updated.balance=(profile.balance or 0)+cash
  updated.sessionCash=(profile.sessionCash or 0)+cash
 else
  updated.owned=table.clone(profile.owned or {})
  updated.shopUnlocked=table.clone(profile.shopUnlocked or {})
  if not updated.owned[card.id] then updated.sessionUnlocks=(profile.sessionUnlocks or 0)+1 end
  updated.owned[card.id]=true
  -- A HOF or non-college prize is claimed in the Shop as well as owned. Without
  -- this the card stays for sale, cash could buy what was already won, and the
  -- rare wheel still would not offer it, since eligibility reads shopUnlocked.
  updated.shopUnlocked[card.id]=true
 end
 updated.dailyReward={id=reward.id,index=index,cash=cash,collectionComplete=complete,cardId=card and card.id,name=complete and "$1,000,000" or card and card.name,at=now}
 return updated,"DAILY_SPUN"
end
return Daily
