-- SCI Sentinel GUI Module
local version = "1.34"

-- Initialize error handling and theme
local ErrorHandler = require("ErrorHandler")
local theme

-- Improved theme initialization with error handling
local function getTheme()
    if theme then return theme end
    
    local success, loadedTheme = ErrorHandler.protectedCall("get_theme", function()
        local t = require("Theme")
        if not t then
            error("Failed to load Theme module")
        end
        -- Initialize theme if needed
        if type(t.init) == "function" and not t.isInitialized() then
            local initSuccess = t.init()
            if not initSuccess then
                error("Theme initialization failed")
            end
        end
        return t
    end)
    
    if not success or type(loadedTheme) ~= "table" then
        error("Critical: Theme initialization failed: " .. tostring(loadedTheme))
    end
    
    theme = loadedTheme
    return theme
end

local gui = {}
local background = {}

-- Safe terminal operations with better error handling
local function safeSetCursor(x, y)
    return ErrorHandler.protectedCall("set_cursor", function()
        if not term.setCursorPos(x, y) then
            error("Failed to set cursor position")
        end
        return true
    end)
end

local function safeWrite(text)
    return ErrorHandler.protectedCall("write_text", function()
        if not write(text) then
            error("Failed to write text")
        end
        return true
    end)
end

local function safePrint(text)
    return ErrorHandler.protectedCall("print_text", function()
        if not print(text) then
            error("Failed to print text")
        end
        return true
    end)
end

-- GUI Functions with improved error handling
function gui.setBackground(bg)
    return ErrorHandler.protectedCall("set_background", function()
        background = bg
        return true
    end)
end

function gui.getBackground()
    return ErrorHandler.protectedCall("get_background", function()
        return background
    end)
end

function gui.getScreenDimensions()
    return ErrorHandler.protectedCall("get_dimensions", function()
        return getTheme().getScreenDimensions()
    end)
end

function gui.drawScreen()
    return ErrorHandler.protectedCall("draw_screen", function()
        local th = getTheme()
        if not th then
            error("Failed to load theme module")
        end
        
        local bg = th.getColor("background")
        if not bg then
            error("Failed to get background color from theme")
        end
        
        term.setBackgroundColor(bg)
        term.clear()
        
        -- Only draw title bar if not in login screen
        if not th.isLoginScreen then
            local success = th.drawPersistentTitleBar("SCI Sentinel OS")
            if not success then
                error("Failed to draw title bar")
            end
        end
        
        return true
    end)
end

function gui.clear()
    return ErrorHandler.protectedCall("clear_screen", function()
        local th = getTheme()
        if not th then
            error("Failed to load theme module")
        end
        
        local bg = th.getColor("background")
        if not bg then
            error("Failed to get background color from theme")
        end
        
        term.setBackgroundColor(bg)
        term.clear()
        
        -- Only draw title bar if not in login screen
        if not th.isLoginScreen then
            local success = th.drawPersistentTitleBar("SCI Sentinel OS")
            if not success then
                error("Failed to draw title bar")
            end
        end
        
        return true
    end)
end

function gui.getContentWindow()
    return ErrorHandler.protectedCall("get_content_window", function()
        return getTheme().getContentWindow()
    end)
end

function gui.redirect()
    return ErrorHandler.protectedCall("redirect", function()
        return getTheme().redirect()
    end)
end

function gui.printPrompt()
    return ErrorHandler.protectedCall("print_prompt", function()
        term.setTextColor(getTheme().getColor("text"))
        term.write("> ")
        return true
    end)
end

function gui.drawSuccess(message)
    return ErrorHandler.protectedCall("draw_success", function()
        term.setTextColor(getTheme().getColor("successText"))
        safePrint(message)
        term.setTextColor(getTheme().getColor("text"))
        return true
    end)
end

function gui.drawError(message)
    return ErrorHandler.protectedCall("draw_error", function()
        term.setTextColor(getTheme().getColor("errorText"))
        safePrint("Error: " .. message)
        term.setTextColor(getTheme().getColor("text"))
        return true
    end)
end

