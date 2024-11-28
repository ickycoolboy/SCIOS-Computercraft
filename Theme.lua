-- SCI Sentinel Theme Module
local theme = {}

-- Direct color definitions
local defaultColors = {
    titleBar = colors.purple,
    titleText = colors.white,
    windowBg = colors.black,
    text = colors.white,
    systemText = colors.white,
    systemBg = colors.black,
    systemAccent = colors.purple,
    success = colors.lime,
    warning = colors.yellow,
    error = colors.red,
    info = colors.lightBlue,
    menuBg = colors.black,
    menuText = colors.white,
    menuSelect = colors.purple,
    menuSelectText = colors.white,
    contentBg = nil,
    contentText = nil,
    buttonBg = colors.purple,
    buttonText = colors.white,
    buttonHover = colors.magenta,
    scrollBg = colors.gray,
    scrollHandle = colors.purple,
    tabActive = colors.purple,
    tabInactive = colors.gray,
    tabTextActive = colors.white,
    tabTextInactive = colors.lightGray,
    background = colors.black,  -- Add explicit background color
    progressBg = colors.gray,  -- Add explicit progress background color
    progressBar = colors.purple,  -- Add explicit progress bar color
    border = colors.gray,  -- Add explicit border color
    dimText = colors.gray  -- Add explicit dim text color
}

-- Get color from theme
function theme.getColor(name)
    return defaultColors[name] or colors.white
end

