local login = {}
local theme = require("Theme")
local ErrorHandler = require("ErrorHandler")

-- Default user credentials
local users = {
    ["Ickycoolboy"] = "",
    ["The Dertopian"] = ""
}

-- Save terminal state
local function saveTerminalState()
    local x, y = term.getCursorPos()
    return {
        bg = term.getBackgroundColor(),
        fg = term.getTextColor(),
        x = x,
        y = y
    }
end

-- Restore terminal state
local function restoreTerminalState(state)
    if state then
        term.setBackgroundColor(state.bg)
        term.setTextColor(state.fg)
        term.setCursorPos(state.x, state.y)
    end
end

-- Handle user input with proper event handling
local function getUserInput(x, y, isPassword)
    term.setCursorPos(x, y)
    term.setCursorBlink(true)
    
    local input = ""
    local cursorPos = 1
    
    while true do
        local event, param1, param2, param3 = os.pullEvent()
        
        if event == "char" then
            -- Insert character at cursor position
            input = string.sub(input, 1, cursorPos - 1) .. param1 .. string.sub(input, cursorPos)
            cursorPos = cursorPos + 1
            
            -- Redraw input line
            term.setCursorPos(x, y)
            if isPassword then
                term.write(string.rep("*", #input))
            else
                term.write(input)
            end
            term.setCursorPos(x + cursorPos - 1, y)
            
        elseif event == "key" then
            if param1 == keys.enter then
                term.setCursorBlink(false)
                return input
            elseif param1 == keys.backspace and cursorPos > 1 then
                -- Remove character before cursor
                input = string.sub(input, 1, cursorPos - 2) .. string.sub(input, cursorPos)
                cursorPos = cursorPos - 1
                
                -- Redraw input line
                term.setCursorPos(x, y)
                if isPassword then
                    term.write(string.rep("*", #input) .. " ")
                else
                    term.write(input .. " ")
                end
                term.setCursorPos(x + cursorPos - 1, y)
            end
        end
    end
end

function login.showLoginScreen()
    ErrorHandler.logError("Login", "Starting login screen display")
    
    -- Save initial terminal state
    local initialState = saveTerminalState()
    
    -- Set login screen flag
    theme.isLoginScreen = true
    
    -- Get terminal dimensions
    local w, h = term.getSize()
    local boxWidth = 30
    local boxHeight = 5
    local startX = math.floor((w - boxWidth) / 2)
    local startY = math.floor((h - boxHeight) / 2)
    
    -- Clear screen with current theme colors
    local success = ErrorHandler.protectedCall("clear_screen", function()
        term.setBackgroundColor(theme.getColor("background"))
        term.clear()
        return true
    end)
    
    if not success then
        ErrorHandler.logError("Login", "Failed to clear screen")
        restoreTerminalState(initialState)
        return false
    end
    
    -- Draw minimal login interface
    success = ErrorHandler.protectedCall("draw_login_box", function()
        theme.drawBox(startX, startY, boxWidth, boxHeight, "Login")
        return true
    end)
    
    if not success then
        ErrorHandler.logError("Login", "Failed to draw login box")
        restoreTerminalState(initialState)
        return false
    end
    
    -- Username input
    term.setBackgroundColor(theme.getColor("windowBg"))
    term.setTextColor(theme.getColor("text"))
    term.setCursorPos(startX + 2, startY + 2)
    term.write("Username: ")
    local username = getUserInput(startX + 11, startY + 2, false)
    
    ErrorHandler.logError("Login", "Username entered: " .. username)
    
    -- Validate credentials
    if users[username] ~= nil then
        if users[username] == "" then
            ErrorHandler.logError("Login", "Login successful for user: " .. username)
            
            -- Reset login screen flag
            theme.isLoginScreen = false
            
            -- Initialize shell environment with error handling
            success = ErrorHandler.protectedCall("init_shell", function()
                term.setBackgroundColor(theme.getColor("background"))
                term.setTextColor(theme.getColor("text"))
                term.clear()
                term.setCursorPos(1, 2)
                term.write("> ")
                return true
            end)
            
            if not success then
                ErrorHandler.logError("Login", "Failed to initialize shell environment")
                restoreTerminalState(initialState)
                return false
            end
            
            return true
        else
            -- Handle password-protected accounts
            term.setCursorPos(startX + 2, startY + 3)
            term.write("Password: ")
            local password = getUserInput(startX + 11, startY + 3, true)
            
            if password == users[username] then
                ErrorHandler.logError("Login", "Login successful for user: " .. username)
                
                -- Reset login screen flag
                theme.isLoginScreen = false
                
                -- Initialize shell environment with error handling
                success = ErrorHandler.protectedCall("init_shell", function()
                    term.setBackgroundColor(theme.getColor("background"))
                    term.setTextColor(theme.getColor("text"))
                    term.clear()
                    term.setCursorPos(1, 2)
                    term.write("> ")
                    return true
                end)
                
                if not success then
                    ErrorHandler.logError("Login", "Failed to initialize shell environment")
                    restoreTerminalState(initialState)
                    return false
                end
                
                return true
            end
        end
    end
    
    -- Add error handling for invalid username
    term.setCursorPos(startX + 2, startY + 3)
    term.setTextColor(theme.getColor("error"))
    term.write("Invalid username. Try again.")
    os.sleep(2)  -- Pause to show error message
        
    ErrorHandler.logError("Login", "Login failed for user: " .. username)
    restoreTerminalState(initialState)
    return false
end

function login.exitLoginScreen()
    theme.isLoginScreen = false  -- Reset flag to show title bar
    theme.init() -- Clear screen with theme
end

return login
