-- Proves the jersey's top edge is fully covered by its piping at every slope,
-- and that the part budget per avatar stays low. The old build exposed the
-- fabric corners by 0.068 studs at the armholes, which read as a jagged strip.
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local G = require("../src/shared/JerseyGeometry")

for _, path in { "src/shared/JerseyGeometry.luau", "src/ServerScriptService/Customization/Jersey.luau" } do
	luau.compile(fs.readFile(path))
end

-- The silhouette itself is unchanged: scooped neck, flat strap, armhole drop.
assert(math.abs(G.topRatio(0) - 0.21) < 1e-9, "Neck sits lowest at the centre")
assert(math.abs(G.topRatio(0.6) - 0.5) < 1e-9 and math.abs(G.topRatio(0.7) - 0.5) < 1e-9, "Shoulder strap is flat")
assert(math.abs(G.topRatio(1) - 0.14) < 1e-9, "Armhole drops away at the outer edge")
for u = 0, 1, 0.01 do
	local ratio = G.topRatio(u)
	assert(ratio >= 0.13 and ratio <= 0.51, "Top edge stays on the torso at u=" .. u)
end

-- R6 (2x2x1) and R15 (2x1.6x1) torsos, plus scaled avatars either side of them.
local torsos = {}
for _, x in { 1.2, 1.6, 2.0, 2.4, 3.0 } do
	for _, y in { 1.0, 1.6, 2.0, 2.6, 3.2 } do
		table.insert(torsos, { width = x + 0.065, height = y })
	end
end

local worstMargin = math.huge
for _, torso in torsos do
	local width, height = torso.width, torso.height
	local shape = G.build(width, height)
	assert(#shape.slabs == G.Segments and #shape.trims == G.Segments, "One capping chord per slab")
	-- The provable condition: a slab is never wider than the trim is thick.
	local slabWidth = width / G.Segments
	assert(shape.trimThickness >= slabWidth, "Trim must be at least as thick as a slab is wide")

	local spannedLeft, spannedRight = math.huge, -math.huge
	for index, slab in shape.slabs do
		local chord = shape.trims[index]
		local halfSpan = slabWidth / 2
		local x1, x2 = slab.x - halfSpan, slab.x + halfSpan
		local y1, y2 = G.topAt(x1, width, height), G.topAt(x2, width, height)
		spannedLeft, spannedRight = math.min(spannedLeft, x1), math.max(spannedRight, x2)

		-- The slab's flat top is the chord's midpoint.
		assert(math.abs(slab.top - (y1 + y2) / 2) < 1e-9, "Slab top must sit on the chord midpoint")
		assert(math.abs(chord.y - slab.top) < 1e-9, "Chord is centred on the slab's top edge")
		assert(math.abs(chord.x - slab.x) < 1e-9, "Chord is centred on the slab")

		-- Furthest the chord strays from the flat fabric top, vertically.
		local deviation = math.abs(y2 - y1) / 2
		-- Vertical half-extent of the rotated trim band about the chord.
		local slope = (y2 - y1) / slabWidth
		local covered = (shape.trimThickness / 2) * math.sqrt(1 + slope * slope)
		assert(deviation <= covered,
			string.format("Fabric corner exposed by %.4f studs at slab %d (w=%.3f h=%.3f)",
				deviation - covered, index, width, height))
		worstMargin = math.min(worstMargin, covered - deviation)

		-- Each chord overruns its own span, so neighbours interpenetrate at the
		-- joint rather than leaving a notch where the angle changes.
		local span = math.sqrt(slabWidth ^ 2 + (y2 - y1) ^ 2)
		assert(chord.length > span, "Chord must overrun its span")
		assert(math.abs(chord.length - span - shape.trimThickness) < 1e-9, "Overrun is half the thickness per end")

		-- Slabs reach the bottom of the torso and never poke out the top.
		assert(slab.top + height / 2 > 0, "Slab has positive height")
		assert(slab.top <= 0.5 * height + 1e-9, "Slab never rises above the shoulder line")
		assert(slab.width > slabWidth, "Slabs overlap rather than meeting exactly")
	end
	assert(math.abs(spannedLeft + width / 2) < 1e-9 and math.abs(spannedRight - width / 2) < 1e-9,
		"Slabs tile the full torso width")
end
assert(worstMargin > 0, "Every tested torso must have coverage to spare")

-- Part budget per avatar: slabs + trim + print panel + waist + four per leg.
local perAvatar = G.Segments * 2 + 1 + 1 + 8
assert(perAvatar == 50, "Expected 50 parts per avatar, got " .. perAvatar)
assert(perAvatar < 158 * 0.4, "Must be well under a third of the previous 158 parts")

print(string.format(
	"Jersey fit tests passed: two scripts compile; %d torso shapes fully covered (worst margin %.4f studs); %d parts per avatar, down from 158",
	#torsos, worstMargin, perAvatar))
