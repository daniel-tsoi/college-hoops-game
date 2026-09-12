-- Primary background music.
--
-- Roblox only plays audio that has been uploaded to your account, so a local
-- .mp3 cannot be referenced here. Upload the track once in
-- Creator Dashboard > Creations > Audio, wait for moderation to approve it,
-- then paste its numeric asset ID below. Audio longer than six seconds is
-- usable only in experiences you own, which this is.
--
-- Source file: vaitsez-roblox-minecraft-fortnite-music-574103.mp3 (2:08, 256kbps).
return table.freeze({
	-- 0 leaves music disabled and the script does nothing.
	-- Uploaded to this account on 12 Sep 2026.
	assetId = 111581132324736,
	-- Sits under the roll effects, which play at .55 in the same sound group.
	volume = 0.35,
	-- Fade in on join rather than starting at full volume mid-bar.
	fadeSeconds = 2,
})
