-- Display Manager Module for SCI Sentinel OS
local displayManager = {}

-- Configuration
local config = {
    mirrorEnabled = false
}

-- Store monitor references
local mainMonitor = term.current()
local secondaryMonitor = nil
local currentMonitor = nil

-- Check for connected monitors
function displayManager.detectMonitors()
    for _, side in ipairs({"top", "bottom", "left", "right", "front", "back"}) do
        if peripheral.getType(side) == "monitor" then
            secondaryMonitor = peripheral.wrap(side)
            if secondaryMonitor then
                -- Initialize the monitor with same size as main
                local w, h = term.getSize()
                secondaryMonitor.setTextScale(0.5)  -- Start with smallest scale
                secondaryMonitor.clear()
                secondaryMonitor.setCursorPos(1,1)
                secondaryMonitor.setBackgroundColor(colors.black)
                secondaryMonitor.setTextColor(colors.white)
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
        secondaryMonitor.setBackgroundColor(colors.black)
        secondaryMonitor.setTextColor(colors.white)
    end
end

-- Toggle display mirroring
function displayManager.toggleMirroring()
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

    -- Store current cursor position and colors
    local oldX, oldY = term.getCursorPos()
    local oldBg = term.getBackgroundColor()
    local oldFg = term.getTextColor()
    
    -- Get screen content
    local width, height = term.getSize()
    local lines = {}
    local colors = {}
    local bgColors = {}
    
    -- Capture current screen state
    for y = 1, height do
        term.setCursorPos(1, y)
        lines[y] = term.getLine()
        colors[y] = {}
        bgColors[y] = {}
        for x = 1, width do
            term.setCursorPos(x, y)
            colors[y][x] = term.getTextColor()
            bgColors[y][x] = term.getBackgroundColor()
        end
    end
    
    -- Write to secondary monitor
    secondaryMonitor.clear()
    for y = 1, height do
        for x = 1, width do
            secondaryMonitor.setCursorPos(x, y)
            secondaryMonitor.setTextColor(colors[y][x])
            secondaryMonitor.setBackgroundColor(bgColors[y][x])
            secondaryMonitor.write(lines[y]:sub(x,x))
        end
    end
    
    -- Restore original cursor position and colors
    term.setCursorPos(oldX, oldY)
    term.setBackgroundColor(oldBg)
    term.setTextColor(oldFg)
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
