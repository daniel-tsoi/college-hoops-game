local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local Titles = require(game:GetService("ReplicatedStorage").Shared.PlayerTitles)

TextChatService.OnIncomingMessage = function(message)
	local source = message.TextSource
	local player = source and Players:GetPlayerByUserId(source.UserId)
	local title = player and player:GetAttribute("HoopsTitle")
	local color = title and Titles.Colors[title]
	if not color then return nil end
	local properties = Instance.new("TextChatMessageProperties")
	properties.PrefixText = string.format('<font color="#%s">[%s]</font> %s', color:ToHex(), title, message.PrefixText)
	return properties
end
