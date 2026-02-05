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
        [singleKey('m', 'resize split mode')] = function () spoon.MiroWindowsManager.enterResizeSplitMode() end
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