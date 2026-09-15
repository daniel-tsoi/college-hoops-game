-- Only the authenticated server Player.UserId selects these privileges.
local Creator = {}
Creator.UserId = 1123697419 -- Codeninjaexpert111
function Creator.apply(profile, userId)
 local updated = table.clone(profile)
 local allowed = userId == Creator.UserId
 updated.infiniteMoney = allowed
 updated.unlimitedActions = allowed
 updated.creatorLuck = allowed and 50 or nil
 return updated
end
return Creator
