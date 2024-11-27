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
            return true
        end
    end
    return false
end

-- Enable display mirroring
function displayManager.enableMirroring()
    if displayManager.detectMonitors() then
        config.mirrorEnabled = true
        return true
    end
    return false
end

-- Disable display mirroring
function displayManager.disableMirroring()
    config.mirrorEnabled = false
    if secondaryMonitor then
        secondaryMonitor.clear()
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
    
    -- Get main display content
    local oldTerm = term.redirect(mainMonitor)
    local width, height = term.getSize()
    local content = {}
    
    for y = 1, height do
        content[y] = {}
        for x = 1, width do
            term.setCursorPos(x, y)
            content[y][x] = {
                text = term.getLine(y):sub(x,x),
                textColor = term.getTextColor(),
                backgroundColor = term.getBackgroundColor()
            }
        end
    end
    
    -- Restore main terminal
    term.redirect(oldTerm)
    
    -- Mirror to secondary display
    term.redirect(secondaryMonitor)
    secondaryMonitor.setTextScale(1)
    secondaryMonitor.clear()
    
    for y = 1, height do
        for x = 1, width do
            local pixel = content[y][x]
            term.setCursorPos(x, y)
            term.setTextColor(pixel.textColor)
            term.setBackgroundColor(pixel.backgroundColor)
            term.write(pixel.text)
        end
    end
    
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
