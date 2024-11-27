-- SCI Sentinel GUI Module
local version = "1.0.1"

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
    local w, h = term.getSize()
    local isPocketPC = h <= 13  -- Standard pocket computer height is 13 or less
    return {
        width = w,
        height = h,
        isPocketPC = isPocketPC,
        headerHeight = isPocketPC and 2 or 3,
        footerHeight = 1,
        contentHeight = h - (isPocketPC and 3 or 4)  -- Adjust content area based on device
    }
end

function gui.drawScreen()
    local screen = gui.getScreenDimensions()
    term.clear()
    term.setCursorPos(1,1)
    term.setTextColor(colors.yellow)
    
    if screen.isPocketPC then
        -- Compact header for pocket PC
        print(string.rep("#", screen.width))
        print("#" .. string.rep(" ", math.floor((screen.width - 19) / 2)) .. "SCI Sentinel" .. string.rep(" ", screen.width - 19 - math.floor((screen.width - 19) / 2)) .. "#")
    else
        -- Full header for normal PC
        print(string.rep("#", screen.width))
        print("#" .. string.rep(" ", math.floor((screen.width - 23) / 2)) .. "Welcome to SCI Sentinel" .. string.rep(" ", screen.width - 23 - math.floor((screen.width - 23) / 2)) .. "#")
        print(string.rep("#", screen.width))
    end
    term.setTextColor(colors.white)
end

function gui.printPrompt()
    -- Show current directory in prompt
    local currentDir = shell.dir()
    if currentDir == "" then currentDir = "/" end
    term.setTextColor(colors.cyan)
    write(currentDir)
    term.setTextColor(colors.lime)
    write("> ")
    term.setTextColor(colors.white)
end

function gui.drawSuccess(message)
    term.setTextColor(colors.lime)
    print(message)
    term.setTextColor(colors.white)
end

function gui.drawError(message)
    term.setTextColor(colors.red)
    print("Error: " .. message)
    term.setTextColor(colors.white)
end

function gui.drawWarning(message)
    term.setTextColor(colors.yellow)
    print("Warning: " .. message)
    term.setTextColor(colors.white)
end

function gui.drawInfo(message)
    term.setTextColor(colors.white)
    print(message)
    term.setTextColor(colors.white)
end

function gui.confirm(message)
    term.setTextColor(colors.yellow)
    print(message .. " (y/n)")
    local input = read():lower()
    term.setTextColor(colors.white)
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
    term.setTextColor(colors.white)
    write(text .. " [")
    term.setTextColor(colors.lime)
    
    local barWidth = width - #text - 3
    if showPercent then
        barWidth = barWidth - 5  -- Account for percentage display
    end
    local filled = math.floor(barWidth * progress)
    write(string.rep("=", filled))
    term.setTextColor(colors.gray)
    write(string.rep("-", barWidth - filled))
    term.setTextColor(colors.white)
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
        term.setTextColor(colors.white)
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
    term.setBackgroundColor(colors.gray)
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
    write("+" .. string.rep("-", width-2) .. "+")
    
    -- Draw title if provided
    if title then
        term.setCursorPos(x + 2, y)
        write(" " .. title .. " ")
    end
    
    -- Draw sides
    for i = 1, height-2 do
        term.setCursorPos(x, y + i)
        write("|")
        term.setCursorPos(x + width-1, y + i)
        write("|")
    end
    
    -- Draw bottom border
    term.setCursorPos(x, y + height-1)
    write("+" .. string.rep("-", width-2) .. "+")
    
    -- Return the content area dimensions for convenience
    return {
        contentX = x + 1,
        contentY = y + 1,
        contentWidth = width - 2,
        contentHeight = height - 2
    }
end

-- Draw a button
function gui.drawButton(x, y, text, buttonColor)
    local oldBg = term.getBackgroundColor()
    local oldFg = term.getTextColor()
    
    term.setCursorPos(x, y)
    term.setBackgroundColor(buttonColor or colors.blue)
    term.setTextColor(colors.white)
    write(" " .. text .. " ")
    
    term.setBackgroundColor(oldBg)
    term.setTextColor(oldFg)
    
    return {
        x = x,
        y = y,
        width = #text + 2,
        text = text
    }
end

-- Handle button clicks
function gui.handleButtons(buttons)
    while true do
        local event, button, x, y = os.pullEvent("mouse_click")
        for _, btn in ipairs(buttons) do
            if y == btn.y and x >= btn.x and x < btn.x + btn.width then
                return btn.text
            end
        end
    end
end

-- Draw a fancy progress bar
function gui.drawFancyProgressBar(x, y, width, text, progress)
    local barWidth = width - #text - 3
    local filled = math.floor(barWidth * progress)
    
    term.setCursorPos(x, y)
    term.setTextColor(colors.white)
    write(text .. " [")
    term.setTextColor(colors.lime)
    write(string.rep("=", filled))
    term.setTextColor(colors.gray)
    write(string.rep("-", barWidth - filled))
    term.setTextColor(colors.white)
    write("]")
end

-- Draw a centered text line
function gui.drawCenteredText(y, text, textColor)
    local w, _ = term.getSize()
    local x = math.floor((w - #text) / 2) + 1
    term.setCursorPos(x, y)
    if textColor then
        term.setTextColor(textColor)
    end
    write(text)
    term.setTextColor(colors.white)
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
        term.setTextColor(colors.white)
        write(text .. " [")
        term.setTextColor(colors.lime)
        
        local barWidth = width - #text - 3
        local filled = math.floor(barWidth * currentProgress)
        write(string.rep("=", filled))
        term.setTextColor(colors.gray)
        write(string.rep("-", barWidth - filled))
        term.setTextColor(colors.white)
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
    bgColor = bgColor or colors.black
    fgColor = fgColor or colors.white
    
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
        term.setTextColor(colors.yellow)
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

-- Draw a clickable button with hover effect
function gui.drawClickableButton(x, y, text, bgColor, hoverColor)
    local width = #text + 2
    local buttonData = {
        x = x,
        y = y,
        width = width,
        height = 1,
        text = text,
        bgColor = bgColor or colors.blue,
        hoverColor = hoverColor or colors.lightBlue,
        clicked = false
    }
    
    -- Draw initial button
    gui.drawButton(x, y, text, buttonData.bgColor)
    
    return buttonData
end

-- Handle mouse events for buttons
function gui.handleMouseEvents(buttons)
    while true do
        local event, button, x, y = os.pullEvent()
        
        if event == "mouse_click" or event == "mouse_drag" then
            -- Check each button
            for _, btn in ipairs(buttons) do
                if x >= btn.x and x < btn.x + btn.width and
                   y == btn.y then
                    -- Button clicked
                    gui.drawButton(btn.x, btn.y, btn.text, btn.hoverColor)
                    btn.clicked = true
                end
            end
        elseif event == "mouse_up" then
            -- Check for clicked buttons
            for _, btn in ipairs(buttons) do
                if btn.clicked then
                    -- Reset button appearance
                    gui.drawButton(btn.x, btn.y, btn.text, btn.bgColor)
                    if x >= btn.x and x < btn.x + btn.width and
                       y == btn.y then
                        -- Button was released while mouse was still over it
                        return btn.text
                    end
                    btn.clicked = false
                end
            end
        end
    end
end

-- Draw a section header
function gui.drawHeader(x, y, text, color)
    term.setCursorPos(x, y)
    term.setTextColor(color or colors.yellow)
    write("[ " .. text .. " ]")
    term.setTextColor(colors.white)
end

return gui
