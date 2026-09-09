--!strict
-- Pure jersey silhouette maths, free of Roblox globals so the fit can be proved
-- outside Studio. See tests/jersey_fit.spec.luau.
--
-- The top edge is drawn as flat-topped fabric slabs capped by a rotated trim
-- chord. A slab's top sits on its chord's MIDPOINT, so the chord strays at most
-- half a slab's rise above or below it. The trim covers a band of
-- (thickness / 2) * sqrt(1 + slope^2) either side of the chord, which is at
-- least (thickness / 2) * slope. So whenever a slab is no wider than the trim is
-- thick, the fabric corners are covered at EVERY slope -- including the steep
-- drop into each armhole, where a fixed thin trim leaves them exposed.
local JerseyGeometry = {}

-- Wider slabs mean far fewer parts welded to each avatar.
JerseyGeometry.Segments = 20
-- Trim thickness as a multiple of slab width; anything >= 1 is provably covering.
JerseyGeometry.TrimMargin = 1.15
JerseyGeometry.MinTrim = 0.06
-- Slabs overlap slightly rather than meeting exactly, keeping their side faces
-- out of a shared plane where they would shimmer against each other.
JerseyGeometry.SlabOverlap = 0.004
-- The trim wraps the full torso depth plus this, so it encloses the fabric edge
-- instead of floating in front of it as a separate ribbon.
JerseyGeometry.TrimDepthMargin = 0.05

export type Slab = { x: number, width: number, top: number }
export type Chord = { x: number, y: number, length: number, angle: number }
export type Shape = { slabs: { Slab }, trims: { Chord }, trimThickness: number }

-- Height of the top edge at |x| ratio u, as a fraction of torso height:
-- a scooped neck, a flat shoulder strap, then a steep drop into the armhole.
function JerseyGeometry.topRatio(u: number): number
	if u < 0.60 then
		return 0.21 + 0.29 * (u / 0.60) ^ 2
	end
	if u > 0.78 then
		return 0.5 - 0.36 * ((u - 0.78) / 0.22) ^ 2
	end
	return 0.5
end

function JerseyGeometry.topAt(x: number, width: number, height: number): number
	return JerseyGeometry.topRatio(math.abs(x) * 2 / width) * height
end

function JerseyGeometry.build(width: number, height: number): Shape
	local segments = JerseyGeometry.Segments
	local slabWidth = width / segments
	local thickness = math.max(JerseyGeometry.MinTrim, slabWidth * JerseyGeometry.TrimMargin)
	local shape: Shape = { slabs = {}, trims = {}, trimThickness = thickness }
	for index = 1, segments do
		local x1 = -width / 2 + (index - 1) * slabWidth
		local x2 = x1 + slabWidth
		local y1 = JerseyGeometry.topAt(x1, width, height)
		local y2 = JerseyGeometry.topAt(x2, width, height)
		local midX, midY = (x1 + x2) / 2, (y1 + y2) / 2
		table.insert(shape.slabs, { x = midX, width = slabWidth + JerseyGeometry.SlabOverlap, top = midY })
		local dx, dy = x2 - x1, y2 - y1
		-- Overrun each end by half the thickness so neighbouring chords
		-- interpenetrate instead of leaving a notch where the angle changes.
		table.insert(shape.trims, {
			x = midX,
			y = midY,
			length = math.sqrt(dx * dx + dy * dy) + thickness,
			angle = math.atan2(dy, dx),
		})
	end
	return shape
end

return JerseyGeometry
