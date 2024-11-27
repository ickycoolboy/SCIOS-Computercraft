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

function gui.drawScreen()
    term.clear()
    term.setCursorPos(1,1)
    term.setTextColor(colors.yellow)
    print("#######################################")
    print("#       Welcome to SCI Sentinel       #")
    print("#######################################")
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
    term.setTextColor(colors.white)
    gui.printPrompt()
    local input = read():lower()
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
    local filled = math.floor(barWidth * progress)
    write(string.rep("=", filled))
    term.setTextColor(colors.gray)
    write(string.rep("-", barWidth - filled))
    term.setTextColor(colors.white)
    write("]")
    
    -- Add percentage display if requested
    if showPercent then
        local percent = math.floor(progress * 100)
        term.setCursorPos(x + width + 1, y)
        write(string.format(" %3d%%", percent))
    end
end

-- Update progress with status message
function gui.updateProgress(x, y, width, text, progress, status)
    gui.drawProgressBar(x, y, width, text, progress, true)
    if status then
        term.setCursorPos(x, y + 1)
        term.setTextColor(colors.white)
        -- Ensure there's a space after the percentage
        local percent = math.floor(progress * 100)
        write(string.format("%3d%% %s", percent, status))
        -- Clear the rest of the line
        local remaining = width - #status - 5  -- 5 for the percentage and space
        if remaining > 0 then
            write(string.rep(" ", remaining))
        end
    end
end

-- Message box
function gui.messageBox(title, message)
    local oldBg = term.getBackgroundColor()
    local oldFg = term.getTextColor()
    local w, h = term.getSize()
    
    -- Draw box
    term.setBackgroundColor(colors.gray)
    term.clear()
    term.setCursorPos(1, 1)
    term.setTextColor(colors.white)
    print(string.rep("-", w))
    print(string.format("| %-" .. (w-4) .. "s |", title))
    print(string.rep("-", w))
    print(string.format("| %-" .. (w-4) .. "s |", message))
    print(string.rep("-", w))
    print("| Press any key to continue" .. string.rep(" ", w-26) .. "|")
    print(string.rep("-", w))
    
    -- Wait for keypress
    os.pullEvent("key")
    
    -- Restore colors
    term.setBackgroundColor(oldBg)
    term.setTextColor(oldFg)
    gui.drawScreen()
end

-- Draw a box with borders
function gui.drawBox(x, y, width, height, title)
    -- Draw top border
    term.setCursorPos(x, y)
    write("+" .. string.rep("-", width-2) .. "+")
    
    -- Draw sides
    for i = 1, height-2 do
        term.setCursorPos(x, y+i)
        write("|" .. string.rep(" ", width-2) .. "|")
    end
    
    -- Draw bottom border
    term.setCursorPos(x, y+height-1)
    write("+" .. string.rep("-", width-2) .. "+")
    
    -- Draw title if provided
    if title then
        term.setCursorPos(x + math.floor((width - #title) / 2), y)
        write(title)
    end
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

return gui
