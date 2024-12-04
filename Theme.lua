-- SCI Sentinel Theme Module
local ErrorHandler = require("ErrorHandler")

-- Log module loading attempt
ErrorHandler.logError("Theme", "Theme module is being loaded")

local theme = {
    -- Module version
    version = "1.34",
    -- Initialize flag
    _initialized = false
}

-- Validate ErrorHandler
if not ErrorHandler or type(ErrorHandler) ~= "table" then
    error("ErrorHandler module failed to load correctly")
end

-- Default color definitions
local defaultColors = {
    titleBar = colors.purple,
    titleText = colors.white,
    windowBg = colors.black,
    text = colors.purple,
    background = colors.black,
    shellBg = colors.black,
    shellText = colors.purple,
    buttonBg = colors.gray,
    buttonText = colors.white,
    buttonHover = colors.lightGray,
    menuBg = colors.black,
    menuText = colors.white,
    menuSelect = colors.blue,
    menuSelectText = colors.white,
    progressBg = colors.black,
    progressBar = colors.blue,
    scrollBg = colors.black,
    scrollHandle = colors.blue,
    tabActive = colors.blue,
    tabInactive = colors.gray,
    tabTextActive = colors.white,
    tabTextInactive = colors.black,
    border = colors.gray,
    dimText = colors.gray,
    shadow = colors.gray,
    error = colors.red
}

-- Current theme colors (can be modified by user)
local currentColors = {}

-- Load saved theme with error handling
function theme.loadTheme()
    ErrorHandler.logError("Theme", "Loading theme configuration...")
    return ErrorHandler.protectedCall("load_theme", function()
        -- Initialize with defaults first
        for k, v in pairs(defaultColors) do
            currentColors[k] = v
        end
        
        if fs.exists("/scios/theme.cfg") then
            ErrorHandler.logError("Theme", "Theme configuration file found")
            local file = fs.open("/scios/theme.cfg", "r")
            if not file then
                error("Failed to open theme configuration")
            end
            
            local content = file.readAll()
            file.close()
            
            local data = textutils.unserialize(content)
            if type(data) ~= "table" then
                error("Invalid theme configuration format")
            end
            
            -- Validate colors before applying
            for k, v in pairs(data) do
                if type(v) ~= "number" then
                    error("Invalid color value for " .. k .. ": " .. tostring(v))
                end
                currentColors[k] = v
            end
            ErrorHandler.logError("Theme", "Theme configuration loaded successfully")
        else
            ErrorHandler.logError("Theme", "No saved theme configuration. Using defaults")
        end
        return true
    end)
end

-- Initialize the theme system
function theme.init()
    -- Check for persistent initialization state
    if fs.exists("/scios/.theme_initialized") then
        ErrorHandler.logError("Theme", "Initialization skipped: found persistent state")
        return true
    end
    
    ErrorHandler.logError("Theme", "Starting theme initialization")
    local success = theme.loadTheme()
    if not success then
        ErrorHandler.logError("Theme", "Failed to load theme configuration")
        return false
    end
    
    -- Create persistent initialization state
    local file = fs.open("/scios/.theme_initialized", "w")
    if file then
        file.write("initialized")
        file.close()
    end
    
    theme._initialized = true
    ErrorHandler.logError("Theme", "Theme initialization completed successfully")
    return true
end

-- Reset theme initialization state
function theme.reset()
    if fs.exists("/scios/.theme_initialized") then
        fs.delete("/scios/.theme_initialized")
    end
    theme._initialized = false
    ErrorHandler.logError("Theme", "Theme initialization state reset")
end

-- Check if theme is initialized
function theme.isInitialized()
    return theme._initialized
end

-- Direct terminal operations
local function setBackgroundColor(color)
    if type(color) ~= "number" then
        ErrorHandler.logError("Set Background Color", "Invalid color value: " .. tostring(color))
        color = colors.black -- Fallback to default
    end
    term.setBackgroundColor(color)
end

local function setTextColor(color)
    if type(color) ~= "number" then
        ErrorHandler.logError("Set Text Color", "Invalid color value: " .. tostring(color))
        color = colors.white -- Fallback to default
    end
    term.setTextColor(color)
