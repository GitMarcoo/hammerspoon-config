local Toast = {}

local currentToast = nil

local defaultConfig = {
  width    = 320,
  height   = 110,
  margin   = { x = 20, y = 40 },
  position = "topRight", -- topRight, topLeft, bottomRight, bottomLeft, center
  duration = 5,           -- seconds; 0 or nil = until dismissed
}

local function hideCurrent(reason, buttonId, inputText)
  if not currentToast then return end

  local t = currentToast
  currentToast = nil

  if t.timer then
    t.timer:stop()
  end

  if t.canvas then
    t.canvas:delete()
  end

  if t.onResult then
    t.onResult({
      reason = reason or "dismiss",
      button = buttonId,
      input  = inputText,
    })
  end
end

local function computeFrame(opts)
  local screen   = (opts and opts.screen) or hs.screen.mainScreen()
  local frame    = screen:frame()
  local width    = (opts and opts.width) or defaultConfig.width
  local height   = (opts and opts.height) or defaultConfig.height
  local margin   = (opts and opts.margin) or defaultConfig.margin
  local position = (opts and opts.position) or defaultConfig.position

  local x, y

  if position == "topLeft" then
    x = frame.x + margin.x
    y = frame.y + margin.y
  elseif position == "bottomLeft" then
    x = frame.x + margin.x
    y = frame.y + frame.h - height - margin.y
  elseif position == "bottomRight" then
    x = frame.x + frame.w - width - margin.x
    y = frame.y + frame.h - height - margin.y
  elseif position == "center" then
    x = frame.x + (frame.w - width) / 2
    y = frame.y + (frame.h - height) / 2
  else -- topRight (default)
    x = frame.x + frame.w - width - margin.x
    y = frame.y + margin.y
  end

  return { x = x, y = y, w = width, h = height }
end

--- Toast.show(opts)
--- opts = {
---   title    = string | nil,
---   message  = string (required),
---   buttons  = { { id = string, label = string }, ... } | nil,
---   duration = number (seconds) | 0 | nil,
---   position = "topRight" | "topLeft" | "bottomRight" | "bottomLeft" | "center",
---   margin   = { x = number, y = number } | nil,
---   width    = number | nil,
---   height   = number | nil,
---   onResult = function(result) end,
--- }
function Toast.show(opts)
  if not opts or not opts.message then
    return
  end

  -- Close any existing toast first
  if currentToast then
    hideCurrent("dismiss")
  end

  local hasTitle   = opts.title ~= nil
  local buttons    = opts.buttons or {}
  local hasButtons = #buttons > 0

  -- Adjust height based on content (very simple heuristic)
  local baseHeight = 80
  if hasTitle then baseHeight = baseHeight + 18 end
  if hasButtons then baseHeight = baseHeight + 34 end

  local frame = computeFrame({
    screen   = opts.screen,
    width    = opts.width or defaultConfig.width,
    height   = opts.height or baseHeight,
    margin   = opts.margin,
    position = opts.position,
  })


  local c = hs.canvas.new(frame)
  c:level(hs.canvas.windowLevels.floating)
  -- Background (match-ish Focus Timer style)
  c[1] = {
    type = "rectangle",
    action = "fill",
    fillColor = { alpha = 0.9, red = 0.08, green = 0.08, blue = 0.10 },
    roundedRectRadii = { x = 14, y = 14 },
  }

  local idx = 2

  if hasTitle then
    c[idx] = {
      type="text",
      frame={ x="6%", y="8%", w="88%", h="24%" },
      text=opts.title,
      textSize=16,
      textColor={ hex="#FFFFFF" },
      textAlignment="left",
    }
    idx = idx + 1
  end

  -- Message text
  c[idx] = {
    type="text",
    frame={ x="6%", y= hasTitle and "32%" or "14%", w="88%", h= hasButtons and "40%" or "70%" },
    text=opts.message,
    textSize=14,
    textColor={ hex="#E6E6E6" },
    textAlignment="left",
  }
  idx = idx + 1

  local buttonElementToId = {}

  -- Close 'X' button at top-right
  do
    local closeBgIndex = idx
    c[closeBgIndex] = {
      type = "rectangle",
      frame = { x = "88%", y = "6%", w = "8%", h = "20%" },
      action = "fill",
      fillColor = { alpha = 0 }, -- invisible clickable area
      roundedRectRadii = { x = 4, y = 4 },
      trackMouseDown = true,
    }
    buttonElementToId[closeBgIndex] = "__close"
    idx = idx + 1

    c[idx] = {
      type = "text",
      frame = { x = "88%", y = "6%", w = "8%", h = "20%" },
      text = "×",
      textSize = 14,
      textColor = { hex = "#FFFFFF" },
      textAlignment = "center",
    }
    idx = idx + 1
  end

  if hasButtons then
    local btnCount = #buttons
    if btnCount > 0 then
      local totalWidthPct = 88    -- total width reserved for all buttons
      local gapPct        = 4     -- gap between buttons
      local btnWidthPct   = (totalWidthPct - gapPct * (btnCount - 1)) / btnCount
      local startXPct     = 6
      local yPct          = 72
      local hPct          = 18

      for i, btn in ipairs(buttons) do
        local xPct = startXPct + (i - 1) * (btnWidthPct + gapPct)

        -- Button background
        c[idx] = {
          type = "rectangle",
          frame = {
            x = string.format("%d%%", xPct),
            y = string.format("%d%%", yPct),
            w = string.format("%d%%", btnWidthPct),
            h = string.format("%d%%", hPct),
          },
          action = "fill",
          fillColor = { hex = "#333333" },
          roundedRectRadii = { x = 8, y = 8 },
          trackMouseDown = true,
        }

        buttonElementToId[idx] = btn.id or tostring(i)
        idx = idx + 1

        -- Button label
        c[idx] = {
          type="text",
          frame={
            x = string.format("%d%%", xPct),
            y = string.format("%d%%", yPct),
            w = string.format("%d%%", btnWidthPct),
            h = string.format("%d%%", hPct),
          },
          text = btn.label or btn.id or ("Button " .. tostring(i)),
          textSize = 13,
          textColor = { hex = "#FFFFFF" },
          textAlignment = "center",
        }
        idx = idx + 1
      end
    end
  end

  -- Mouse callback for buttons and close 'X'
  c:mouseCallback(function(canvas, event, id, x, y)
    local mapped = buttonElementToId[id]
    if event == "mouseDown" and mapped then
      if mapped == "__close" then
        hideCurrent("dismiss", nil, nil)
      else
        hideCurrent("button", mapped, nil)
      end
    end
  end)

  c:show()

  local duration = opts.duration
  local timer
  if duration and duration > 0 then
    timer = hs.timer.doAfter(duration, function()
      hideCurrent("timeout", nil, nil)
    end)
  end

  currentToast = {
    canvas   = c,
    timer    = timer,
    onResult = opts.onResult,
  }

  return {
    hide = function(reason)
      hideCurrent(reason or "dismiss")
    end
  }
end

return Toast
