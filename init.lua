local windowManager = require("Managers.WindowManager")
local applicationsManager = require("Managers.ApplicationsManager")
local Toast = require("Managers.Toast")

hs.alert.show("Hammerspoon loaded!")

hs.loadSpoon("RecursiveBinder")

spoon.RecursiveBinder.escapeKey = {{}, 'escape'}  -- Press escape to abort

local singleKey = spoon.RecursiveBinder.singleKey
local windowTable = windowManager(singleKey)
local applicationsTable = applicationsManager(singleKey)

local keyMap = {
  [singleKey('h', 'hammerspoon+')] = {
    [singleKey('r', 'reload')] = function() hs.reload() hs.console.clearConsole() end,
    [singleKey('c', 'config')] = function() hs.execute("code ~/.hammerspoon .") end,
    [singleKey('d', 'daily 8h check')] = function()
      local ok, err = pcall(function()
        Toast.show{
          title   = "Daily Check-in",
          message = "Did you work 8 hours today?",
          buttons = {
            { id = "yes", label = "Yes" },
            { id = "no",  label = "No"  },
          },
          duration = 0, -- stay until user clicks
          onResult = function(result)
            if result.reason == "button" then
              if result.button == "yes" then
                hs.alert.show("Nice work today!")
              elseif result.button == "no" then
                hs.alert.show("There is always tomorrow.")
              end
            end
          end,
        }
      end)
      if not ok then
        hs.alert.show("Toast error: " .. tostring(err))
      end
    end,
  },
  [singleKey('s', 'scroll')] = {
    [singleKey('j', 'down')] = function () hs.eventtap.scrollWheel({0, -100}, {}, nil) end,
    [singleKey('c', 'change')] = function () changeScroll() end
  },
}

for k, v in pairs(windowTable) do
  keyMap[k] = v
end

for k, v in pairs(applicationsTable) do
  keyMap[k] = v
end

function changeScroll()
  local currentSetting = hs.settings.get("com.apple.swipescrolldirection")
  if currentSetting == "1" then -- Natural scrolling is on
    hs.settings.set("com.apple.swipescrolldirection", "0") -- Turn natural scrolling off
  else
    hs.settings.set("com.apple.swipescrolldirection", "1") -- Turn natural scrolling on
  end
  hs.alert.show(hs.settings.get("com.apple.swipescrolldirection") == "1" and "Natural Scrolling On" or "Natural Scrolling Off")
end

hs.hotkey.bind({'control'}, 'space', spoon.RecursiveBinder.recursiveBind(keyMap))