end

-- Save current theme with error handling
function theme.saveTheme()
    return ErrorHandler.protectedCall("save_theme", function()
        -- Validate theme before saving
        for k, v in pairs(currentColors) do
            if type(v) ~= "number" then
                error("Invalid color value for " .. k .. ": " .. tostring(v))
            end
        end
        
        local file = fs.open("/scios/theme.cfg", "w")
        if not file then
            error("Failed to create theme configuration file")
        end
        
        file.write(textutils.serialize(currentColors))
        file.close()
        return true
    end)
end

-- Set a specific color with validation
function theme.setColor(name, color)
    return ErrorHandler.protectedCall("set_color", function()
        if defaultColors[name] == nil then
            error("Invalid theme element: " .. tostring(name))
        end
        if type(color) ~= "number" then
            error("Invalid color value: " .. tostring(color))
        end
        
        currentColors[name] = color
        return true
    end)
end

-- Get a color value safely
function theme.getColor(name)
    -- Ensure currentColors is initialized
    if not currentColors or not next(currentColors) then
        -- Force initialization, but don't error out
        pcall(theme.init)
    end
    
    -- Fallback color mapping with comprehensive coverage
    local fallbackColors = {
        titleBar = colors.purple,
        titleText = colors.white,
        windowBg = colors.black,
        text = colors.white,
        background = colors.black,
        border = colors.gray,
        shadow = colors.gray,
        buttonBg = colors.gray,
        buttonText = colors.white,
        progressBar = colors.blue,
        progressBg = colors.black,
        error = colors.red,
        shellBg = colors.black,
        shellText = colors.white
    }
    
    -- Safely retrieve color
    local color = currentColors and currentColors[name]
    
    -- If color is nil, use fallback
    if color == nil then
        color = fallbackColors[name]
        
        -- Log color retrieval for debugging
        if color ~= nil then
            ErrorHandler.logError("Get Color", "Using fallback color for " .. tostring(name) .. ": " .. tostring(color))
        else
            ErrorHandler.logError("Get Color", "No color found for " .. tostring(name) .. ", using default gray")
            color = colors.gray
        end
    end
    
    return color
end

-- Reset to defaults with error handling
function theme.resetToDefaults()
    return ErrorHandler.protectedCall("reset_defaults", function()
        for k, v in pairs(defaultColors) do
            currentColors[k] = v
        end
        return theme.saveTheme()
    end)
end

-- Get all theme colors safely
function theme.getColors()
    return ErrorHandler.protectedCall("get_colors", function()
        local result = {}
        for k, v in pairs(currentColors) do
            result[k] = v
        end
        return result
    end)
end

-- Get available color names safely
function theme.getColorNames()
    return ErrorHandler.protectedCall("get_color_names", function()
        local names = {}
        for k, _ in pairs(defaultColors) do
            table.insert(names, k)
        end
        return names
    end)
end

-- Get native terminal safely
local native = term.native()
local shellWindow = nil

-- Create a themed shell window with error handling
local function createShellWindow()
    local w, h = term.getSize()
    shellWindow = window.create(term.current(), 1, 1, w, h, true)
    if not shellWindow then
        error("Failed to create shell window")
    end
    
    local bgColor = theme.getColor("shellBg")
    ErrorHandler.logError("Shell Window", "Background color: " .. tostring(bgColor))
    shellWindow.setBackgroundColor(bgColor)
    
    local textColor = theme.getColor("shellText")
    ErrorHandler.logError("Shell Window", "Text color: " .. tostring(textColor))
    shellWindow.setTextColor(textColor)
    
    return shellWindow
end

-- Safe terminal redirection
local function safeRedirect(target)
    local success, result = ErrorHandler.protectedCall("terminal_redirect", function()
        return term.redirect(target)
    end)
    
    if success then
        return result
    else
        ErrorHandler.logError("Theme", "Failed to redirect terminal: " .. tostring(result))
        return term.current() -- Fallback to current terminal
    end
end

-- Create a new window for the content area
local mainWindow = nil

