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
local dualTerm = nil

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
            primary.write(text)
            if config.mirrorEnabled and secondary then
                pcall(function()
                    secondary.setCursorPos(primary.getCursorPos())
                    secondary.write(text)
                end)
            end
        end,
        blit = function(text, textColors, backColors)
            primary.blit(text, textColors, backColors)
            if config.mirrorEnabled and secondary then
                pcall(function()
                    secondary.setCursorPos(primary.getCursorPos())
                    secondary.blit(text, textColors, backColors)
                end)
            end
        end,
        clear = function()
            primary.clear()
            if config.mirrorEnabled and secondary then
                pcall(function() secondary.clear() end)
            end
        end,
        clearLine = function()
            primary.clearLine()
            if config.mirrorEnabled and secondary then
                pcall(function()
                    secondary.setCursorPos(primary.getCursorPos())
                    secondary.clearLine()
                end)
            end
        end,
        getCursorPos = primary.getCursorPos,
        setCursorPos = function(x, y)
            primary.setCursorPos(x, y)
            if config.mirrorEnabled and secondary then
                pcall(function() secondary.setCursorPos(x, y) end)
            end
        end,
        getCursorBlink = primary.getCursorBlink,
        setCursorBlink = function(blink)
            primary.setCursorBlink(blink)
            if config.mirrorEnabled and secondary then
                pcall(function() secondary.setCursorBlink(blink) end)
            end
        end,
        getSize = primary.getSize,
        scroll = function(lines)
            primary.scroll(lines)
            if config.mirrorEnabled and secondary then
                pcall(function() secondary.scroll(lines) end)
            end
        end,
        setTextColor = function(color)
            primary.setTextColor(color)
            if config.mirrorEnabled and secondary then
                pcall(function() secondary.setTextColor(color) end)
            end
        end,
        setBackgroundColor = function(color)
            primary.setBackgroundColor(color)
            if config.mirrorEnabled and secondary then
                pcall(function() secondary.setBackgroundColor(color) end)
            end
        end,
        getTextColor = primary.getTextColor,
        getBackgroundColor = primary.getBackgroundColor,
        isColor = primary.isColor,
        setTextScale = function(scale)
            if config.mirrorEnabled and secondary and secondary.setTextScale then
                pcall(function() secondary.setTextScale(scale) end)
            end
        end
    }
end

-- Check for connected monitors
function displayManager.detectMonitors()
    debug("Detecting monitors...")
    for _, side in ipairs({"top", "bottom", "left", "right", "front", "back"}) do
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
                
                -- Create dual terminal
                dualTerm = createDualTerminal(term.current(), secondaryMonitor)
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
    config.mirrorEnabled = true
    if secondaryMonitor then
        secondaryMonitor.clear()
        secondaryMonitor.setCursorPos(1,1)
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
        secondaryMonitor.clear()
        secondaryMonitor.setCursorPos(1,1)
        debug("Mirroring disabled")
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
    displayManager.enableMirroring()
end

-- Get mirroring status
function displayManager.isMirroringEnabled()
    return config.mirrorEnabled
end

-- Get the dual terminal object
function displayManager.getDualTerm()
    return dualTerm or term.current()
end

return displayManager
