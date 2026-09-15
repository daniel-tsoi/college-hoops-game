-- Authorization is checked using Player.UserId, never client flags.
local Gifts = {}
function Gifts.valid(actorId, request)
 if actorId ~= 1123697419 then return false, "FORBIDDEN" end
 if type(request) ~= "table" or type(request.username) ~= "string" or #request.username > 20
  or type(request.requestId) ~= "string" or #request.requestId ~= 36 then return false, "INVALID" end
 local total=0
 for field,limit in pairs({cash=1000000000000,rerolls=1000000,refreshes=1000000}) do
  local n=request[field]
  if type(n)~="number" or n~=n or n<0 or n>limit or n%1~=0 then return false,"INVALID" end
  total+=n
 end
 return total>0, total>0 and "READY" or "INVALID"
end
function Gifts.grant(profile, actorId, request)
 local valid,code=Gifts.valid(actorId,request)
 if not valid then return profile,code end
 if (profile.creatorGiftReceipts or {})[request.requestId] then return profile,"ALREADY_GIFTED" end
 local updated=table.clone(profile)
 updated.creatorGiftReceipts=table.clone(profile.creatorGiftReceipts or {})
 updated.creatorGiftReceipts[request.requestId]=true
 updated.balance=(profile.balance or 0)+request.cash
 updated.rerolls=(profile.rerolls or 0)+request.rerolls
 updated.refreshes=(profile.refreshes or 0)+request.refreshes
 return updated,"GIFTED"
end
return Gifts
