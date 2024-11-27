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

-- Debug function
local function debug(msg)
    if config.debug then
        print("[DisplayManager] " .. tostring(msg))
    end
end

-- Create a terminal object that writes to both screens
local function createDualTerminal(primary, secondary)
    return {
        write = function(text)
            debug("Writing text: " .. text)
            primary.write(text)
            if config.mirrorEnabled then
                secondary.write(text)
            end
        end,
        blit = function(text, textColors, backColors)
            debug("Blitting text: " .. text)
            primary.blit(text, textColors, backColors)
            if config.mirrorEnabled then
                secondary.blit(text, textColors, backColors)
            end
        end,
        clear = function()
            primary.clear()
            if config.mirrorEnabled then
                secondary.clear()
            end
        end,
        clearLine = function()
            primary.clearLine()
            if config.mirrorEnabled then
                secondary.clearLine()
            end
        end,
        getCursorPos = primary.getCursorPos,
        setCursorPos = function(x, y)
            primary.setCursorPos(x, y)
            if config.mirrorEnabled then
                secondary.setCursorPos(x, y)
            end
        end,
        getCursorBlink = primary.getCursorBlink,
        setCursorBlink = function(blink)
            primary.setCursorBlink(blink)
            if config.mirrorEnabled then
                secondary.setCursorBlink(blink)
            end
        end,
        getSize = primary.getSize,
        scroll = function(lines)
            primary.scroll(lines)
            if config.mirrorEnabled then
                secondary.scroll(lines)
            end
        end,
        setTextColor = function(color)
            primary.setTextColor(color)
            if config.mirrorEnabled then
                secondary.setTextColor(color)
            end
        end,
        setBackgroundColor = function(color)
            primary.setBackgroundColor(color)
            if config.mirrorEnabled then
                secondary.setBackgroundColor(color)
            end
        end,
        getTextColor = primary.getTextColor,
        getBackgroundColor = primary.getBackgroundColor,
        isColor = primary.isColor,
        setTextScale = function(scale)
            if config.mirrorEnabled and secondary.setTextScale then
                secondary.setTextScale(scale)
            end
        end
    }
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
                
                -- Create and set dual terminal
                local dualTerm = createDualTerminal(term.current(), secondaryMonitor)
                term.redirect(dualTerm)
                
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
