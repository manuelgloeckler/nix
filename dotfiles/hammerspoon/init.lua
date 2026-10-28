-- Keyboard focus across displays; Hyper = Caps Lock held (Karabiner).
-- Hyper+Tab cycles like Cmd+Tab; Hyper+H/L is already Raycast window management.
local hyper = { "ctrl", "alt", "cmd" }

local function focus_next_display()
  local current = hs.mouse.getCurrentScreen()
  local focused = hs.window.focusedWindow()
  if focused then
    current = focused:screen()
  end
  local target = current:next()

  -- orderedWindows is front-to-back, so the first match is the topmost one.
  for _, window in ipairs(hs.window.orderedWindows()) do
    if window:screen() == target and window:isStandard() then
      window:focus()
      break
    end
  end
  -- Follow with the pointer so clicks and scrolling land on the new display.
  hs.mouse.absolutePosition(hs.geometry.rectMidPoint(target:frame()))
end

hs.hotkey.bind(hyper, "tab", focus_next_display)
