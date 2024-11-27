-- Display Manager Module for SCI Sentinel OS
local displayManager = {}

-- Configuration
local config = {
    mirrorEnabled = false,
    debug = true -- Enable debug output
}

-- Store monitor references
local secondaryMonitor = nil
local originalTerm = term.current()
local redirectedTerm = nil

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
                secondaryMonitor.setTextScale(0.5)
                secondaryMonitor.clear()
                secondaryMonitor.setCursorPos(1,1)
                secondaryMonitor.setBackgroundColor(colors.black)
                secondaryMonitor.setTextColor(colors.white)
                
                -- Create redirected terminal
                redirectedTerm = term.redirect(secondaryMonitor)
                term.redirect(originalTerm)
                
                debug("Monitor initialized")
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
        -- Set up terminal redirection
        if secondaryMonitor then
            redirectedTerm = term.redirect(secondaryMonitor)
            term.redirect(originalTerm)
        end
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
        -- Save current terminal
        local currentTerm = term.current()
        
        -- Redirect to secondary monitor
        term.redirect(secondaryMonitor)
        
        -- Copy from original terminal
        local width, height = originalTerm.getSize()
        
        -- Clear the monitor
        term.clear()
        term.setCursorPos(1,1)
        
        -- Copy content from original terminal
        for y = 1, height do
            term.setCursorPos(1, y)
            local line = originalTerm.getLine(y)
            if line then
                term.write(line)
            end
        end
        
        -- Restore original terminal
        term.redirect(currentTerm)
    end)

    if not status then
        debug("Error mirroring content: " .. tostring(err))
        displayManager.disableMirroring()
    end
end

-- Initialize display manager
function displayManager.init()
    debug("Initializing display manager")
    originalTerm = term.current() -- Store original terminal
    displayManager.detectMonitors()
end

-- Get mirroring status
function displayManager.isMirroringEnabled()
    return config.mirrorEnabled
end

return displayManager
