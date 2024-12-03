-- SCI Sentinel GUI Module
local version = "1.34"
local theme = require("Theme")

local gui = {}
local background = {}

function gui.setBackground(bg)
    background = bg
end

function gui.getBackground()
    return background
end

-- Screen size utilities
function gui.getScreenDimensions()
    return theme.getScreenDimensions()
end

function gui.drawScreen()
    -- This will draw the interface and return the content window
    return theme.drawInterface()
end

function gui.clear()
    theme.clear()
end

-- Get the content window for drawing operations
function gui.getContentWindow()
    return theme.getContentWindow()
end

-- Redirect terminal to content window
function gui.redirect()
    return theme.redirect()
end

-- Print prompt
function gui.printPrompt()
    -- Show current directory in prompt
    local currentDir = shell.dir()
    if currentDir == "" then currentDir = "/" end
    term.setTextColor(theme.getColor("promptText"))
    write(currentDir)
    term.setTextColor(theme.getColor("promptSymbol"))
    write("> ")
    term.setTextColor(theme.getColor("text"))
end

function gui.drawSuccess(message)
    term.setTextColor(theme.getColor("successText"))
    print(message)
    term.setTextColor(theme.getColor("text"))
end

function gui.drawError(message)
    term.setTextColor(theme.getColor("errorText"))
    print("Error: " .. message)
    term.setTextColor(theme.getColor("text"))
end

function gui.drawWarning(message)
    term.setTextColor(theme.getColor("warningText"))
    print("Warning: " .. message)
    term.setTextColor(theme.getColor("text"))
end

function gui.drawInfo(message)
    term.setTextColor(theme.getColor("infoText"))
    print(message)
    term.setTextColor(theme.getColor("text"))
end

function gui.confirm(message)
    term.setTextColor(theme.getColor("confirmText"))
    print(message .. " (y/n)")
    local input = read():lower()
    term.setTextColor(theme.getColor("text"))
    return input == "y" or input == "yes"
end

-- Progress bar functionality
function gui.drawProgressBar(current, total, width)
    width = width or 20
    local progress = math.floor((current / total) * width)
    local bar = string.rep("=", progress) .. string.rep("-", width - progress)
    print(string.format("[%s] %d%%", bar, (current / total) * 100))
end

-- Draw a continuous progress bar
function gui.drawProgressBar(x, y, width, text, progress, showPercent)
    -- Draw the progress bar
    term.setCursorPos(x, y)
    term.setTextColor(theme.getColor("text"))
    write(text .. " [")
    term.setTextColor(theme.getColor("progressBar"))
    
    local barWidth = width - #text - 3
    if showPercent then
        barWidth = barWidth - 5  -- Account for percentage display
    end
    local filled = math.floor(barWidth * progress)
    write(string.rep("=", filled))
    term.setTextColor(theme.getColor("progressBg"))
    write(string.rep("-", barWidth - filled))
    term.setTextColor(theme.getColor("text"))
    write("]")
    
    -- Add percentage display if requested
    if showPercent then
        local percent = math.floor(progress * 100)
        write(string.format(" %3d%%", percent))
    end
end

-- Update progress with status message
function gui.updateProgress(x, y, width, text, progress, status)
    gui.drawProgressBar(x, y, width, text, progress, true)
    if status then
        term.setCursorPos(x, y + 1)
        term.setTextColor(theme.getColor("text"))
        write(status)
        -- Clear the rest of the line
        local remaining = width - #status
        if remaining > 0 then
            write(string.rep(" ", remaining))
        end
    end
end

