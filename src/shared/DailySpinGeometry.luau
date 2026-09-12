local Geometry={}

-- GuiObjects rotate around their center, regardless of AnchorPoint.
function Geometry.ray(radius,degrees)
 local angle=math.rad(degrees-90)
 return radius+math.cos(angle)*radius/2,radius+math.sin(angle)*radius/2,degrees-90
end

function Geometry.target(current,index,count,fraction)
 local width=360/count
 -- Keep the pointer away from dividers; randomness here is cosmetic only.
 local landing=(index-1+(.2+.6*math.clamp(fraction,0,1)))*width
 return current+360*5+((-landing-current)%360)
end

return Geometry