function gui.drawWarning(message)
    return ErrorHandler.protectedCall("draw_warning", function()
        term.setTextColor(getTheme().getColor("warningText"))
        safePrint("Warning: " .. message)
        term.setTextColor(getTheme().getColor("text"))
        return true
    end)
end

function gui.drawInfo(message)
    return ErrorHandler.protectedCall("draw_info", function()
        term.setTextColor(getTheme().getColor("infoText"))
        safePrint(message)
        term.setTextColor(getTheme().getColor("text"))
        return true
    end)
end

function gui.confirm(message)
    return ErrorHandler.protectedCall("confirm", function()
        term.setTextColor(getTheme().getColor("confirmText"))
        safePrint(message .. " (y/n)")
        local input = read():lower()
        term.setTextColor(getTheme().getColor("text"))
        return input == "y" or input == "yes"
    end)
end

function gui.drawProgressBar(x, y, width, text, progress, showPercent)
    return ErrorHandler.protectedCall("draw_progress", function()
        -- Validate inputs
        if type(progress) ~= "number" or progress < 0 or progress > 1 then
            error("Invalid progress value: " .. tostring(progress))
        end
        
        safeSetCursor(x, y)
        term.setTextColor(getTheme().getColor("text"))
        safeWrite(text .. " [")
        term.setTextColor(getTheme().getColor("progressBar"))
        
        local barWidth = width - #text - 3
        if showPercent then
            barWidth = barWidth - 5
        end
        
        local filled = math.floor(barWidth * progress)
        safeWrite(string.rep("=", filled))
        term.setTextColor(getTheme().getColor("progressBg"))
        safeWrite(string.rep("-", barWidth - filled))
        term.setTextColor(getTheme().getColor("text"))
        safeWrite("]")
        
        if showPercent then
            local percent = math.floor(progress * 100)
            safeWrite(string.format(" %3d%%", percent))
        end
        
        return true
    end)
end

function gui.updateProgress(x, y, width, text, progress, status)
    return ErrorHandler.protectedCall("update_progress", function()
        gui.drawProgressBar(x, y, width, text, progress, true)
        
        if status then
            safeSetCursor(x, y + 1)
            term.setTextColor(getTheme().getColor("text"))
            safeWrite(status)
            
            local remaining = width - #status
            if remaining > 0 then
                safeWrite(string.rep(" ", remaining))
            end
        end
        
        return true
    end)
end

