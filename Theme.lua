-- SCI Sentinel Theme Module
local theme = {}

-- Default retro purple theme
local defaultTheme = {
    -- Main colors
    primary = colors.purple,
    secondary = colors.magenta,
    background = colors.black,
    text = colors.white,
    
    -- UI Elements
    header = colors.purple,
    headerText = colors.white,
    footer = colors.purple,
    footerText = colors.white,
    
    -- Interactive elements
    button = colors.purple,
    buttonText = colors.white,
    buttonHover = colors.magenta,
    
    -- Messages and alerts
    success = colors.lime,
    warning = colors.yellow,
    error = colors.red,
    info = colors.lightBlue
}

local currentTheme = {}

-- Initialize theme with defaults
function theme.init()
    for k, v in pairs(defaultTheme) do
        currentTheme[k] = v
    end
end

-- Get current theme
function theme.get()
    return currentTheme
end

-- Get specific theme color
function theme.getColor(colorName)
    return currentTheme[colorName] or defaultTheme[colorName] or colors.white
end

-- Set a custom theme
function theme.set(newTheme)
    for k, v in pairs(newTheme) do
        currentTheme[k] = v
    end
end

-- Reset to default theme
function theme.reset()
    theme.init()
end

-- Initialize with default theme
theme.init()

return theme
