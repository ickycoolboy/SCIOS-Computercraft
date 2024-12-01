local login = {}
local theme = require("Theme")

-- Default user credentials
local users = {
    ["Ickycoolboy"] = "",
    ["The Dertopian"] = ""
}

function login.showLoginScreen()
    -- Initialize theme and clear screen
    theme.init()
    theme.isLoginScreen = true  -- Set flag to hide title bar
    theme.drawInterface()
    
    -- Get terminal dimensions
    local w, h = term.getSize()
    local boxWidth = 30
    local boxHeight = 5
    local startX = math.floor((w - boxWidth) / 2)
    local startY = math.floor((h - boxHeight) / 2)
    
    -- Draw minimal login interface
    theme.drawBox(startX, startY, boxWidth, boxHeight, "Login")
    
    -- Username input
    term.setBackgroundColor(theme.getColor("windowBg"))
    term.setTextColor(theme.getColor("text"))
    term.setCursorPos(startX + 2, startY + 2)
    term.write("Username: ")
    term.setCursorPos(startX + 11, startY + 2)
    local username = read()
    
    -- Validate credentials
    if users[username] ~= nil then
        if users[username] == "" then
            theme.init() -- Clear screen with theme
            return true
        else
            term.setCursorPos(startX + 2, startY + 3)
            term.write("Password: ")
            term.setCursorPos(startX + 11, startY + 3)
            local password = read("*")
            
            theme.init() -- Clear screen with theme
            return password == users[username]
        end
    end
    
    theme.init() -- Clear screen with theme
    return false
end

function login.exitLoginScreen()
    theme.isLoginScreen = false  -- Reset flag to show title bar
    theme.init() -- Clear screen with theme
end

return login