-- Initialize content window with error handling
function theme.initContentWindow()
    return ErrorHandler.protectedCall("init_content_window", function()
        local dims = theme.getScreenDimensions()
        if not dims then
            error("Failed to get screen dimensions")
        end
        
        mainWindow = window.create(term.current(), 1, dims.usableStartY, dims.width, dims.height - dims.titleBarHeight)
        if not mainWindow then
            error("Failed to create main window")
        end
        return mainWindow
    end)
end

-- Get the main content window safely
function theme.getContentWindow()
    return ErrorHandler.protectedCall("get_content_window", function()
        if not mainWindow then
            return theme.initContentWindow()
        end
        return mainWindow
    end)
end

-- Redirect to content window
function theme.redirect()
    local contentWindow = theme.getContentWindow()
    return term.redirect(contentWindow)
end

-- Draw a simple window
function theme.drawBox(x, y, width, height, title)
    local current = term.current()
    
    -- Fill window area
    current.setBackgroundColor(theme.getColor("windowBg"))
    for i = y, y + height - 1 do
        current.setCursorPos(x, i)
        current.write(string.rep(" ", width))
    end

    -- Draw title bar if provided
    if title then
        current.setBackgroundColor(theme.getColor("titleBar"))
        current.setTextColor(theme.getColor("titleText"))
        current.setCursorPos(x, y)
        current.write(string.rep(" ", width))
        current.setCursorPos(x + 1, y)
        current.write(title)
    end
end

-- Draw full-width title bar
function theme.drawFullWidthTitleBar(title)
    local current = term.current()
    local w, h = current.getSize()
    
    -- Clear the first line completely
    current.setBackgroundColor(theme.getColor("titleBar"))
    current.setTextColor(theme.getColor("titleText"))
    current.setCursorPos(1, 1)
    current.write(string.rep(" ", w))
    
    -- Write title
    if title then
        current.setCursorPos(2, 1)
        current.write(title)
    end
    
    -- Fill rest with background
    current.setBackgroundColor(theme.getColor("background"))
    for i = 2, h do
        current.setCursorPos(1, i)
        current.write(string.rep(" ", w))
    end
end

