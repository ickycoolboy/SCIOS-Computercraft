-- SCI Sentinel OS Startup
local version = "1.0.1" -- Version bump for case sensitivity fix

-- System file protection
local protected_files = {
    "scios/Sci_sentinel.lua",
    "scios/Gui.lua",
    "scios/Commands.lua",
    "scios/Updater.lua",
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

-- Show login screen
while true do
    if login.showLoginScreen() then
        -- Login successful, run the main system
        if fs.exists("scios/Sci_sentinel.lua") then
            shell.run("scios/Sci_sentinel.lua")
        else
            print("SCI Sentinel OS not found. Please run the installer.")
        end
        break
    else
        -- Login failed
        term.clear()
        term.setCursorPos(1,1)
        term.setTextColor(colors.red)
        print("Login failed. Please try again.")
        term.setTextColor(colors.white)
        os.sleep(2)
    end
end
