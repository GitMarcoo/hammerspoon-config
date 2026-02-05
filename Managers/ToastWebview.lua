-- Toast.lua (Hammerspoon)
local Toast = {}

local currentToast = nil

local defaultConfig = {
  width    = 360,
  height   = 150,
  margin   = { x = 20, y = 40 },
  position = "topRight", -- topRight, topLeft, bottomRight, bottomLeft, center
  duration = 5,          -- seconds; 0 or nil = until dismissed
}

local function htmlEscape(str)
  if not str then return "" end
  str = tostring(str)
  str = str:gsub("&", "&amp;")
  str = str:gsub("<", "&lt;")
  str = str:gsub(">", "&gt;")
  str = str:gsub('"', "&quot;")
  return str
end

local function hideCurrent(reason, buttonId, inputText)
  if not currentToast then return end

  local t = currentToast
  currentToast = nil

  if t.timer then
    t.timer:stop()
  end

  if t.webview then
    t.webview:delete()
  end

  if t.onResult then
    t.onResult({
      reason = reason or "dismiss",
      button = buttonId,
      input  = inputText,
    })
  end
end

local function computeFrame(opts)
  local screen   = (opts and opts.screen) or hs.screen.mainScreen()
  local frame    = screen:frame()
  local width    = (opts and opts.width) or defaultConfig.width
  local height   = (opts and opts.height) or defaultConfig.height
  local margin   = (opts and opts.margin) or defaultConfig.margin
  local position = (opts and opts.position) or defaultConfig.position

  local x, y

  if position == "topLeft" then
    x = frame.x + margin.x
    y = frame.y + margin.y
  elseif position == "bottomLeft" then
    x = frame.x + margin.x
    y = frame.y + frame.h - height - margin.y
  elseif position == "bottomRight" then
    x = frame.x + frame.w - width - margin.x
    y = frame.y + frame.h - height - margin.y
  elseif position == "center" then
    x = frame.x + (frame.w - width) / 2
    y = frame.y + (frame.h - height) / 2
  else -- topRight
    x = frame.x + frame.w - width - margin.x
    y = frame.y + margin.y
  end

  return { x = x, y = y, w = width, h = height }
end

