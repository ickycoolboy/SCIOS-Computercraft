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
                secondaryMonitor.setTextScale(1)
                secondaryMonitor.clear()
                secondaryMonitor.setCursorPos(1,1)
                secondaryMonitor.setBackgroundColor(colors.black)
                secondaryMonitor.setTextColor(colors.white)
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
        -- Save current terminal state
        local curX, curY = term.getCursorPos()
        local curFg = term.getTextColor()
        local curBg = term.getBackgroundColor()
        
        -- Get terminal size
        local width, height = term.getSize()
        
        -- Clear secondary monitor
        secondaryMonitor.clear()
        secondaryMonitor.setCursorPos(1,1)
        
        -- Copy content line by line
        for y = 1, height do
            term.setCursorPos(1, y)
            -- Use write to capture the current line's content
            local line = ""
            for x = 1, width do
                term.setCursorPos(x, y)
                local char = term.current().write()
                if char then
                    line = line .. char
                else
                    line = line .. " "
                end
            end
            -- Write the line to secondary monitor
            secondaryMonitor.setCursorPos(1, y)
            secondaryMonitor.write(line)
        end
        
        -- Restore terminal state
        term.setCursorPos(curX, curY)
        term.setTextColor(curFg)
        term.setBackgroundColor(curBg)
    end)

    if not status then
        debug("Error mirroring content: " .. tostring(err))
        -- Disable mirroring on error
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
