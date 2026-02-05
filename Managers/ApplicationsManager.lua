function Init(singleKey)
  return {
    [singleKey('a', "applications")] = {
      [singleKey('t', 'terminal')] = function() hs.application.launchOrFocus("Ghostty") end,
      [singleKey('c', 'chrome')] = function () hs.application.launchOrFocus("Google Chrome") end,
      [singleKey('v', 'vscode')] = function () hs.application.launchOrFocus("Visual Studio Code") end,
      [singleKey('i', 'intelij')] = function () hs.application.launchOrFocus("Intellij IDEA") end,
      [singleKey('o', 'obsidian')] = function () hs.application.launchOrFocus("Obsidian") end,
      [singleKey('r', 'rider')] = function () hs.application.launchOrFocus('Rider') end,
      [singleKey('m', 'mysql')] = function () hs.application.launchOrFocus('MySQLWorkbench') end,
      [singleKey('b', 'bruno')] = function () hs.application.launchOrFocus('Bruno') end,
      [singleKey('d', 'Docker')] = function () hs.application.launchOrFocus('Docker') end,
      [singleKey('s', 'Slack')] = function () hs.application.launchOrFocus('Slack') end,
      [singleKey('l', 'Linear')] = function () hs.application.launchOrFocus('Linear') end,
      [singleKey('g', 'Ghostty')] = function () hs.application.launchOrFocus('Ghostty') end
    }
  }
end

return Init
