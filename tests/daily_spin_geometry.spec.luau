local G=require("../src/shared/DailySpinGeometry")
for degrees=0,359 do
 local x,y,rotation=G.ray(230,degrees)
 local dx,dy=math.cos(math.rad(rotation))*115,math.sin(math.rad(rotation))*115
 assert(math.abs(x-dx-230)<1e-8 and math.abs(y-dy-230)<1e-8,"Every strip starts at the wheel center")
 assert(math.abs(((x+dx-230)^2+(y+dy-230)^2)^.5-230)<1e-8,"Every strip ends on the rim")
end
for current=0,359 do
 for index=1,5 do
  for _,fraction in ipairs({0,.25,.5,.75,1}) do
   local target=G.target(current,index,5,fraction)
   assert(target-current>=1800 and target-current<2160,"At least five clockwise turns")
   local angle=(-target)%360
   assert(math.floor(angle/72)+1==index,"Pointer must land on the server-awarded prize")
   local within=angle%72
   assert(within>14 and within<58,"Never land on a divider")
  end
 end
end
print("Daily spinner: centered rays, circular rim, clockwise turns and all prize landing positions passed")
