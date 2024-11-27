-- Display Manager Module for SCI Sentinel OS
local displayManager = {}

-- Configuration
local config = {
    mirrorEnabled = false,
    debug = true -- Enable debug output
}

-- Store monitor references
local secondaryMonitor = nil

-- Debug function
local function debug(msg)
    if config.debug then
        print("[DisplayManager] " .. tostring(msg))
    end
end

-- Check for connected monitors
function displayManager.detectMonitors()
    debug("Detecting monitors...")
    for _, side in ipairs({"top", "bottom", "left", "right", "front", "back"}) do
        debug("Checking " .. side)
        if peripheral.getType(side) == "monitor" then
            debug("Found monitor on " .. side)
            secondaryMonitor = peripheral.wrap(side)
            if secondaryMonitor then
                debug("Successfully wrapped monitor")
                -- Match the main terminal's text scale
                local w, h = term.getSize()
                secondaryMonitor.setTextScale(0.5)
                while true do
                    local mw, mh = secondaryMonitor.getSize()
                    if mw >= w and mh >= h then
                        break
                    end
                    local scale = secondaryMonitor.getTextScale()
                    if scale >= 5 then
                        break
                    end
                    secondaryMonitor.setTextScale(scale + 0.5)
                end
                
                secondaryMonitor.clear()
                secondaryMonitor.setCursorPos(1,1)
                secondaryMonitor.setBackgroundColor(colors.black)
                secondaryMonitor.setTextColor(colors.white)
                debug("Monitor initialized with scale: " .. secondaryMonitor.getTextScale())
                return true
            end
        end
    end
    debug("No monitors found")
    return false
end

-- Enable display mirroring
function displayManager.enableMirroring()
    debug("Enabling mirroring")
    if displayManager.detectMonitors() then
        config.mirrorEnabled = true
        debug("Mirroring enabled")
        return true
    end
    debug("Failed to enable mirroring")
    return false
end

-- Disable display mirroring
function displayManager.disableMirroring()
    debug("Disabling mirroring")
    config.mirrorEnabled = false
    if secondaryMonitor then
        pcall(function()
            secondaryMonitor.clear()
            secondaryMonitor.setCursorPos(1,1)
            secondaryMonitor.setBackgroundColor(colors.black)
            secondaryMonitor.setTextColor(colors.white)
        end)
    end
end

-- Toggle display mirroring
function displayManager.toggleMirroring()
    debug("Toggling mirroring")
    if config.mirrorEnabled then
        displayManager.disableMirroring()
    else
        return displayManager.enableMirroring()
    end
    return config.mirrorEnabled
end

-- Mirror content to secondary display
function displayManager.mirrorContent()
    if not config.mirrorEnabled or not secondaryMonitor then
        return
    end

    local status, err = pcall(function()
        -- Get terminal size
        local width, height = term.getSize()
        
        -- Save current terminal state
        local curX, curY = term.getCursorPos()
        local curFg = term.getTextColor()
        local curBg = term.getBackgroundColor()
        
        -- Clear secondary monitor
        secondaryMonitor.clear()
        
        -- Copy terminal content
        for y = 1, height do
            for x = 1, width do
                -- Get character at position
                term.setCursorPos(x, y)
                local fg = term.getTextColor()
                local bg = term.getBackgroundColor()
                
                -- Set position and colors on secondary monitor
                secondaryMonitor.setCursorPos(x, y)
                secondaryMonitor.setTextColor(fg)
                secondaryMonitor.setBackgroundColor(bg)
                
                -- Write the character
                secondaryMonitor.write(" ")
            end
        end
        
        -- Restore cursor and colors
        term.setCursorPos(curX, curY)
        term.setTextColor(curFg)
        term.setBackgroundColor(curBg)
    end)

    if not status then
        debug("Error mirroring content: " .. tostring(err))
        displayManager.disableMirroring()
    end
end

-- Initialize display manager
function displayManager.init()
    debug("Initializing display manager")
    displayManager.detectMonitors()
end

-- Get mirroring status
function displayManager.isMirroringEnabled()
    return config.mirrorEnabled
end

return displayManager
