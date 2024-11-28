-- SCI Sentinel OS Startup
local version = "1.0.1" -- Version bump for case sensitivity fix

-- Set up the module path
if not fs.exists("scios") then
    fs.makeDir("scios")
end

-- Add the scios directory to package path
package.path = "./?.lua;/scios/?.lua;" .. package.path

-- Initialize theme system
local theme = require("Theme")
theme.init() -- Initialize theme colors

-- Display startup message with theme colors
term.setBackgroundColor(theme.getColor("background"))
term.setTextColor(theme.getColor("text"))
term.clear()
term.setCursorPos(1, 1)
local w, h = term.getSize()
local msg = "SCI Sentinel OS v" .. version
local x = math.floor((w - #msg) / 2)
term.setCursorPos(x, math.floor(h / 2))
term.write(msg)
term.setCursorPos(1, h)
term.write("Press Ctrl + +/- to adjust screen size")
os.sleep(1)

-- Reset to theme colors
term.setBackgroundColor(theme.getColor("background"))
term.clear()

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

-- Handle resolution controls
local function handleResolution()
    while true do
        local event, key, held = os.pullEvent("key")
        if held then
            if key == keys.equals then -- Ctrl + + (zoom out)
                local w, h = term.getSize()
                term.setResolution(w + 1, h + 1)
            elseif key == keys.minus then -- Ctrl + - (zoom in)
                local w, h = term.getSize()
                if w > 20 and h > 10 then -- Prevent too small resolution
                    term.setResolution(w - 1, h - 1)
                end
            end
        end
    end
end

-- Start resolution control in parallel
parallel.waitForAny(function()
    handleResolution()
end, function()
    while true do
        theme.init() -- Ensure theme is maintained
        if not login.showLoginScreen() then
            term.setBackgroundColor(theme.getColor("background"))
            term.setTextColor(theme.getColor("text"))
            term.clear()
            term.setCursorPos(1, 1)
            print("Login failed!")
            os.sleep(2)
        else
            -- Login successful, run the main system
            if fs.exists("scios/Sci_sentinel.lua") then
                shell.run("scios/Sci_sentinel.lua")
            else
                print("SCI Sentinel OS not found. Please run the installer.")
            end
            break
        end
    end
end)