function gui.messageBox(title, message)
    return ErrorHandler.protectedCall("message_box", function()
        local oldBg = term.getBackgroundColor()
        local oldFg = term.getTextColor()
        local screen = gui.getScreenDimensions()
        
        -- Calculate box dimensions
        local boxWidth = math.min(screen.width - 4, math.max(#title, #message) + 6)
        local startX = math.floor((screen.width - boxWidth) / 2)
        local startY = math.floor((screen.height - 7) / 2)
        
        -- Draw box
        term.setBackgroundColor(getTheme().getColor("messageBoxBg"))
        term.clear()
        
        -- Draw borders and content
        for y = startY, startY + 6 do
            safeSetCursor(startX, y)
            if y == startY or y == startY + 6 then
                safeWrite(string.rep("-", boxWidth))
            elseif y == startY + 2 then
                safeWrite("|" .. string.rep("-", boxWidth - 2) .. "|")
            else
                safeWrite("|" .. string.rep(" ", boxWidth - 2) .. "|")
            end
        end
        
        -- Draw title
        safeSetCursor(startX + math.floor((boxWidth - #title) / 2), startY + 1)
        safeWrite(title)
        
        -- Draw message
        safeSetCursor(startX + 2, startY + 4)
        safeWrite(message)
        
        -- Wait for key press
        os.pullEvent("key")
        
        -- Restore colors
        term.setBackgroundColor(oldBg)
        term.setTextColor(oldFg)
        term.clear()
        
        return true
    end)
end

function gui.handleMouseEvents(buttons)
    return ErrorHandler.protectedCall("handle_mouse", function()
        -- Get initial click
        local event, button, x, y = os.pullEvent("mouse_click")
        
        -- Find clicked button
        for _, btn in ipairs(buttons) do
            if x >= btn.x and x < btn.x + #btn.text and
               y == btn.y then
                -- Handle button action
                if type(btn.action) == "function" then
                    return btn.action()
                end
                return btn.action
            end
        end
        
        return nil
    end)
end

function gui.drawHeader(x, y, text, color)
    return ErrorHandler.protectedCall("draw_header", function()
        safeSetCursor(x, y)
        term.setTextColor(color or getTheme().getColor("headerText"))
        safeWrite("[ " .. text .. " ]")
        term.setTextColor(getTheme().getColor("text"))
        return true
    end)
end

function gui.centerText(text, width)
    local padding = width - #text
    local leftPad = math.floor(padding / 2)
    local rightPad = padding - leftPad
    return string.rep(" ", leftPad) .. text .. string.rep(" ", rightPad)
end

function gui.drawBox(x, y, width, height, title)
    local screen = gui.getScreenDimensions()
    
    -- Adjust dimensions if they exceed screen size
    width = math.min(width, screen.width - x + 1)
    height = math.min(height, screen.height - y + 1)
    
    -- Draw top border
    safeSetCursor(x, y)
    term.setBackgroundColor(getTheme().getColor("boxBg"))
    safeWrite("+" .. string.rep("-", width-2) .. "+")
    
    -- Draw title if provided
    if title then
        safeSetCursor(x + 2, y)
        term.setTextColor(getTheme().getColor("boxTitle"))
        safeWrite(" " .. title .. " ")
    end
    
    -- Draw sides
    for i = 1, height-2 do
        safeSetCursor(x, y + i)
        safeWrite("|")
        safeSetCursor(x + width-1, y + i)
        safeWrite("|")
        -- Fill background
        safeSetCursor(x + 1, y + i)
        term.setBackgroundColor(getTheme().getColor("boxBg"))
        safeWrite(string.rep(" ", width-2))
    end
    
    -- Draw bottom border
    safeSetCursor(x, y + height-1)
    term.setBackgroundColor(getTheme().getColor("boxBg"))
    safeWrite("+" .. string.rep("-", width-2) .. "+")
    
    -- Return the content area dimensions for convenience
    return {
        contentX = x + 1,
        contentY = y + 1,
        contentWidth = width - 2,
        contentHeight = height - 2
    }
end

function gui.drawClickableButton(x, y, text, buttonColor)
    local width = #text + 4
    safeSetCursor(x, y)
    term.setBackgroundColor(buttonColor)
    safeWrite(string.rep(" ", width))
    safeSetCursor(x + 2, y)
    term.setTextColor(getTheme().getColor("buttonText"))
    safeWrite(text)
    term.setBackgroundColor(getTheme().getColor("background"))
    term.setTextColor(getTheme().getColor("text"))
    
    -- Return button information
    return {
        text = text,
        x1 = x,
        y1 = y,
        x2 = x + width - 1,
        y2 = y,
        width = width,
        color = buttonColor
    }
end

function gui.drawFancyProgressBar(x, y, width, text, progress)
    local barWidth = width - #text - 3
    local filled = math.floor(barWidth * progress)
    
    safeSetCursor(x, y)
    term.setTextColor(getTheme().getColor("text"))
    safeWrite(text .. " [")
    term.setTextColor(getTheme().getColor("progressBar"))
    safeWrite(string.rep("=", filled))
    term.setTextColor(getTheme().getColor("progressBg"))
    safeWrite(string.rep("-", barWidth - filled))
    term.setTextColor(getTheme().getColor("text"))
    safeWrite("]")
end

function gui.drawAnimatedProgressBar(x, y, width, text, startProgress, endProgress, duration)
    local startTime = os.epoch("utc")
    local currentProgress = startProgress
    
    while currentProgress < endProgress do
        -- Calculate progress based on time
        local elapsed = (os.epoch("utc") - startTime) / 1000.0 -- Convert to seconds
        currentProgress = startProgress + (endProgress - startProgress) * (elapsed / duration)
        if currentProgress > endProgress then
            currentProgress = endProgress
        end
        
        -- Draw the progress bar
        safeSetCursor(x, y)
        term.setTextColor(getTheme().getColor("text"))
        safeWrite(text .. " [")
        term.setTextColor(getTheme().getColor("progressBar"))
        
        local barWidth = width - #text - 3
        local filled = math.floor(barWidth * currentProgress)
        safeWrite(string.rep("=", filled))
        term.setTextColor(getTheme().getColor("progressBg"))
        safeWrite(string.rep("-", barWidth - filled))
        term.setTextColor(getTheme().getColor("text"))
        safeWrite("]")
        
        -- Add percentage display
        local percent = math.floor(currentProgress * 100)
        safeSetCursor(x + width + 1, y)
        safeWrite(string.format(" %3d%%", percent))
        
        -- Small delay for animation
        os.sleep(0.05)
    end
end

function gui.drawFancyBox(x, y, width, height, title, bgColor, fgColor)
    bgColor = bgColor or getTheme().getColor("background")
    fgColor = fgColor or getTheme().getColor("text")
    
    -- Save current colors
    local oldBg = term.getBackgroundColor()
    local oldFg = term.getTextColor()
    
    -- Set colors
    term.setBackgroundColor(bgColor)
    term.setTextColor(fgColor)
    
    -- Draw top border with title
    safeSetCursor(x, y)
    safeWrite("╔" .. string.rep("═", width-2) .. "╗")
    if title then
        safeSetCursor(x + math.floor((width - #title) / 2) - 1, y)
        term.setTextColor(getTheme().getColor("titleText"))
        safeWrite(" " .. title .. " ")
        term.setTextColor(fgColor)
    end
    
    -- Draw sides
    for i = 1, height-2 do
        safeSetCursor(x, y + i)
        safeWrite("║")
        safeSetCursor(x + width-1, y + i)
        safeWrite("║")
        -- Fill background
        safeSetCursor(x + 1, y + i)
        term.setBackgroundColor(bgColor)
        safeWrite(string.rep(" ", width-2))
    end
    
    -- Draw bottom border
    safeSetCursor(x, y + height-1)
    safeWrite("╚" .. string.rep("═", width-2) .. "╝")
    
    -- Restore colors
    term.setBackgroundColor(oldBg)
    term.setTextColor(oldFg)
end

function gui.drawWindow(x, y, width, height, title)
    -- Background
    local oldBg = term.getBackgroundColor()
    local oldFg = term.getTextColor()
    
    -- Draw shadow
    term.setBackgroundColor(getTheme().getColor("shadow"))
    for i = 1, height do
        safeSetCursor(x + width, y + i)
        safeWrite(" ")
    end
    for i = 1, width do
        safeSetCursor(x + i, y + height)
        safeWrite(" ")
    end
    
    -- Draw main window
    term.setBackgroundColor(getTheme().getColor("windowBg"))
    for i = 1, height-1 do
        safeSetCursor(x, y + i - 1)
        safeWrite(string.rep(" ", width-1))
    end
    
    -- Draw title bar
    term.setBackgroundColor(getTheme().getColor("titleBar"))
    safeSetCursor(x, y)
    safeWrite(string.rep(" ", width-1))
    
    -- Draw title
    safeSetCursor(x + 1, y)
    term.setTextColor(getTheme().getColor("titleText"))
    safeWrite(" " .. title .. " ")
    
    -- Reset colors
    term.setBackgroundColor(oldBg)
    term.setTextColor(oldFg)
end

gui.colors = {
    background = getTheme().getColor("background"),
    windowBg = getTheme().getColor("windowBg"),
    text = getTheme().getColor("text"),
    border = getTheme().getColor("border"),
    shadow = getTheme().getColor("shadow"),
    buttonBg = getTheme().getColor("buttonBg"),
    buttonText = getTheme().getColor("buttonText"),
    titleBar = getTheme().getColor("titleBar"),
    titleText = getTheme().getColor("titleText"),
    progressBar = getTheme().getColor("progressBar"),
    progressBg = getTheme().getColor("progressBg")
}

-- Return the gui module
return gui