-- Draw a simple window
function theme.drawBox(x, y, width, height, title)
    -- Draw title bar
    term.setBackgroundColor(colors.purple)
    term.setTextColor(colors.white)
    
    -- Fill entire title bar
    for i = 0, height - 1 do
        term.setCursorPos(x, y + i)
        if i == 0 then
            term.setBackgroundColor(colors.purple)
        else
            term.setBackgroundColor(colors.black)
        end
        term.write(string.rep(" ", width))
    end
    
    -- Write title if provided
    if title then
        local titleX = x + math.floor((width - #title) / 2)
        term.setCursorPos(titleX, y)
        term.setBackgroundColor(colors.purple)
        term.setTextColor(colors.white)
        term.write(title)
    end
end

-- Initialize theme
function theme.init()
    if not term.isColor() then
        -- Fallback to monochrome if needed
        defaultColors.titleBar = colors.gray
        defaultColors.titleText = colors.white
        defaultColors.windowBg = colors.black
        defaultColors.text = colors.white
        defaultColors.background = colors.black
    end
    
    -- Clear screen with theme colors
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.clear()
end

-- Apply theme to a window
function theme.applyWindow(window)
    if window then
        window.setBackgroundColor(defaultColors.background)
        window.setTextColor(defaultColors.text)
        window.clear()
    end
end

-- Screen resolution management
local screen = {
    width = 0,
    height = 0,
    isColor = false,
    mode = "normal", -- normal, compact, or expanded
    scale = 1
}

-- Initialize screen properties
local function initScreen()
    -- Get terminal properties
    screen.width, screen.height = term.getSize()
    screen.isColor = term.isColor()
    
    -- Check if we're on an advanced computer or monitor
    if term.native then
        local native = term.native()
        screen.isAdvanced = native.isColor()
    end
    
    -- Set appropriate mode based on screen size
    if screen.height <= 13 then
        screen.mode = "compact"    -- Pocket computer or small screen
    elseif screen.height >= 25 then
        screen.mode = "expanded"   -- Advanced computer or monitor
    else
        screen.mode = "normal"     -- Standard computer
    end
    
    -- Adjust scale for different modes
    if screen.mode == "compact" then
        screen.scale = 0.75
    elseif screen.mode == "expanded" then
        screen.scale = 1.5
    else
        screen.scale = 1
    end
end

-- Current active theme
local currentTheme = {}

-- Get the current theme
function theme.get()
    return currentTheme
end

-- Get a border character
function theme.getBorder(borderName)
    return currentTheme.borders[screen.mode][borderName] or " "
end

-- Apply a new theme
function theme.apply(newTheme)
    if type(newTheme) == "table" then
        -- Merge with default theme to ensure all properties exist
        currentTheme = {}
        for k, v in pairs(defaultTheme) do
            if type(v) == "table" then
                currentTheme[k] = {}
                for subK, subV in pairs(v) do
                    currentTheme[k][subK] = newTheme[k] and newTheme[k][subK] or subV
                end
            else
                currentTheme[k] = newTheme[k] or v
            end
        end
    end
end

-- Reset to default theme
function theme.reset()
    theme.apply(defaultTheme)
end

-- Get current screen properties
function theme.getScreen()
    return screen
end

-- Set terminal mode
function theme.setMode(mode)
    if mode == "compact" or mode == "normal" or mode == "expanded" then
        screen.mode = mode
        -- Reinitialize screen properties
        initScreen()
    end
end

-- Get layout settings for current mode
function theme.getLayout()
    return defaultTheme.layout[screen.mode]
end

-- Scale a dimension based on current mode
function theme.scale(size)
    return math.floor(size * screen.scale)
end

-- Draw a themed box
function theme.drawCompactHeader(text)
    local oldBg = term.getBackgroundColor()
    local oldFg = term.getTextColor()
    
    term.setBackgroundColor(theme.getColor("titleBar"))
    term.setTextColor(theme.getColor("titleText"))
    term.setCursorPos(1, 1)
    
    -- Create shortened text if needed
    local maxWidth = screen.width - 2
    local displayText = #text > maxWidth and text:sub(1, maxWidth-3) .. "..." or text
    
    -- Center the text
    local padding = math.floor((screen.width - #displayText) / 2)
    term.write(string.rep(" ", padding) .. displayText .. string.rep(" ", screen.width - padding - #displayText))
    
    term.setBackgroundColor(oldBg)
    term.setTextColor(oldFg)
end

-- Draw a themed button
function theme.drawButton(x, y, text, active)
    local oldBg = term.getBackgroundColor()
    local oldFg = term.getTextColor()
    
    local bg = active and theme.getColor("buttonHover") or theme.getColor("buttonBg")
    term.setBackgroundColor(bg)
    term.setTextColor(theme.getColor("buttonText"))
    
    term.setCursorPos(x, y)
    term.write(" " .. text .. " ")
    
    term.setBackgroundColor(oldBg)
    term.setTextColor(oldFg)
    
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
    term.setBackgroundColor(bg)
    term.setTextColor(theme.getColor("buttonText"))
    
    -- Shorten text if needed
    local maxWidth = 5
    local displayText = #text > maxWidth and text:sub(1, maxWidth-2) .. ">" or text
    
    term.setCursorPos(x, y)
    term.write(displayText)
    
    term.setBackgroundColor(oldBg)
    term.setTextColor(oldFg)
    
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
    term.setBackgroundColor(theme.getColor("progressBg"))
    term.setCursorPos(x, y)
    term.write(string.rep(" ", width))
    
    -- Draw progress
    local fillWidth = math.floor(progress * width)
    if fillWidth > 0 then
        term.setBackgroundColor(theme.getColor("progressBar"))
        term.setCursorPos(x, y)
        term.write(string.rep(" ", fillWidth))
    end
    
    -- Draw text if provided
    if text then
        local textX = x + math.floor((width - #text) / 2)
        term.setCursorPos(textX, y)
        term.setTextColor(theme.getColor("text"))
        term.write(text)
    end
    
    term.setBackgroundColor(oldBg)
    term.setTextColor(oldFg)
end

-- Draw a menu item
function theme.drawMenuItem(x, y, text, selected, disabled)
    local oldBg = term.getBackgroundColor()
    local oldFg = term.getTextColor()
    
    if selected then
        term.setBackgroundColor(theme.getColor("menuSelect"))
        term.setTextColor(theme.getColor("menuSelectText"))
    else
        term.setBackgroundColor(theme.getColor("menuBg"))
        term.setTextColor(disabled and theme.getColor("dimText") or theme.getColor("menuText"))
    end
    
    term.setCursorPos(x, y)
    term.write(text)
    
    term.setBackgroundColor(oldBg)
    term.setTextColor(oldFg)
end

-- Draw a status message
function theme.drawStatus(x, y, text, status)
    local oldBg = term.getBackgroundColor()
    local oldFg = term.getTextColor()
    
    term.setCursorPos(x, y)
    term.setTextColor(theme.getColor(status or "text"))
    term.write(text)
    
    term.setBackgroundColor(oldBg)
    term.setTextColor(oldFg)
end

-- Draw a header
function theme.drawHeader(text, y)
    y = y or 1
    local width = term.getSize()
    local oldBg = term.getBackgroundColor()
    local oldFg = term.getTextColor()
    
    -- Draw header background
    term.setBackgroundColor(theme.getColor("titleBar"))
    term.setCursorPos(1, y)
    term.write(string.rep(" ", width))
    
    -- Draw header text
    local textX = math.floor((width - #text) / 2)
    term.setCursorPos(textX, y)
    term.setTextColor(theme.getColor("titleText"))
    term.write(text)
    
    term.setBackgroundColor(oldBg)
    term.setTextColor(oldFg)
end

-- Draw a separator line
function theme.drawSeparator(y, style)
    local width = term.getSize()
    local oldBg = term.getBackgroundColor()
    local oldFg = term.getTextColor()
    
    term.setTextColor(theme.getColor("border"))
    term.setCursorPos(1, y)
    term.write(string.rep(theme.getBorder(style or "headerSeparator"), width))
    
    term.setBackgroundColor(oldBg)
    term.setTextColor(oldFg)
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
            term.setBackgroundColor(theme.getColor("scrollBg"))
            term.setTextColor(theme.getColor("scrollHandle"))
            term.write(theme.getBorder("scrollBarTrack"))
        end
        
        -- Draw scrollbar handle
        local handlePos = math.floor((scrollIndex - 1) * (height - 2) / maxScroll) + 1
        term.setCursorPos(x + width - 1, y + handlePos)
        term.setBackgroundColor(theme.getColor("scrollHandle"))
        term.write(theme.getBorder("scrollBarHandle"))
    end
    
    term.setBackgroundColor(oldBg)
    term.setTextColor(oldFg)
    
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
        term.setBackgroundColor(theme.getColor(isActive and "tabActive" or "tabInactive"))
        term.setTextColor(theme.getColor(isActive and "tabTextActive" or "tabTextInactive"))
        
        -- Draw tab
        term.setCursorPos(currentX, y)
        term.write(" " .. tab .. " ")
        
        -- Draw separator unless it's the last tab
        if i < #tabs then
            term.setTextColor(theme.getColor("border"))
            term.write(theme.getBorder("tabSeparator"))
        end
        
        currentX = currentX + tabWidth + 1
    end
    
    -- Draw bottom line for inactive tabs
    term.setBackgroundColor(theme.getColor("tabActive"))
    term.setCursorPos(x, y + 1)
    term.write(string.rep(" ", width))
    
    term.setBackgroundColor(oldBg)
    term.setTextColor(oldFg)
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
    
    term.setBackgroundColor(oldBg)
    term.setTextColor(oldFg)
end

-- Draw a checkbox
function theme.drawCheckbox(x, y, text, checked)
    local oldBg = term.getBackgroundColor()
    local oldFg = term.getTextColor()
    
    -- Draw checkbox
    term.setBackgroundColor(theme.getColor("windowBg"))
    term.setTextColor(theme.getColor("text"))
    term.setCursorPos(x, y)
    term.write("[" .. (checked and "X" or " ") .. "] " .. text)
    
    term.setBackgroundColor(oldBg)
    term.setTextColor(oldFg)
    
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
    term.setBackgroundColor(theme.getColor("windowBg"))
    term.setTextColor(theme.getColor("text"))
    term.setCursorPos(x, y)
    term.write("(" .. (selected and "•" or " ") .. ") " .. text)
    
    term.setBackgroundColor(oldBg)
    term.setTextColor(oldFg)
    
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
    term.setBackgroundColor(theme.getColor("windowBg"))
    term.setTextColor(theme.getColor("text"))
    term.setCursorPos(x + 1, y + 1)
    term.write(text)
    
    term.setBackgroundColor(oldBg)
    term.setTextColor(oldFg)
end

-- Resolution controls
function theme.handleKey(key)
    if key == keys.leftCtrl then
        theme.ctrlPressed = true
    elseif theme.ctrlPressed then
        if key == keys.equals then
            term.setTextScale(0.5)
        elseif key == keys.minus then
            term.setTextScale(2)
        end
    end
end

function theme.keyUp(key)
    if key == keys.leftCtrl then
        theme.ctrlPressed = false
    end
end

-- Show help message
function theme.showResolutionHelp()
    local w, h = term.getSize()
    local msg = "Press Ctrl + +/- to adjust screen size"
    term.setBackgroundColor(colors.titleBar)
    term.setTextColor(colors.titleText)
    term.setCursorPos(math.floor((w - #msg) / 2), h)
    term.write(msg)
end

-- Initialize screen on load
initScreen()

-- Initialize theme
theme.init()

return theme
