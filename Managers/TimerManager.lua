function Init(singleKey)
  -- Hotkeys
  hs.hotkey.bind({"alt","cmd"}, "T", toggle)
  hs.hotkey.bind({"alt","cmd"}, "R", reset)
  hs.hotkey.bind({"alt","cmd"}, "G", setGoal)
  hs.hotkey.bind({"alt","cmd"}, "H", hideShow)
  return {
    [singleKey('t', "timer")] = {
      [singleKey('s', "start")] = function () toggle() end
    }
  }
  -- initial draw
end

redraw()

-- === Simple Overlay Timer (Hammerspoon) ===
-- Hotkeys: ⌥⌘T start/stop | ⌥⌘R reset | ⌥⌘G set goal minutes | ⌥⌘H hide/show

local goalMins = 120        -- default goal in minutes
local running  = false
local startAt  = nil
local elapsedS = 0

-- Canvas (floating, draggable)
local w, h = 260, 92
local screen = hs.screen.mainScreen():frame()
local x = screen.x + screen.w - w - 20
local y = screen.y + 40

local c = hs.canvas.new{ x=x, y=y, w=w, h=h }
c:level(hs.canvas.windowLevels.floating)
c:behavior(hs.canvas.windowBehaviors.moveByWindowBackground)
c[1] = { type="rectangle", action="fill", fillColor={alpha=0.85, red=0.08, green=0.08, blue=0.1}, roundedRectRadii={x=14,y=14} }
c[2] = { type="text", frame={x="6%", y="8%", w="88%", h="34%"},
        text="Focus Timer", textSize=18, textColor={hex="#FFFFFF"}, textAlignment="left" }
c[3] = { type="text", frame={x="6%", y="40%", w="88%", h="28%"},
        text="00:00:00  /  02:00:00", textSize=16, textColor={hex="#E6E6E6"}, textAlignment="left" }
c[4] = { type="rectangle", frame={x="6%", y="74%", w="88%", h="12%"},
        action="strokeAndFill", strokeColor={hex="#444"}, fillColor={hex="#222"}, roundedRectRadii={x=8,y=8} }
c[5] = { type="rectangle", frame={x="6%", y="74%", w="0%", h="12%"},
        action="fill", fillColor={hex="#5AC8FA"}, roundedRectRadii={x=8,y=8} }
c:show()

function fmtHMS(sec)
  local h = math.floor(sec/3600)
  local m = math.floor((sec%3600)/60)
  local s = math.floor(sec%60)
  return string.format("%02d:%02d:%02d", h, m, s)
end

function redraw()
  local goalS = goalMins * 60
  local shown = fmtHMS(elapsedS) .. "  /  " .. fmtHMS(goalS)
  c[3].text = shown

  local pct = math.min(1, elapsedS / goalS)
  c[5].frame.w = tostring(6 + pct*88) .. "%"  -- start at 6% left, grow width
  c[2].text = running and "⏱ Focus Timer (running)" or "⏹ Focus Timer (paused)"
end

timer = hs.timer.doEvery(1, function()
  if running and startAt then
    elapsedS = os.time() - startAt
    redraw()
  end
end)

function toggle()
  if running then
    -- pause
    elapsedS = os.time() - startAt
    running = false
  else
    -- resume/start
    startAt = os.time() - elapsedS
    running = true
  end
  redraw()
end

function reset()
  running  = false
  startAt  = nil
  elapsedS = 0
  redraw()
end

function setGoal()
  local btn, txt = hs.dialog.textPrompt("Set goal (minutes)", "Enter total minutes:", tostring(goalMins), "OK", "Cancel")
  if btn == "OK" then
    local v = tonumber(txt)
    if v and v > 0 then
      goalMins = math.floor(v)
      redraw()
    end
  end
end

visible = true
function hideShow()
  visible = not visible
  if visible then c:show() else c:hide() end
end

return Init