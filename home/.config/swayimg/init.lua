local viewer = swayimg.viewer

local SWIPE_THRESHOLD = 30

local swipe_distance = 0

local function open_previous() viewer.open("prev") end
local function open_next() viewer.open("next") end

local function on_swipe(_, horizontal, _)
  swipe_distance = swipe_distance + horizontal
  if swipe_distance <= -SWIPE_THRESHOLD then
    swipe_distance = 0
    open_next()
  elseif swipe_distance >= SWIPE_THRESHOLD then
    swipe_distance = 0
    open_previous()
  end
end

viewer.on_key({ "h", "Left" }, open_previous)
viewer.on_key({ "l", "Right" }, open_next)
viewer.on_scroll(on_swipe)
