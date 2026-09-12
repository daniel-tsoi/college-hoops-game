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
function Daily.grant(profile,now,reward,index,card)
 if not Daily.available(profile,now) then return profile,"DAILY_COOLDOWN" end
 if not reward.cash and not card then return profile,"DAILY_UNAVAILABLE" end
 local updated=table.clone(profile)
 updated.nextDailySpinAt=now+Daily.Cooldown
 if reward.cash then
  updated.balance=(profile.balance or 0)+reward.cash
  updated.sessionCash=(profile.sessionCash or 0)+reward.cash
 else
  updated.owned=table.clone(profile.owned or {})
  if not updated.owned[card.id] then updated.sessionUnlocks=(profile.sessionUnlocks or 0)+1 end
  updated.owned[card.id]=true
 end
 updated.dailyReward={id=reward.id,index=index,cash=reward.cash,cardId=card and card.id,name=card and card.name,at=now}
 return updated,"DAILY_SPUN"
end
return Daily
