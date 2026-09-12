-- Looping background music, routed through the same HoopsSFX sound group as the
-- roll effects so the SFX bars in Settings raise, lower and mute it too. Local
-- audio only; nothing here is broadcast to other players.
local SoundService = game:GetService("SoundService")
local ContentProvider = game:GetService("ContentProvider")
local TweenService = game:GetService("TweenService")
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("MusicConfig"))
local SettingsState = require(script.Parent:WaitForChild("SettingsState"))

-- No uploaded track yet, or a second copy of this script: do nothing.
if Config.assetId == 0 or SoundService:FindFirstChild("HoopsMusic") then
	return
end

local music = Instance.new("Sound")
music.Name = "HoopsMusic"
music.SoundId = "rbxassetid://" .. Config.assetId
music.Looped = true
-- Starts silent and fades up; the sound group applies the player's SFX level
-- on top of this, so muting SFX silences the music as well.
music.Volume = 0
music.SoundGroup = SettingsState.soundGroup()
-- SoundService rather than PlayerGui, so the track survives respawns.
music.Parent = SoundService

task.spawn(function()
	-- A track that has not finished moderation will fail to preload; play it
	-- anyway rather than leaving the game silent if that call errors.
	pcall(function()
		ContentProvider:PreloadAsync({ music })
	end)
	music:Play()
	TweenService:Create(music, TweenInfo.new(Config.fadeSeconds), { Volume = Config.volume }):Play()
end)
