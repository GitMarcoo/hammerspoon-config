local resizeStep = 40
local resizeMode = hs.hotkey.modal.new()

local function adjustWindowWidth(delta)
  local win = hs.window.focusedWindow()
  if not win then
    hs.alert.show("No focused window!")
    return
  end

  local screen = win:screen()
  local screenFrame = screen:frame()
  local winFrame = win:frame()
  local minWidth = 200

  -- Find the "other" window on the same screen with the
  -- largest vertical overlap (the most likely split partner).
  local windows = hs.window.visibleWindows()
  local bestNeighbor = nil
  local bestOverlap = 0

  for _, w in ipairs(windows) do
    if w ~= win and w:screen() == screen then
      local f = w:frame()
      local overlapTop = math.max(winFrame.y, f.y)
      local overlapBottom = math.min(winFrame.y + winFrame.h, f.y + f.h)
      local overlap = math.max(0, overlapBottom - overlapTop)
      if overlap > bestOverlap then
        bestOverlap = overlap
        bestNeighbor = w
      end
    end
  end

  if bestNeighbor and bestOverlap > 0 then
    -- Treat them as left/right neighbors and move the split.
    local neighborFrame = bestNeighbor:frame()

    local leftWin, rightWin, leftFrame, rightFrame
    if winFrame.x <= neighborFrame.x then
      leftWin, rightWin = win, bestNeighbor
      leftFrame, rightFrame = winFrame, neighborFrame
    else
      leftWin, rightWin = bestNeighbor, win
      leftFrame, rightFrame = neighborFrame, winFrame
    end

    local splitX = rightFrame.x
    local newSplitX = splitX + delta

    local minX = screenFrame.x + minWidth
    local maxX = screenFrame.x + screenFrame.w - minWidth
    if newSplitX < minX then newSplitX = minX end
    if newSplitX > maxX then newSplitX = maxX end

    leftFrame.x = screenFrame.x
    leftFrame.w = newSplitX - screenFrame.x
    leftFrame.y = screenFrame.y
    leftFrame.h = screenFrame.h

    rightFrame.x = newSplitX
    rightFrame.w = screenFrame.x + screenFrame.w - newSplitX
    rightFrame.y = screenFrame.y
    rightFrame.h = screenFrame.h

    leftWin:setFrame(leftFrame)
    rightWin:setFrame(rightFrame)
  else
    -- Fallback: just resize the focused window.
    winFrame.w = math.max(minWidth, math.min(screenFrame.w, winFrame.w + delta))
    win:setFrame(winFrame)
  end
end

local function enterResizeSplitMode()
  hs.alert.show("Resize mode: h/l, Esc to exit")
  resizeMode:enter()
end

resizeMode:bind({}, 'h', function()
  adjustWindowWidth(-resizeStep)
end, nil, function()
  adjustWindowWidth(-resizeStep)
end)

resizeMode:bind({}, 'l', function()
  adjustWindowWidth(resizeStep)
end, nil, function()
  adjustWindowWidth(resizeStep)
end)

resizeMode:bind({}, 'escape', function()
  resizeMode:exit()
end)

function Init(singleKey)
  hs.loadSpoon("MiroWindowsManager")

  return {
    [singleKey('w', 'window')] = {
      [singleKey('f', 'fullscreen')] = function () spoon.MiroWindowsManager.maxWidth() spoon.MiroWindowsManager.maxHeight() end,
      [singleKey('j', 'bottom')] = function () spoon.MicroWindowsManager.down() end,
      [singleKey('k', 'top')] = function () spoon.MiroWindowsManager.top() end,
      [singleKey('h', 'left')] = function () spoon.MiroWindowsManager.left() end,
      [singleKey('l', 'right')] = function () spoon.MiroWindowsManager.right() end,
      [singleKey('s', 'swap / move')] = {
        [singleKey('s', 'swap screens')] = function () SwapScreens() end,
        [singleKey('m', 'move split mode')] = function () enterResizeSplitMode() end
      },
      [singleKey('n', 'moveNextScreen')] = function () MoveActiveAppToOtherScreen() end
    },
  }
end

function SwapScreens()
    local screens = hs.screen.allScreens()
    if #screens < 2 then
        hs.alert.show("Need 2 screens!")
        return
    end

    local screen1 = screens[1]
    local screen2 = screens[2]
    local windows = hs.window.visibleWindows()

    for _, win in ipairs(windows) do
        local screen = win:screen()
        if screen == screen1 then
            win:moveToScreen(screen2)
        elseif screen == screen2 then
            win:moveToScreen(screen1)
        end
    end
end

function MoveActiveAppToOtherScreen()
    local win = hs.window.focusedWindow()
    if not win then
        hs.alert.show("No focused window!")
        return
    end

    local currentScreen = win:screen()
    local allScreens = hs.screen.allScreens()

    if #allScreens < 2 then
        hs.alert.show("Need 2 screens!")
        return
    end

    -- Pick the other screen
    local otherScreen = (currentScreen == allScreens[1]) and allScreens[2] or allScreens[1]

    -- Move all windows of the focused app to the other screen
    local app = win:application()
    local appWindows = app:allWindows()

    for _, w in ipairs(appWindows) do
        if w:isStandard() then
            w:moveToScreen(otherScreen)
            spoon.MiroWindowsManager.maxWidth() spoon.MiroWindowsManager.maxHeight()
        end
    end
end


return Init