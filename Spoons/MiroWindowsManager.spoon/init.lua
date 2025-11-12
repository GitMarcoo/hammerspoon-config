-- Managers/WindowActions.lua
local M = {}

-- Config (tweak if you like)
M.sizes = { 2, 3, 3/2 }
M.fullScreenSizes = { 1, 4/3, 2 }
M.GRID = { w = 24, h = 24 }

function M.init(opts)
  if opts and opts.grid then M.GRID = opts.grid end
  hs.grid.setGrid(M.GRID.w .. "x" .. M.GRID.h)
  hs.grid.MARGINX = opts and opts.marginX or 0
  hs.grid.MARGINY = opts and opts.marginY or 0
end

local function nextStep(dim, offs, cb)
  local win = hs.window.frontmostWindow()
  if not win then return end
  local screen = win:screen()
  local cell = hs.grid.get(win, screen)

  local axis    = (dim == "w") and "x" or "y"
  local oppDim  = (dim == "w") and "h" or "w"
  local oppAxis = (dim == "w") and "y" or "x"

  local nextSize = M.sizes[1]
  for i = 1, #M.sizes do
    if cell[dim] == M.GRID[dim] / M.sizes[i]
       and ((cell[axis] + (offs and cell[dim] or 0)) == (offs and M.GRID[dim] or 0)) then
      nextSize = M.sizes[(i % #M.sizes) + 1]
      break
    end
  end

  cb(cell, nextSize)

  if cell[oppAxis] ~= 0 and (cell[oppAxis] + cell[oppDim] ~= M.GRID[oppDim]) then
    cell[oppDim] = M.GRID[oppDim]
    cell[oppAxis] = 0
  end

  hs.grid.set(win, cell, screen)
end

-- Public actions
function M.left()
  nextStep("w", false, function(cell, nextSize)
    cell.x = 0
    cell.w = M.GRID.w / nextSize
  end)
end

function M.right()
  nextStep("w", true, function(cell, nextSize)
    cell.x = M.GRID.w - M.GRID.w / nextSize
    cell.w = M.GRID.w / nextSize
  end)
end

function M.up()
  nextStep("h", false, function(cell, nextSize)
    cell.y = 0
    cell.h = M.GRID.h / nextSize
  end)
end

function M.down()
  nextStep("h", true, function(cell, nextSize)
    cell.y = M.GRID.h - M.GRID.h / nextSize
    cell.h = M.GRID.h / nextSize
  end)
end

function M.maxWidth()
  local win = hs.window.frontmostWindow(); if not win then return end
  local screen = win:screen()
  local cell = hs.grid.get(win, screen)
  cell.w = M.GRID.w; cell.x = 0
  hs.grid.set(win, cell, screen)
end

function M.maxHeight()
  local win = hs.window.frontmostWindow(); if not win then return end
  local screen = win:screen()
  local cell = hs.grid.get(win, screen)
  cell.h = M.GRID.h; cell.y = 0
  hs.grid.set(win, cell, screen)
end

function M.centerCycle() -- cycles 1x, 3/4, 1/2 centered
  local win = hs.window.frontmostWindow(); if not win then return end
  local screen = win:screen()
  local cell = hs.grid.get(win, screen)

  local nextSize = M.fullScreenSizes[1]
  for i = 1, #M.fullScreenSizes do
    local s = M.fullScreenSizes[i]
    if cell.w == M.GRID.w / s and cell.h == M.GRID.h / s
       and cell.x == (M.GRID.w - M.GRID.w / s) / 2
       and cell.y == (M.GRID.h - M.GRID.h / s) / 2 then
      nextSize = M.fullScreenSizes[(i % #M.fullScreenSizes) + 1]
      break
    end
  end

  cell.w = M.GRID.w / nextSize
  cell.h = M.GRID.h / nextSize
  cell.x = (M.GRID.w - cell.w) / 2
  cell.y = (M.GRID.h - cell.h) / 2
  hs.grid.set(win, cell, screen)
end

function M.nextScreen()
  local win = hs.window.frontmostWindow(); if not win then return end
  local screen = win:screen()
  win:move(win:frame():toUnitRect(screen:frame()), screen:next(), true, 0)
end

return M
