-- SCI Sentinel OS Startup
local version = "1.34"

-- Set up the module path
if not fs.exists("scios") then
    fs.makeDir("scios")
end

-- Add the scios directory to package path
package.path = "./?.lua;/scios/?.lua;" .. package.path

-- Initialize theme system
local theme = require("Theme")
theme.init()

-- Track key states
local altHeld = false

-- Handle resolution controls
local function handleResolution()
    while true do
        local event, key = os.pullEvent()
        
        if event == "key" then
            -- 56 is the left alt key in ComputerCraft
            if key == 56 then
                altHeld = true
            elseif altHeld then
                if key == keys.EQUALS then -- plus key
                    local currentScale = term.current().getTextScale()
                    if currentScale > 0.5 then
                        term.current().setTextScale(currentScale - 0.5)
                    end
                    theme.init() -- Refresh theme after resize
                elseif key == keys.MINUS then -- minus key
                    local currentScale = term.current().getTextScale()
                    if currentScale < 5 then
                        term.current().setTextScale(currentScale + 0.5)
                    end
                    theme.init() -- Refresh theme after resize
                end
            end
        elseif event == "key_up" and key == 56 then
            altHeld = false
        end
    end
end

-- Display startup message
theme.drawTitleBar("SCI Sentinel OS v" .. version)

-- Show resize hint
local w, h = term.getSize()
term.setBackgroundColor(colors.black)
term.setTextColor(colors.white)
term.setCursorPos(1, math.floor(h/2))
term.write(string.rep(" ", w))
local msg = "Press Alt + +/- to adjust screen size"
local x = math.floor((w - #msg) / 2)
term.setCursorPos(x, math.floor(h/2))
term.write(msg)
os.sleep(3) -- Show the message longer

-- Clear the hint
term.setBackgroundColor(colors.black)
term.clear()
theme.drawTitleBar("SCI Sentinel OS v" .. version)

-- System file protection
local protected_files = {
    "scios/Sci_sentinel.lua",
    "scios/Gui.lua",
    "scios/Commands.lua",
    "scios/Updater.lua",
    "scios/Theme.lua",
    "startup.lua",
    "scios/versions.db"
}

-- Override fs.delete for protected files
local original_delete = fs.delete
fs.delete = function(path)
    path = fs.combine("", path) -- Normalize path
    for _, protected in ipairs(protected_files) do
        if path == protected then
            return false -- Prevent deletion of protected files
        end
    end
    return original_delete(path)
end

-- Load the login screen
local login = require("scios/Login")

-- Start resolution control in parallel with login
parallel.waitForAll(
    handleResolution,
    function()
        while true do
            theme.init() -- Ensure theme is maintained
            if not login.showLoginScreen() then
                term.setBackgroundColor(colors.black)
                term.setTextColor(colors.red)
                term.clear()
                term.setCursorPos(1, 1)
                print("Login failed!")
                os.sleep(2)
            else
                -- Login successful, run the main system
                theme.init() -- Ensure clean slate
                term.setBackgroundColor(theme.getColor("background"))
                term.clear()
                theme.drawTitleBar("SCI Sentinel OS v" .. version)
                
                if fs.exists("scios/Sci_sentinel.lua") then
                    shell.run("scios/Sci_sentinel.lua")
                else
                    term.setBackgroundColor(theme.getColor("background"))
                    term.setTextColor(theme.getColor("text"))
                    term.setCursorPos(1, 3)
                    print("SCI Sentinel OS not found. Please run the installer.")
                end
                break
            end
        end
    end
)
