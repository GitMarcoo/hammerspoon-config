-- NotesManager: Obsidian daily notes shortcuts

-- Configure these paths per machine
local VAULT_PATH = "marcodeboer/Documents/Vault1"      -- full path to your Obsidian vault (edit this)
local DAILY_NOTES_SUBDIR = "Daily_Notes"            -- folder inside the vault for daily notes

local function buildDailyNotePath(offsetDays)
  if VAULT_PATH == "/path/to/your/vault" then
    hs.alert.show("Set VAULT_PATH in Managers/NotesManager.lua")
    return nil
  end

  local baseTime = os.time()
  local targetTime = baseTime + (offsetDays * 24 * 60 * 60)
  local filename = os.date("%Y-%m-%d", targetTime) .. ".md"

  local sep = "/"
  local path = VAULT_PATH .. sep .. DAILY_NOTES_SUBDIR .. sep .. filename
  return path
end

local function ensureFileExists(path)
  if not path then return nil end

  local f = io.open(path, "r")
  if f then
    f:close()
    return true
  end

  -- Try to create the file if it doesn't exist
  -- Best-effort: assume the folder exists; just create the file
  local newFile, err = io.open(path, "w")
  if not newFile then
    hs.alert.show("Could not create note: " .. tostring(err))
    return nil
  end
  newFile:write("")
  newFile:close()
  return true
end

local function openInObsidian(path)
  if not path then return end
  -- Open the markdown file with Obsidian (assuming it is installed)
  local cmd = string.format('open -a "Obsidian" "%s"', path)
  hs.execute(cmd)
end

local function openDailyNote(offsetDays)
  local path = buildDailyNotePath(offsetDays)
  if ensureFileExists(path) then
    openInObsidian(path)
  end
end

function Init(singleKey)
  return {
    [singleKey('n', 'notes')] = {
      [singleKey('c', 'today note')] = function() openDailyNote(0) end,
      [singleKey('n', 'tomorrow note')] = function() openDailyNote(1) end,
      [singleKey('p', 'yesterday note')] = function() openDailyNote(-1) end,
    },
  }
end

return Init
