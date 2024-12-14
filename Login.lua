local login = {}
local theme = require("Theme")
local ErrorHandler = require("ErrorHandler")

-- Default user credentials
local users = {
    ["Ickycoolboy"] = "",
    ["The Dertopian"] = ""
}

-- Validate login credentials
local function validateLogin(username)
    ErrorHandler.logError("Login", "Validating login for user: " .. username)
    if not users[username] then
        ErrorHandler.logError("Login", "Invalid username: " .. username)
        return false
    end
    return true
end

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
    
    while true do
        -- Get terminal dimensions
        local w, h = term.getSize()
        local boxWidth = 30
        local boxHeight = 7
        local startX = math.floor((w - boxWidth) / 2)
        local startY = math.floor((h - boxHeight) / 2)
        
        -- Draw login box
        local success = ErrorHandler.protectedCall("draw_login_box", function()
            term.setBackgroundColor(theme.getColor("background"))
            term.clear()
            
            -- Draw box
            term.setBackgroundColor(theme.getColor("windowBg"))
            term.setTextColor(theme.getColor("text"))
            
            for y = startY, startY + boxHeight - 1 do
                term.setCursorPos(startX, y)
                term.write(string.rep(" ", boxWidth))
            end
            
            -- Draw title
            term.setCursorPos(startX + (boxWidth - 11) / 2, startY)
            term.write("Login Screen")
            
            -- Draw input prompts
            term.setCursorPos(startX + 2, startY + 2)
            term.write("Username: ")
            
            -- Draw valid users
            term.setCursorPos(startX + 2, startY + 4)
            term.write("Valid users:")
            local userList = {}
            for user, _ in pairs(users) do
                table.insert(userList, user)
            end
            term.setCursorPos(startX + 2, startY + 5)
            term.write(table.concat(userList, ", "))
            
            return true
        end)
        
        if not success then
            ErrorHandler.logError("Login", "Failed to draw login screen")
            return false
        end
        
        -- Handle login input
        term.setCursorPos(startX + 11, startY + 2)
        term.setTextColor(theme.getColor("text"))
        local username = getUserInput(startX + 11, startY + 2, false)
        
        if not username or username == "" then
            ErrorHandler.logError("Login", "No username entered")
            -- Show error message
            term.setCursorPos(startX + 2, startY + 6)
            term.setTextColor(theme.getColor("error"))
            term.write("Please enter a username!")
            os.sleep(2)
        else
            -- Validate login
            if validateLogin(username) then
                ErrorHandler.logError("Login", "Login successful for user: " .. username)
                login.exitLoginScreen()
                return true
            else
                -- Show error message
                term.setCursorPos(startX + 2, startY + 6)
                term.setTextColor(theme.getColor("error"))
                term.write("Invalid username!")
                os.sleep(2)
            end
        end
    end
end

function login.exitLoginScreen()
    theme.isLoginScreen = false  -- Reset flag to show title bar
    theme.init() -- Clear screen with theme
end

return login
