local windowManager = require("Managers.WindowManager")
local applicationsManager = require("Managers.ApplicationsManager")
local scrollManager = require("Managers.ScrollManager")
local Toast = require("Managers.ToastWebview")

hs.loadSpoon("RecursiveBinder")

spoon.RecursiveBinder.escapeKey = {{}, 'escape'}  -- Press escape to abort

local singleKey = spoon.RecursiveBinder.singleKey
local windowTable = windowManager(singleKey)
local applicationsTable = applicationsManager(singleKey)
local scrollTable = scrollManager(singleKey)

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
}

for k, v in pairs(windowTable) do
  keyMap[k] = v
end

for k, v in pairs(applicationsTable) do
  keyMap[k] = v
end

for k, v in pairs(scrollTable) do
  keyMap[k] = v
end

hs.hotkey.bind({'control'}, 'space', spoon.RecursiveBinder.recursiveBind(keyMap))

