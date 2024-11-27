-- SCI Sentinel OS GUI Module
local gui = {}

function gui.drawScreen()
    term.clear()
    term.setCursorPos(1, 1)
    term.setTextColor(colors.yellow)
    print("############################################")
    print("#            Welcome to SCI Sentinel       #")
    print("############################################")
    term.setTextColor(colors.white)
end

function gui.printPrompt()
    term.setTextColor(colors.lightBlue)
    write("SCI-Sentinel> ")
    term.setTextColor(colors.white)
end

function gui.drawError(message)
    term.setTextColor(colors.red)
    print("Error: " .. message)
    term.setTextColor(colors.white)
end

function gui.drawSuccess(message)
    term.setTextColor(colors.green)
    print(message)
    term.setTextColor(colors.white)
end

-- Return the GUI module
return gui