-- Draw the persistent title bar
function theme.drawPersistentTitleBar(title)
    return ErrorHandler.protectedCall("draw_title_bar", function()
        if not title then
            title = "SCI Sentinel OS"
        end
        
        local current = term.current()
        local w, h = current.getSize()
        
        -- Draw the title bar background
        setBackgroundColor(theme.getColor("titleBar"))
        setTextColor(theme.getColor("titleText"))
        current.setCursorPos(1, 1)
        current.write(string.rep(" ", w))
        
        -- Center the title
        local titleX = math.floor((w - #title) / 2) + 1
        current.setCursorPos(titleX, 1)
        current.write(title)
        
        -- Reset cursor position
        current.setCursorPos(1, 2)
        
        return true
    end)
end

-- Draw the persistent title bar
function theme.drawTitleBar(title)
    return ErrorHandler.protectedCall("draw_title_bar", function()
        if not title then
            title = "SCI Sentinel OS"
        end
        
        local current = term.current()
        local w, h = current.getSize()
        
        -- Draw the title bar background
        setBackgroundColor(theme.getColor("titleBar"))
        setTextColor(theme.getColor("titleText"))
        current.setCursorPos(1, 1)
        current.write(string.rep(" ", w))
        
        -- Center the title
        local titleX = math.floor((w - #title) / 2) + 1
        current.setCursorPos(titleX, 1)
        current.write(title)
        
        -- Reset cursor position
        current.setCursorPos(1, 2)
        
        return true
    end)
end

-- Alias for backward compatibility
theme.drawPersistentTitleBar = theme.drawTitleBar

-- Get screen dimensions safely
function theme.getScreenDimensions()
    local w, h = term.getSize()
    if type(w) ~= "number" or type(h) ~= "number" then
        error("Invalid screen dimensions")
    end
    
    return {
        width = w,
        height = h,
        titleBarHeight = 1,
        usableStartY = 2,
        usableHeight = h - 1
    }
end

-- Modified drawInterface function to handle separate content window
function theme.drawInterface()
    -- Get or create content window
    local contentWindow = theme.getContentWindow()
    
    -- Draw title bar on native terminal
    theme.drawTitleBar()
    
    -- Set up content window
    contentWindow.setBackgroundColor(theme.getColor("background"))
    contentWindow.clear()
    contentWindow.setCursorPos(1, 1)
    
    -- Return the content window for further operations
    return contentWindow
end

-- Modified drawInterface function to handle reserved title bar space
function theme.drawInterfaceWithReservedTitleBar()
    local w, h = term.getSize()
    local dims = theme.getScreenDimensions()
    
    -- Draw background
    setBackgroundColor(theme.getColor("background"))
    term.clear()
    
    -- Draw title bar (except for login screen)
    if not theme.isLoginScreen then
        -- Save current colors
        local oldBg = term.getBackgroundColor()
        local oldFg = term.getTextColor()
        
        -- Draw title bar background
        -- setBackgroundColor(theme.getColor("titleBar"))
        -- term.setCursorPos(1, 1)
        -- term.clearLine()
        
        -- Draw title text
        -- setTextColor(theme.getColor("titleText"))
        -- local title = "SCI Sentinel OS"
        -- local centerX = math.floor((w - #title) / 2) + 1
        -- term.setCursorPos(centerX, 1)
        -- term.write(title)
        
        -- Restore colors
        -- setBackgroundColor(oldBg)
        -- setTextColor(oldFg)
        
        -- Set cursor to start of usable area
        term.setCursorPos(1, dims.usableStartY)
    end
end

-- Draw a themed box
function theme.drawCompactHeader(text)
    local oldBg = term.getBackgroundColor()
    local oldFg = term.getTextColor()
    
    setBackgroundColor(theme.getColor("titleBar"))
    setTextColor(theme.getColor("titleText"))
    term.setCursorPos(1, 1)
    
    -- Create shortened text if needed
    local maxWidth = screen.width - 2
    local displayText = #text > maxWidth and text:sub(1, maxWidth-3) .. "..." or text
    
    -- Center the text
    local padding = math.floor((screen.width - #displayText) / 2)
    term.write(string.rep(" ", padding) .. displayText .. string.rep(" ", screen.width - padding - #displayText))
    
    setBackgroundColor(oldBg)
    setTextColor(oldFg)
end

-- Draw a themed button
function theme.drawButton(x, y, text, active)
    local oldBg = term.getBackgroundColor()
    local oldFg = term.getTextColor()
    
    local bg = active and theme.getColor("buttonHover") or theme.getColor("buttonBg")
    setBackgroundColor(bg)
    setTextColor(theme.getColor("buttonText"))
    
    term.setCursorPos(x, y)
    term.write(" " .. text .. " ")
    
    setBackgroundColor(oldBg)
    setTextColor(oldFg)
    
    -- Return button bounds for click detection
    return {
        x1 = x,
        x2 = x + #text + 1,
        y = y,
        text = text,
        width = #text + 2
    }
end

-- Draw a compact button
function theme.drawCompactButton(x, y, text, active)
    local oldBg = term.getBackgroundColor()
    local oldFg = term.getTextColor()
    
    local bg = active and theme.getColor("buttonHover") or theme.getColor("buttonBg")
    setBackgroundColor(bg)
    setTextColor(theme.getColor("buttonText"))
    
    -- Shorten text if needed
    local maxWidth = 5
    local displayText = #text > maxWidth and text:sub(1, maxWidth-2) .. ">" or text
    
    term.setCursorPos(x, y)
    term.write(displayText)
    
    setBackgroundColor(oldBg)
    setTextColor(oldFg)
    
    return {
        x1 = x,
        x2 = x + #displayText - 1,
        y = y,
        text = text,
        width = #displayText
    }
end

-- Draw a progress bar
function theme.drawProgressBar(x, y, width, progress, text)
    local oldBg = term.getBackgroundColor()
    local oldFg = term.getTextColor()
    
    -- Draw background
    setBackgroundColor(theme.getColor("progressBg"))
    term.setCursorPos(x, y)
    term.write(string.rep(" ", width))
    
    -- Draw progress
    local fillWidth = math.floor(progress * width)
    if fillWidth > 0 then
        setBackgroundColor(theme.getColor("progressBar"))
        term.setCursorPos(x, y)
        term.write(string.rep(" ", fillWidth))
    end
    
    -- Draw text if provided
    if text then
        local textX = x + math.floor((width - #text) / 2)
        term.setCursorPos(textX, y)
        setTextColor(theme.getColor("text"))
        term.write(text)
    end
    
    setBackgroundColor(oldBg)
    setTextColor(oldFg)
end

-- Draw a menu item
function theme.drawMenuItem(x, y, text, selected, disabled)
    local oldBg = term.getBackgroundColor()
    local oldFg = term.getTextColor()
    
    if selected then
        setBackgroundColor(theme.getColor("menuSelect"))
        setTextColor(theme.getColor("menuSelectText"))
    else
        setBackgroundColor(theme.getColor("menuBg"))
        setTextColor(disabled and theme.getColor("dimText") or theme.getColor("menuText"))
    end
    
    term.setCursorPos(x, y)
    term.write(text)
    
    setBackgroundColor(oldBg)
    setTextColor(oldFg)
end

-- Draw a status message
function theme.drawStatus(x, y, text, status)
    local oldBg = term.getBackgroundColor()
    local oldFg = term.getTextColor()
    
    term.setCursorPos(x, y)
    setTextColor(theme.getColor(status or "text"))
    term.write(text)
    
    setBackgroundColor(oldBg)
    setTextColor(oldFg)
end

-- Draw a header
function theme.drawHeader(text, y)
    y = y or 1
    local width = term.getSize()
    local oldBg = term.getBackgroundColor()
    local oldFg = term.getTextColor()
    
    -- Draw header background
    setBackgroundColor(theme.getColor("titleBar"))
    term.setCursorPos(1, y)
    term.write(string.rep(" ", width))
    
    -- Draw header text
    local textX = math.floor((width - #text) / 2)
    term.setCursorPos(textX, y)
    setTextColor(theme.getColor("titleText"))
    term.write(text)
    
    setBackgroundColor(oldBg)
    setTextColor(oldFg)
end

-- Draw a separator line
function theme.drawSeparator(y, style)
    local width = term.getSize()
    local oldBg = term.getBackgroundColor()
    local oldFg = term.getTextColor()
    
    setTextColor(theme.getColor("border"))
    term.setCursorPos(1, y)
    term.write(string.rep(theme.getBorder(style or "headerSeparator"), width))
    
    setBackgroundColor(oldBg)
    setTextColor(oldFg)
end

-- Draw a scrollable list
function theme.drawList(x, y, width, height, items, selectedIndex, scrollIndex)
    local oldBg = term.getBackgroundColor()
    local oldFg = term.getTextColor()
    
    scrollIndex = scrollIndex or 1
    local visibleItems = height - 2
    local maxScroll = math.max(1, #items - visibleItems + 1)
    scrollIndex = math.min(maxScroll, math.max(1, scrollIndex))
    
    -- Draw list box
    theme.drawBox(x, y, width, height)
    
    -- Draw items
    for i = 1, visibleItems do
        local itemIndex = i + scrollIndex - 1
        if itemIndex <= #items then
            local isSelected = itemIndex == selectedIndex
            theme.drawMenuItem(x + 1, y + i, string.sub(items[itemIndex], 1, width - 3), isSelected)
        end
    end
    
    -- Draw scrollbar if needed
    if #items > visibleItems then
        -- Draw scrollbar track
        for i = 1, height - 2 do
            term.setCursorPos(x + width - 1, y + i)
            setBackgroundColor(theme.getColor("scrollBg"))
            setTextColor(theme.getColor("scrollHandle"))
            term.write(theme.getBorder("scrollBarTrack"))
        end
        
        -- Draw scrollbar handle
        local handlePos = math.floor((scrollIndex - 1) * (height - 2) / maxScroll) + 1
        term.setCursorPos(x + width - 1, y + handlePos)
        setBackgroundColor(theme.getColor("scrollHandle"))
        term.write(theme.getBorder("scrollBarHandle"))
    end
    
    setBackgroundColor(oldBg)
    setTextColor(oldFg)
    
    return scrollIndex
end

-- Draw tabs
function theme.drawTabs(x, y, width, tabs, activeTab)
    local oldBg = term.getBackgroundColor()
    local oldFg = term.getTextColor()
    
    local currentX = x
    for i, tab in ipairs(tabs) do
        local isActive = i == activeTab
        local tabWidth = #tab + 2
        
        -- Draw tab background
        setBackgroundColor(theme.getColor(isActive and "tabActive" or "tabInactive"))
        setTextColor(theme.getColor(isActive and "tabTextActive" or "tabTextInactive"))
        
        -- Draw tab
        term.setCursorPos(currentX, y)
        term.write(" " .. tab .. " ")
        
        -- Draw separator unless it's the last tab
        if i < #tabs then
            setTextColor(theme.getColor("border"))
            term.write(theme.getBorder("tabSeparator"))
        end
        
        currentX = currentX + tabWidth + 1
    end
    
    -- Draw bottom line for inactive tabs
    setBackgroundColor(theme.getColor("tabActive"))
    term.setCursorPos(x, y + 1)
    term.write(string.rep(" ", width))
    
    setBackgroundColor(oldBg)
    setTextColor(oldFg)
end

-- Draw a dropdown menu
function theme.drawDropdown(x, y, width, items, selectedIndex, isOpen)
    local oldBg = term.getBackgroundColor()
    local oldFg = term.getTextColor()
    
    -- Draw selected item
    theme.drawBox(x, y, width, 1)
    theme.drawMenuItem(x + 1, y, items[selectedIndex] .. " ▼", false)
    
    -- Draw dropdown list if open
    if isOpen then
        theme.drawBox(x, y + 1, width, #items)
        for i, item in ipairs(items) do
            theme.drawMenuItem(x + 1, y + i, item, i == selectedIndex)
        end
    end
    
    setBackgroundColor(oldBg)
    setTextColor(oldFg)
end

-- Draw a checkbox
function theme.drawCheckbox(x, y, text, checked)
    local oldBg = term.getBackgroundColor()
    local oldFg = term.getTextColor()
    
    -- Draw checkbox
    setBackgroundColor(theme.getColor("windowBg"))
    setTextColor(theme.getColor("text"))
    term.setCursorPos(x, y)
    term.write("[" .. (checked and "X" or " ") .. "] " .. text)
    
    setBackgroundColor(oldBg)
    setTextColor(oldFg)
    
    return {
        x1 = x,
        x2 = x + #text + 4,
        y = y,
        checked = checked
    }
end

-- Draw a radio button
function theme.drawRadio(x, y, text, selected)
    local oldBg = term.getBackgroundColor()
    local oldFg = term.getTextColor()
    
    -- Draw radio button
    setBackgroundColor(theme.getColor("windowBg"))
    setTextColor(theme.getColor("text"))
    term.setCursorPos(x, y)
    term.write("(" .. (selected and "•" or " ") .. ") " .. text)
    
    setBackgroundColor(oldBg)
    setTextColor(oldFg)
    
    return {
        x1 = x,
        x2 = x + #text + 4,
        y = y,
        selected = selected
    }
end

-- Draw a tooltip
function theme.drawTooltip(x, y, text)
    local width = #text + 2
    local oldBg = term.getBackgroundColor()
    local oldFg = term.getTextColor()
    
    -- Draw tooltip box
    theme.drawBox(x, y, width, 3)
    
    -- Draw tooltip text
    setBackgroundColor(theme.getColor("windowBg"))
    setTextColor(theme.getColor("text"))
    term.setCursorPos(x + 1, y + 1)
    term.write(text)
    
    setBackgroundColor(oldBg)
    setTextColor(oldFg)
end

-- Clear screen while maintaining theme
function theme.clear()
    local contentWindow = theme.getContentWindow()
    contentWindow.setBackgroundColor(theme.getColor("background"))
    contentWindow.clear()
    contentWindow.setCursorPos(1, 1)
    theme.drawTitleBar()
end

-- Get the shell cursor position
function theme.getShellStartPos()
    return 1, 2 -- X, Y coordinates where shell should start
end

-- Initialize shell environment
function theme.initShell()
    if theme.isLoginScreen then return end
    
    local x, y = theme.getShellStartPos()
    term.setCursorPos(x, y)
    term.setBackgroundColor(currentColors.background)
    term.setTextColor(currentColors.text)
    term.clearLine()
    term.write("> ")
end

-- Draw a fancy logo as a title bar
function theme.drawLogo()
    local current = term.current()
    local w, _ = current.getSize()
    local logoText = "SCI Sentinel"
    local centerX = math.floor((w - #logoText) / 2)
    
    -- Save current colors
    local oldBg = term.getBackgroundColor()
    local oldFg = term.getTextColor()
    
    -- Set logo colors
    term.setBackgroundColor(theme.getColor("titleBar"))
    term.setTextColor(theme.getColor("titleText"))
    
    -- Draw the logo with a simple animation effect
    for i = 1, #logoText do
        term.setCursorPos(centerX + i - 1, 1)
        term.write(logoText:sub(i, i))
        os.sleep(0.1)  -- Small delay for animation effect
    end
    
    -- Restore original colors
    term.setBackgroundColor(oldBg)
    term.setTextColor(oldFg)
end

-- Draw the persistent title bar
function theme.drawPersistentTitleBar(title)
    local current = term.current()
    local w, h = current.getSize()
    local logoText = "SCI Sentinel OS"
    local centerX = math.floor((w - #logoText) / 2)
    
    -- Save current colors
    local oldBg = term.getBackgroundColor()
    local oldFg = term.getTextColor()
    
    -- Set logo colors
    term.setBackgroundColor(theme.getColor("titleBar"))
    term.setTextColor(theme.getColor("titleText"))
    
    -- Clear the first line
    term.setCursorPos(1, 1)
    term.write(string.rep(" ", w))
    
    -- Draw centered logo
    term.setCursorPos(centerX, 1)
    term.write(logoText)
    
    -- Restore original colors
    term.setBackgroundColor(oldBg)
    term.setTextColor(oldFg)
end

-- Draw the MS-DOS style blinking cursor
function theme.drawMSDOSCursor()
    local w, h = term.getSize()
    local cursorChar = "_"
    local blinkInterval = 0.5  -- Half-second blink
    
    -- Ensure we're using a valid terminal
    if not term or not term.getSize then
        ErrorHandler.logError("Theme", "Invalid terminal for cursor drawing")
        return
    end
    
    while true do
        -- Protect against terminal errors
        local success, err = pcall(function()
            term.setCursorPos(1, h)
            term.setTextColor(colors.white)
            term.write(cursorChar)
        end)
        
        if not success then
            ErrorHandler.logError("Theme", "Error drawing cursor: " .. tostring(err))
            break
        end
        
        os.sleep(blinkInterval)
        
        -- Protect against terminal errors
        success, err = pcall(function()
            term.setCursorPos(1, h)
            term.write(" ")
        end)
        
        if not success then
            ErrorHandler.logError("Theme", "Error clearing cursor: " .. tostring(err))
            break
        end
        
        os.sleep(blinkInterval)
    end
end

-- Wrapper function to start cursor in a separate coroutine
function theme.startMSDOSCursor()
    return coroutine.create(theme.drawMSDOSCursor)
end

-- Return the theme module
ErrorHandler.logError("Theme", "Theme module loaded successfully")

local function validateTheme(theme)
    -- Perform comprehensive validation of the theme module
    local requiredMethods = {
        "getColor", "drawTitleBar", "loadTheme", "clear"
    }
    
    for _, method in ipairs(requiredMethods) do
        if type(theme[method]) ~= "function" then
            error("Theme module missing required method: " .. method)
        end
    end
    
    return theme
end

-- Validate and return theme
return validateTheme(theme)
