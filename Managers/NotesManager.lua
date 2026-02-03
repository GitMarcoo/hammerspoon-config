-- NotesManager: Obsidian daily notes shortcuts

-- Configure these paths per machine
local VAULT_PATH = "/Users/marcodeboer/Documents/Vault1" -- <-- maak dit ABSOLUUT
local DAILY_NOTES_SUBDIR = "Daily_Notes"

local function vaultAbsolute()
  local abs = hs.fs.pathToAbsolute(VAULT_PATH)
  if not abs then
    hs.alert.show("VAULT_PATH not found: " .. tostring(VAULT_PATH))
    return nil
  end
  return abs
end

local function dailyFolderPath()
  local vault = vaultAbsolute()
  if not vault then return nil end
  return vault .. "/" .. DAILY_NOTES_SUBDIR
end

local function ensureDirExists(dir)
  if not dir then return nil end
  if hs.fs.attributes(dir, "mode") == "directory" then
    return true
  end

  -- mkdir -p
  local ok = hs.fs.mkdir(dir)
  if ok then return true end

  -- fallback: try shell mkdir -p (some setups behave nicer)
  local _, _, _, rc = hs.execute(string.format('mkdir -p "%s"', dir))
  if rc ~= 0 then
    hs.alert.show("Could not create dir: " .. dir)
    return nil
  end
  return true
end

local function buildDailyNotePath(offsetDays)
  local folder = dailyFolderPath()
  if not ensureDirExists(folder) then return nil end

  -- Use noon to reduce DST weirdness
  local base = os.date("*t")
  base.hour = 12; base.min = 0; base.sec = 0
  local targetTime = os.time(base) + (offsetDays * 24 * 60 * 60)

  local filename = os.date("%Y-%m-%d", targetTime) .. ".md"
  return folder .. "/" .. filename
end

local function ensureFileExists(path)
  if not path then return nil end

  -- bestaat het al?
  if hs.fs.attributes(path) then
    return true
  end

  -- maak bestand via shell (betrouwbaar)
  local cmd = string.format('touch "%s"', path)
  local _, _, _, rc = hs.execute(cmd)

  if rc ~= 0 then
    hs.alert.show("Could not create note:\n" .. path)
    return nil
  end

  return true
end


local function urlEncode(str)
  return (str:gsub("([^%w%-_%.~])", function(c)
    return string.format("%%%02X", string.byte(c))
  end))
end

local function openInObsidian(path)
  if not path then return end
  -- Open exact file in Obsidian
  local url = "obsidian://open?path=" .. urlEncode(path)
  hs.urlevent.openURL(url)
end

function openDailyNote(offsetDays)
  local path = buildDailyNotePath(offsetDays)
  if ensureFileExists(path) then
    openInObsidian(path)
  end
end

function Init(singleKey)
    local lastOpenedDay = nil

    local function openTodayOncePerDay()
      local today = os.date("%Y-%m-%d")
      if lastOpenedDay == today then
        return
      end

      lastOpenedDay = today
      openDailyNote(0)
    end

    local wakeWatcher = hs.caffeinate.watcher.new(function(event)
      if event == hs.caffeinate.watcher.systemDidWake
         or event == hs.caffeinate.watcher.screensDidUnlock then
        openTodayOncePerDay()
      end
    end)

    wakeWatcher:start()

    local openTomorrowTimer

    local function startOpenTomorrowAt1700()
      if openTomorrowTimer then return end

      openTomorrowTimer = hs.timer.doAt("17:00", function()
        hs.alert.show("17:00 -> open tomorrow note")
        openDailyNote(1)
      end)

      openTomorrowTimer:start()
    end

    startOpenTomorrowAt1700()

  return {
    [singleKey('n', 'notes')] = {
      [singleKey('t', 'today note')] = function() openDailyNote(0) end,
      [singleKey('n', 'tomorrow note')] = function() openDailyNote(1) end,
      [singleKey('p', 'yesterday note')] = function() openDailyNote(-1) end,
    },
  }
end







return Init
