local windowManager = require("Managers.WindowManager")
local applicationsManager = require("Managers.ApplicationsManager")

hs.alert.show("Hammerspoon loaded!")

hs.loadSpoon("RecursiveBinder")

spoon.RecursiveBinder.escapeKey = {{}, 'escape'}  -- Press escape to abort

local singleKey = spoon.RecursiveBinder.singleKey
local windowTable = windowManager(singleKey)
local applicationsTable = applicationsManager(singleKey)

local keyMap = {
  [singleKey('h', 'hammerspoon+')] = {
    [singleKey('r', 'reload')] = function() hs.reload() hs.console.clearConsole() end,
    [singleKey('c', 'config')] = function() hs.execute("/usr/local/bin/code ~/.hammerspoon") end
  },
  [singleKey('s', 'scroll')] = {
    [singleKey('j', 'down')] = function () hs.eventtap.scrollWheel({0, -100}, {}, nil) end
  }
}

for k, v in pairs(windowTable) do
  keyMap[k] = v
end

for k, v in pairs(applicationsTable) do
  keyMap[k] = v
end


hs.hotkey.bind({'control'}, 'space', spoon.RecursiveBinder.recursiveBind(keyMap))

