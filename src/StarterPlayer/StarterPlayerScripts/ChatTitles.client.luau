local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local Titles = require(game:GetService("ReplicatedStorage").Shared.PlayerTitles)

TextChatService.OnIncomingMessage = function(message)
	local source = message.TextSource
	local player = source and Players:GetPlayerByUserId(source.UserId)
	if not player then return nil end
	-- Role and rank both, e.g. [Creator][Top 1], each in its own colour.
	local badges = Titles.badges(player:GetAttribute("HoopsRole"), player:GetAttribute("LeaderboardRank"))
	local prefix = ""
	for _, badge in ipairs(badges) do
		local color = Titles.Colors[badge]
		if color then
			prefix ..= string.format('<font color="#%s">[%s]</font>', color:ToHex(), badge)
		end
	end
	if prefix == "" then return nil end
	local properties = Instance.new("TextChatMessageProperties")
	properties.PrefixText = prefix .. " " .. message.PrefixText
	return properties
end
