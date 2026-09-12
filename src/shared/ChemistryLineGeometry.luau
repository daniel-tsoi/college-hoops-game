-- Visible intervals of a straight segment, excluding every card's rectangle.
local Geometry = {}
function Geometry.visible(ax, ay, bx, by, rectangles)
	local dx, dy = bx - ax, by - ay
	local spans = {{0, 1}}
	for _, r in ipairs(rectangles) do
		local enter, leave = 0, 1
		for _, axis in ipairs({{ax, dx, r.x, r.x + r.w}, {ay, dy, r.y, r.y + r.h}}) do
			local origin, delta, low, high = table.unpack(axis)
			if math.abs(delta) < 0.00001 then
				if origin < low or origin > high then enter, leave = 1, 0 end
			else
				local first, last = (low - origin) / delta, (high - origin) / delta
				enter = math.max(enter, math.min(first, last))
				leave = math.min(leave, math.max(first, last))
			end
		end
		if enter < leave then
			local remaining = {}
			for _, span in ipairs(spans) do
				if leave <= span[1] or enter >= span[2] then
					table.insert(remaining, span)
				else
					if enter > span[1] then table.insert(remaining, {span[1], enter}) end
					if leave < span[2] then table.insert(remaining, {leave, span[2]}) end
				end
			end
			spans = remaining
		end
	end
	return spans
end
return Geometry