-- Message box
function gui.messageBox(title, message)
    local oldBg = term.getBackgroundColor()
    local oldFg = term.getTextColor()
    local screen = gui.getScreenDimensions()
    
    -- Calculate box dimensions based on screen size
    local boxWidth = math.min(screen.width - 4, math.max(#title, #message) + 6)
    local startX = math.floor((screen.width - boxWidth) / 2)
    local startY = math.floor((screen.height - 7) / 2)
    
    -- Draw box
    term.setBackgroundColor(theme.getColor("messageBoxBg"))
    term.clear()
    
    -- Draw borders and content
    for y = startY, startY + 6 do
        term.setCursorPos(startX, y)
        if y == startY or y == startY + 6 then
            write("+" .. string.rep("-", boxWidth-2) .. "+")
        elseif y == startY + 1 then
            write("|" .. gui.centerText(title, boxWidth-2) .. "|")
        elseif y == startY + 2 then
            write("|" .. string.rep("-", boxWidth-2) .. "|")
        elseif y == startY + 3 then
            write("|" .. gui.centerText(message, boxWidth-2) .. "|")
        elseif y == startY + 4 then
            write("|" .. string.rep("-", boxWidth-2) .. "|")
        else
            write("|" .. gui.centerText("Press any key", boxWidth-2) .. "|")
        end
    end
    
    -- Wait for keypress
    os.pullEvent("key")
    
    -- Restore colors and screen
    term.setBackgroundColor(oldBg)
    term.setTextColor(oldFg)
    gui.drawScreen()
end

-- Utility function for centering text
function gui.centerText(text, width)
    local padding = width - #text
    local leftPad = math.floor(padding / 2)
    local rightPad = padding - leftPad
    return string.rep(" ", leftPad) .. text .. string.rep(" ", rightPad)
end

-- Draw a box with borders
function gui.drawBox(x, y, width, height, title)
    local screen = gui.getScreenDimensions()
    
    -- Adjust dimensions if they exceed screen size
    width = math.min(width, screen.width - x + 1)
    height = math.min(height, screen.height - y + 1)
    
    -- Draw top border
    term.setCursorPos(x, y)
    term.setBackgroundColor(theme.getColor("boxBg"))
    write("+" .. string.rep("-", width-2) .. "+")
    
    -- Draw title if provided
    if title then
        term.setCursorPos(x + 2, y)
        term.setTextColor(theme.getColor("boxTitle"))
        write(" " .. title .. " ")
    end
    
    -- Draw sides
    for i = 1, height-2 do
        term.setCursorPos(x, y + i)
        write("|")
        term.setCursorPos(x + width-1, y + i)
        write("|")
        -- Fill background
        term.setCursorPos(x + 1, y + i)
        term.setBackgroundColor(theme.getColor("boxBg"))
        write(string.rep(" ", width-2))
    end
    
    -- Draw bottom border
    term.setCursorPos(x, y + height-1)
    term.setBackgroundColor(theme.getColor("boxBg"))
    write("+" .. string.rep("-", width-2) .. "+")
    
    -- Return the content area dimensions for convenience
    return {
        contentX = x + 1,
        contentY = y + 1,
        contentWidth = width - 2,
        contentHeight = height - 2
    }
end

-- Windows 9x style colors
gui.colors = {
    background = theme.getColor("background"),
    windowBg = theme.getColor("windowBg"),
    text = theme.getColor("text"),
    border = theme.getColor("border"),
    shadow = theme.getColor("shadow"),
    buttonBg = theme.getColor("buttonBg"),
    buttonText = theme.getColor("buttonText"),
    titleBar = theme.getColor("titleBar"),
    titleText = theme.getColor("titleText"),
    progressBar = theme.getColor("progressBar"),
    progressBg = theme.getColor("progressBg")
}

-- Draw a clickable button and return its bounds
function gui.drawClickableButton(x, y, text, buttonColor)
    local width = #text + 4
    term.setCursorPos(x, y)
    term.setBackgroundColor(buttonColor)
    write(string.rep(" ", width))
    term.setCursorPos(x + 2, y)
    term.setTextColor(theme.getColor("buttonText"))
    write(text)
    term.setBackgroundColor(theme.getColor("background"))
    term.setTextColor(theme.getColor("text"))
    
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

-- Handle mouse events for buttons
function gui.handleMouseEvents(buttons)
    -- Get initial click
    local event, button, x, y = os.pullEvent("mouse_click")
    
    -- Find clicked button
    for _, btn in ipairs(buttons) do
        if x >= btn.x1 and x <= btn.x2 and y == btn.y1 then
            -- Flash button
            local oldBg = term.getBackgroundColor()
            term.setCursorPos(btn.x1, btn.y1)
            term.setBackgroundColor(theme.getColor("buttonFlash"))
            term.setTextColor(btn.color)
            write(string.rep(" ", btn.width))
            term.setCursorPos(btn.x1 + 2, btn.y1)
            write(btn.text)
            
            -- Small delay
            os.sleep(0.05)
            
            -- Restore button
            term.setCursorPos(btn.x1, btn.y1)
            term.setBackgroundColor(btn.color)
            term.setTextColor(theme.getColor("buttonText"))
            write(string.rep(" ", btn.width))
            term.setCursorPos(btn.x1 + 2, btn.y1)
            write(btn.text)
            
            -- Reset colors
            term.setBackgroundColor(oldBg)
            term.setTextColor(theme.getColor("text"))
            
            return btn.text
        end
    end
    
    return nil
end

-- Progress bar functionality
function gui.drawFancyProgressBar(x, y, width, text, progress)
    local barWidth = width - #text - 3
    local filled = math.floor(barWidth * progress)
    
    term.setCursorPos(x, y)
    term.setTextColor(theme.getColor("text"))
    write(text .. " [")
    term.setTextColor(theme.getColor("progressBar"))
    write(string.rep("=", filled))
    term.setTextColor(theme.getColor("progressBg"))
    write(string.rep("-", barWidth - filled))
    term.setTextColor(theme.getColor("text"))
    write("]")
end

-- Draw a centered text line
function gui.drawCenteredText(y, text, textColor)
    local w, _ = term.getSize()
    local x = math.floor((w - #text) / 2) + 1
    term.setCursorPos(x, y)
    if textColor then
        term.setTextColor(textColor)
    else
        term.setTextColor(theme.getColor("text"))
    end
    write(text)
    term.setTextColor(theme.getColor("text"))
end

-- Draw an animated progress bar
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
        term.setCursorPos(x, y)
        term.setTextColor(theme.getColor("text"))
        write(text .. " [")
        term.setTextColor(theme.getColor("progressBar"))
        
        local barWidth = width - #text - 3
        local filled = math.floor(barWidth * currentProgress)
        write(string.rep("=", filled))
        term.setTextColor(theme.getColor("progressBg"))
        write(string.rep("-", barWidth - filled))
        term.setTextColor(theme.getColor("text"))
        write("]")
        
        -- Add percentage display
        local percent = math.floor(currentProgress * 100)
        term.setCursorPos(x + width + 1, y)
        write(string.format(" %3d%%", percent))
        
        -- Small delay for animation
        os.sleep(0.05)
    end
end

-- Draw a fancy border box with title
function gui.drawFancyBox(x, y, width, height, title, bgColor, fgColor)
    bgColor = bgColor or theme.getColor("background")
    fgColor = fgColor or theme.getColor("text")
    
    -- Save current colors
    local oldBg = term.getBackgroundColor()
    local oldFg = term.getTextColor()
    
    -- Set colors
    term.setBackgroundColor(bgColor)
    term.setTextColor(fgColor)
    
    -- Draw top border with title
    term.setCursorPos(x, y)
    write("╔" .. string.rep("═", width-2) .. "╗")
    if title then
        term.setCursorPos(x + math.floor((width - #title) / 2) - 1, y)
        term.setTextColor(theme.getColor("titleText"))
        write(" " .. title .. " ")
        term.setTextColor(fgColor)
    end
    
    -- Draw sides
    for i = 1, height-2 do
        term.setCursorPos(x, y + i)
        write("║")
        term.setCursorPos(x + width-1, y + i)
        write("║")
        -- Fill background
        term.setCursorPos(x + 1, y + i)
        term.setBackgroundColor(bgColor)
        write(string.rep(" ", width-2))
    end
    
    -- Draw bottom border
    term.setCursorPos(x, y + height-1)
    write("╚" .. string.rep("═", width-2) .. "╝")
    
    -- Restore colors
    term.setBackgroundColor(oldBg)
    term.setTextColor(oldFg)
end

-- Draw a section header
function gui.drawHeader(x, y, text, color)
    term.setCursorPos(x, y)
    term.setTextColor(color or theme.getColor("headerText"))
    write("[ " .. text .. " ]")
    term.setTextColor(theme.getColor("text"))
end

-- Draw a Windows 9x style window
function gui.drawWindow(x, y, width, height, title)
    -- Background
    local oldBg = term.getBackgroundColor()
    local oldFg = term.getTextColor()
    
    -- Draw shadow
    term.setBackgroundColor(theme.getColor("shadow"))
    for i = 1, height do
        term.setCursorPos(x + width, y + i)
        write(" ")
    end
    for i = 1, width do
        term.setCursorPos(x + i, y + height)
        write(" ")
    end
    
    -- Draw main window
    term.setBackgroundColor(theme.getColor("windowBg"))
    for i = 1, height-1 do
        term.setCursorPos(x, y + i - 1)
        write(string.rep(" ", width-1))
    end
    
    -- Draw title bar
    term.setBackgroundColor(theme.getColor("titleBar"))
    term.setCursorPos(x, y)
    write(string.rep(" ", width-1))
    
    -- Draw title
    term.setCursorPos(x + 1, y)
    term.setTextColor(theme.getColor("titleText"))
    write(" " .. title .. " ")
    
    -- Reset colors
    term.setBackgroundColor(oldBg)
    term.setTextColor(oldFg)
end

return gui
