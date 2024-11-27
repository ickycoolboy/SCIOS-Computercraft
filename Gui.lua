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

return gui
