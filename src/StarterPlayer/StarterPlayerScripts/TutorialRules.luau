-- Pure client decisions, shared by the guide and failure-path tests.
local Rules={}
function Rules.ready(result)
 return type(result)=="table" and result.ready==true and type(result.tutorialDone)=="boolean"
end
function Rules.saved(result)
 return Rules.ready(result) and result.code=="TUTORIAL_COMPLETED" and result.tutorialDone
end
function Rules.advance(step,action,result)
 if type(result)~="table" or result.ready~=true or type(result.rollState)~="table" then return step end
 if step==1 and action=="RollState" and result.code=="READY" then return 2 end
 if step==2 and (action=="RollPlayer" or action=="ChooseRare") and (result.code=="ROLLED" or result.code=="FINISHED") then return 3 end
 if step==7 and action=="TutorialRunFinished" and result.rollState.finished then return 8 end
 return step
end
-- Returns only after a confirmed save. Exceptions, malformed replies and BUSY
-- all leave completion false; callers can explicitly retry without resetting it.
function Rules.save(invoke,wait)
 for attempt=1,4 do
  local ok,result=pcall(invoke)
  if ok and Rules.saved(result) then return true end
  if attempt<4 then wait(.6) end
 end
 return false
end
-- Arrow ends on the nearest target edge. Inputs are live rectangles in one
-- safe-area coordinate system, not design-time button positions.
function Rules.arrow(cx,cy,tx,ty,tw,th)
 local mx,my=tx+tw/2,ty+th/2
 local dx,dy=cx-mx,cy-my
 if dx==0 and dy==0 then return mx,ty end
 local ratio=math.max(math.abs(dx)/math.max(tw/2,1),math.abs(dy)/math.max(th/2,1))
 return mx+dx/ratio,my+dy/ratio
end
-- All panels use the SAME integer edges. Independently rounded fractional
-- positions/sizes can reveal a bright seam or double-dark overlapping strip.
function Rules.shades(width,height,x,y,w,h)
 width=math.ceil(width);height=math.ceil(height)
 if w<=0 or h<=0 then
  return {{0,0,width,height},{0,0,0,0},{0,0,0,0},{0,0,0,0}}
 end
 local left=math.clamp(math.floor(x),0,width)
 local top=math.clamp(math.floor(y),0,height)
 local right=math.clamp(math.ceil(x+w),left,width)
 local bottom=math.clamp(math.ceil(y+h),top,height)
 return {{0,0,width,top},{0,bottom,width,height-bottom},{0,top,left,bottom-top},{right,top,width-right,bottom-top}}
end
return Rules
