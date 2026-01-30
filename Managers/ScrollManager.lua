local ScrollActions = require("Managers.ScrollActions")

function Init(singleKey)
  return {
    [singleKey('s', 'scroll')] = function() ScrollActions.enterScrollMode() end,
  }
end

return Init