local function buildHtml(opts, hasButtons, hasInput)
  local parts = {}

  table.insert(parts, "<!doctype html><html><head><meta charset='utf-8'>")
  table.insert(parts, [[
<style>
  html, body {
    margin: 0;
    padding: 0;
    background: transparent;
    font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Text', sans-serif;
  }
  .toast-wrapper {
    width: 100%;
    height: 100%;
    box-sizing: border-box;
    padding: 4px 4px;
  }
  .toast {
    position: relative;
    width: 100%;
    height: 100%;
    background: rgba(20, 20, 26, 0.95);
    border-radius: 14px;
    color: #ffffff;
    box-sizing: border-box;
    padding: 10px 14px 12px;
    box-shadow: 0 8px 20px rgba(0,0,0,0.35);
  }
  .toast-title {
    font-size: 14px;
    font-weight: 600;
    margin-bottom: 4px;
  }
  .toast-message {
    font-size: 13px;
    color: #e6e6e6;
    margin-bottom: 8px;
    white-space: pre-wrap;
  }
  .toast-close {
    position: absolute;
    top: 6px;
    right: 8px;
    font-size: 13px;
    cursor: pointer;
    color: #ffffff;
    opacity: 0.7;
    user-select: none;
  }
  .toast-close:hover { opacity: 1.0; }

  .toast-input { margin-bottom: 8px; }
  .toast-input input {
    width: 100%;
    padding: 4px 6px;
    border-radius: 6px;
    border: none;
    outline: none;
    font-size: 13px;
    box-sizing: border-box;
    background: #222;
    color: #fff;
  }
  .toast-buttons {
    display: flex;
    gap: 6px;
    justify-content: flex-end;
  }
  .toast-buttons button {
    border-radius: 8px;
    border: none;
    padding: 4px 10px;
    font-size: 13px;
    cursor: pointer;
    background: #333333;
    color: #ffffff;
  }
  .toast-buttons button:hover { background: #4a4a4a; }
</style>
]])
  table.insert(parts, "</head><body><div class='toast-wrapper'><div class='toast'>")

  table.insert(parts, "<div class='toast-close' id='toast-close'>&times;</div>")

  if opts.title then
    table.insert(parts, "<div class='toast-title'>" .. htmlEscape(opts.title) .. "</div>")
  end

  table.insert(parts, "<div class='toast-message'>" .. htmlEscape(opts.message) .. "</div>")

  if hasInput then
    local placeholder = opts.input and opts.input.placeholder or ""
    local defaultVal  = opts.input and opts.input.default or ""
    table.insert(parts,
      "<div class='toast-input'><input id='toast-input' placeholder='" ..
      htmlEscape(placeholder) .. "' value='" .. htmlEscape(defaultVal) ..
      "'></div>"
    )
  end

  if hasButtons then
    table.insert(parts, "<div class='toast-buttons'>")
    for _, btn in ipairs(opts.buttons) do
      local id    = btn.id or ""
      local label = btn.label or btn.id or "Button"
      table.insert(parts,
        "<button data-id='" .. htmlEscape(id) .. "'>" .. htmlEscape(label) .. "</button>"
      )
    end
    table.insert(parts, "</div>")
  end

  table.insert(parts, [[
</div></div>
<script>
(function() {
  function send(msg) {
    try {
      var payload = encodeURIComponent(JSON.stringify(msg));
      window.location.href = "hammerspoon://toast?payload=" + payload;
    } catch (e) {}
  }

  var inputEl = document.getElementById('toast-input');
  var closeEl = document.getElementById('toast-close');
  var buttonsEl = document.querySelectorAll('.toast-buttons button');

  if (closeEl) {
    closeEl.addEventListener('click', function() {
      send({ type: 'dismiss' });
    });
  }

  buttonsEl.forEach(function(btn) {
    btn.addEventListener('click', function() {
      var val = inputEl ? inputEl.value : null;
      send({ type: 'button', id: btn.getAttribute('data-id') || '', value: val });
    });
  });

  if (inputEl) {
    inputEl.addEventListener('keydown', function(ev) {
      if (ev.key === 'Enter') {
        if (buttonsEl.length > 0) {
          buttonsEl[0].click();
        } else {
          send({ type: 'button', id: '', value: inputEl.value });
        }
      }
    });
    inputEl.focus();
    inputEl.select();
  }
})();
</script>
</body></html>
]])
  return table.concat(parts)
end

-- Bind once (don’t rebind on every show)
local _bound = false
local function ensureBound()
  if _bound then return end
  _bound = true

  hs.urlevent.bind("toast", function(eventName, params)
    local payload = params and params.payload
    if not payload then return end

    local decodedStr = hs.http.urlDecode(payload)
    local ok, body = pcall(function()
      return hs.json.decode(decodedStr)
    end)
    if not ok or type(body) ~= "table" then return end

    if body.type == "button" then
      hideCurrent("button", body.id, body.value)
    elseif body.type == "dismiss" then
      hideCurrent("dismiss", nil, body.value)
    end
  end)
end

--- Toast.show(opts)
function Toast.show(opts)
  if not opts or not opts.message then return end
  ensureBound()

  if currentToast then
    hideCurrent("dismiss")
  end

  local buttons    = opts.buttons or {}
  local hasButtons = #buttons > 0
  local hasInput   = opts.input ~= nil

  local baseHeight = 90
  if opts.title then baseHeight = baseHeight + 16 end
  if hasInput then baseHeight = baseHeight + 28 end
  if hasButtons then baseHeight = baseHeight + 32 end

  local frame = computeFrame({
    screen   = opts.screen,
    width    = opts.width or defaultConfig.width,
    height   = opts.height or baseHeight,
    margin   = opts.margin,
    position = opts.position,
  })

  local wv = hs.webview.new(frame, {
    developerExtrasEnabled = false,
    suppressesIncrementalRendering = false,
  })

  -- borderless if supported (safe)
  pcall(function() wv:windowStyle("borderless") end)

  wv:allowTextEntry(true)
  wv:html(buildHtml(opts, hasButtons, hasInput))
  wv:show()

  local timer
  local duration = opts.duration
  if duration and duration > 0 then
    timer = hs.timer.doAfter(duration, function()
      hideCurrent("timeout", nil, nil)
    end)
  end

  currentToast = {
    webview  = wv,
    timer    = timer,
    onResult = opts.onResult,
  }

  return {
    hide = function(reason)
      hideCurrent(reason or "dismiss")
    end
  }
end

return Toast