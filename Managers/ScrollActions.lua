local M = {}

-- Config
local smallStep = 6            -- base pixel step for smooth (lowercase) scrolling
local timerInterval = 0.02     -- seconds between smooth scroll ticks

local bigBaseStep = 3          -- base step for capital scrolling
local repeatFactor = 3.0       -- multiplier for held capital keys
local capitalFactor = 20       -- multiplier for capital (J/K/H/L)

local scrollMode = hs.hotkey.modal.new()

local gPending = false
local gTimer = nil

-- State for smooth lowercase holds
local keyState = {
  j = { timer = nil, startTime = nil },
  k = { timer = nil, startTime = nil },
  h = { timer = nil, startTime = nil },
  l = { timer = nil, startTime = nil },
}

local function scrollVertical(amount)
  hs.eventtap.scrollWheel({0, amount}, {}, "pixel")
end

local function scrollHorizontal(amount)
  hs.eventtap.scrollWheel({amount, 0}, {}, "pixel")
end

local function goTop()
  hs.eventtap.keyStroke({"cmd"}, "up")
end

local function goBottom()
  hs.eventtap.keyStroke({"cmd"}, "down")
end

-- Gentle acceleration for smooth lowercase holds
local function speedFactor(heldSeconds)
  if heldSeconds < 0.3 then
    return 1
  elseif heldSeconds < 1.0 then
    return 1.3
  else
    return 1.7
  end
end

local function stopHoldSmall(key)
  local state = keyState[key]
  if not state then return end
  if state.timer then
    state.timer:stop()
    state.timer = nil
  end
  state.startTime = nil
end

local function startHoldSmall(key, stepFn)
  local state = keyState[key]
  if not state then return end

  if state.timer then
    state.timer:stop()
    state.timer = nil
  end

  state.startTime = hs.timer.secondsSinceEpoch()
  state.timer = hs.timer.doEvery(timerInterval, function()
    local now = hs.timer.secondsSinceEpoch()
    local held = now - (state.startTime or now)
    local factor = speedFactor(held)
    stepFn(factor)
  end)
end

local function bindSmallKey(key, stepFn)
  scrollMode:bind({}, key,
    function()
      -- single small step on tap
      stepFn(1)
      -- start smooth continuous scrolling on hold
      startHoldSmall(key, stepFn)
    end,
    function()
      -- stop when key released
      stopHoldSmall(key)
    end,
    nil
  )
end

local function stopAllSmallHolds()
  for key, _ in pairs(keyState) do
    stopHoldSmall(key)
  end
end

-- Smooth lowercase directional scrolling (jkhl)
bindSmallKey("j", function(factor)
  scrollVertical(-smallStep * factor)
end)

bindSmallKey("k", function(factor)
  scrollVertical(smallStep * factor)
end)

bindSmallKey("h", function(factor)
  scrollHorizontal(-smallStep * factor)
end)

bindSmallKey("l", function(factor)
  scrollHorizontal(smallStep * factor)
end)

-- Capital scrolling: big steps with simple hold (as you liked)
local function bindBigVertical(mods, key, direction, factor)
  local modsOrEmpty = mods or {}
  local step = bigBaseStep * factor * direction
  local repeatStep = step * repeatFactor

  scrollMode:bind(modsOrEmpty, key,
    function()
      scrollVertical(step)
    end,
    nil,
    function()
      scrollVertical(repeatStep)
    end
  )
end

local function bindBigHorizontal(mods, key, direction, factor)
  local modsOrEmpty = mods or {}
  local step = bigBaseStep * factor * direction
  local repeatStep = step * repeatFactor

  scrollMode:bind(modsOrEmpty, key,
    function()
      scrollHorizontal(step)
    end,
    nil,
    function()
      scrollHorizontal(repeatStep)
    end
  )
end

-- J/K/H/L: ~10x bigger steps (kept as-is)
bindBigVertical({"shift"}, "j", -1, capitalFactor)
bindBigVertical({"shift"}, "k",  1, capitalFactor)
bindBigHorizontal({"shift"}, "h", -1, capitalFactor)
bindBigHorizontal({"shift"}, "l",  1, capitalFactor)

-- gg (top) and G (bottom)
scrollMode:bind({}, "g", function()
  if gPending then
    if gTimer then gTimer:stop(); gTimer = nil end
    gPending = false
    goTop()
  else
    gPending = true
    gTimer = hs.timer.doAfter(1.0, function()
      gPending = false
      gTimer = nil
    end)
  end
end)

scrollMode:bind({"shift"}, "g", function()
  goBottom()
end)

function M.enterScrollMode()
  hs.alert.show("Scroll mode: h/j/k/l, gg, G, Esc")
  gPending = false
  if gTimer then gTimer:stop(); gTimer = nil end
  stopAllSmallHolds()
  scrollMode:enter()
end

function M.exitScrollMode()
  scrollMode:exit()
  gPending = false
  if gTimer then gTimer:stop(); gTimer = nil end
  stopAllSmallHolds()
end

scrollMode:bind({}, "escape", function()
  M.exitScrollMode()
end)

function M.toggleScrollDirection()
  local currentSetting = hs.settings.get("com.apple.swipescrolldirection")
  if currentSetting == "1" then
    hs.settings.set("com.apple.swipescrolldirection", "0")
  else
    hs.settings.set("com.apple.swipescrolldirection", "1")
  end
  hs.alert.show(hs.settings.get("com.apple.swipescrolldirection") == "1" and "Natural Scrolling On" or "Natural Scrolling Off")
end

return M
