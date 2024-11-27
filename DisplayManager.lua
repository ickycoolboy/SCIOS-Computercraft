-- Display Manager Module for SCI Sentinel OS
local displayManager = {}

-- Configuration
local config = {
    mirrorEnabled = false
}

-- Store monitor references
local mainMonitor = term.current()
local secondaryMonitor = nil

-- Check for connected monitors
function displayManager.detectMonitors()
    for _, side in ipairs({"top", "bottom", "left", "right", "front", "back"}) do
        if peripheral.getType(side) == "monitor" then
            secondaryMonitor = peripheral.wrap(side)
            -- Initialize the monitor
            if secondaryMonitor then
                secondaryMonitor.setTextScale(1)
                secondaryMonitor.clear()
                secondaryMonitor.setCursorPos(1,1)
                return true
            end
        end
    end
    return false
end

-- Enable display mirroring
function displayManager.enableMirroring()
    if displayManager.detectMonitors() then
        config.mirrorEnabled = true
        -- Initial mirror
        displayManager.mirrorContent()
        return true
    end
    return false
end

-- Disable display mirroring
function displayManager.disableMirroring()
    config.mirrorEnabled = false
    if secondaryMonitor then
        secondaryMonitor.clear()
        secondaryMonitor.setCursorPos(1,1)
    end
end

-- Toggle display mirroring
function displayManager.toggleMirroring()
    if config.mirrorEnabled then
        displayManager.disableMirroring()
    else
        displayManager.enableMirroring()
    end
    return config.mirrorEnabled
end

-- Mirror content to secondary display
function displayManager.mirrorContent()
    if not config.mirrorEnabled or not secondaryMonitor then
        return
    end
    
    -- Save current terminal state
    local oldTerm = term.current()
    
    -- Get main display content
    local width, height = term.getSize()
    local content = {}
    
    -- Capture the current screen content
    for y = 1, height do
        content[y] = {}
        for x = 1, width do
            local char = {}
            term.setCursorPos(x, y)
            char.text = term.getLine(y):sub(x,x)
            char.textColor = term.getTextColor()
            char.backgroundColor = term.getBackgroundColor()
            content[y][x] = char
        end
    end
    
    -- Switch to secondary monitor and mirror content
    term.redirect(secondaryMonitor)
    secondaryMonitor.setTextScale(1)
    
    -- Copy content to secondary monitor
    for y = 1, height do
        for x = 1, width do
            local char = content[y][x]
            secondaryMonitor.setCursorPos(x, y)
            secondaryMonitor.setTextColor(char.textColor)
            secondaryMonitor.setBackgroundColor(char.backgroundColor)
            secondaryMonitor.write(char.text)
        end
    end
    
    -- Restore original terminal
    term.redirect(oldTerm)
end

-- Initialize display manager
function displayManager.init()
    displayManager.detectMonitors()
end

-- Get mirroring status
function displayManager.isMirroringEnabled()
    return config.mirrorEnabled
end

return displayManager
