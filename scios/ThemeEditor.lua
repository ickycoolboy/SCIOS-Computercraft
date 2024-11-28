-- SCI Sentinel Theme Editor
local theme = require("Theme")
local gui = require("Gui")

local function drawBox(x, y, width, height, title)
    -- Draw double-line border characters
    local chars = {
        topLeft = "\x95",    -- ╔
        topRight = "\x89",   -- ╗
        bottomLeft = "\x8A", -- ╚
        bottomRight = "\x8B",-- ╝
        horizontal = "\x97", -- ═
        vertical = "\x95"    -- ║
    }
    
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.purple)
    
    -- Draw corners
    term.setCursorPos(x, y)
    write(chars.topLeft)
    term.setCursorPos(x + width - 1, y)
    write(chars.topRight)
    term.setCursorPos(x, y + height - 1)
    write(chars.bottomLeft)
    term.setCursorPos(x + width - 1, y + height - 1)
    write(chars.bottomRight)
    
    -- Draw horizontal borders
    for i = x + 1, x + width - 2 do
        term.setCursorPos(i, y)
        write(chars.horizontal)
        term.setCursorPos(i, y + height - 1)
        write(chars.horizontal)
    end
    
    -- Draw vertical borders
    for i = y + 1, y + height - 2 do
        term.setCursorPos(x, i)
        write(chars.vertical)
        term.setCursorPos(x + width - 1, i)
        write(chars.vertical)
    end
    
    -- Draw title if provided
    if title then
        term.setCursorPos(x + math.floor((width - #title) / 2) - 1, y)
        write(" " .. title .. " ")
    end
end

local function drawButton(x, y, text, isSelected)
    local width = #text + 2
    term.setCursorPos(x, y)
    
    if isSelected then
        term.setBackgroundColor(colors.purple)
        term.setTextColor(colors.white)
    else
        term.setBackgroundColor(colors.black)
        term.setTextColor(colors.purple)
    end
    
    write("[" .. text .. "]")
    
    return {
        x = x,
        y = y,
        width = width,
        height = 1
    }
end

local function drawColorPicker(x, y, width, height, title, selectedColor)
    drawBox(x, y, width, height, title)
    
    -- Draw color options
    local colorButtons = {}
    local row, col = 0, 0
    for name, color in pairs(colors) do
        if type(color) == "number" then
            local bx = x + 2 + (col * 8)
            local by = y + 2 + row
            
            -- Draw color box with border
            term.setCursorPos(bx, by)
            term.setBackgroundColor(color)
            write("      ")
            term.setBackgroundColor(colors.black)
            term.setTextColor(colors.purple)
            write("\x95") -- Right border
            
            if row == 0 then
                term.setCursorPos(bx, by - 1)
                write("\x97\x97\x97\x97\x97\x97\x97") -- Top border
            end
            
            -- Add to clickable areas
            table.insert(colorButtons, {
                x = bx,
                y = by,
                width = 6,
                color = color,
                name = name
            })
            
            col = col + 1
            if col >= 4 then
                col = 0
                row = row + 1
            end
        end
    end
    
    return colorButtons
end

local function drawThemeEditor()
    local w, h = term.getSize()
    
    -- Clear screen with retro pattern
    term.setBackgroundColor(colors.black)
    term.clear()
    term.setTextColor(colors.purple)
    for y = 1, h do
        for x = 1, w, 2 do
            term.setCursorPos(x, y)
            write("\x8F") -- Dot character
        end
    end
    
    -- Draw main interface box
    drawBox(1, 1, w, h, " SCI Sentinel Theme Editor ")
    
    -- Draw inner content box
    drawBox(3, 3, w-4, h-6, " Color Settings ")
    
    -- Get current theme colors
    local currentColors = theme.getColors()
    local colorNames = theme.getColorNames()
    
    -- Draw color options
    local buttons = {}
    for i, name in ipairs(colorNames) do
        local y = 5 + (i * 2)
        term.setCursorPos(5, y)
        term.setTextColor(colors.white)
        write(name .. ": ")
        term.setBackgroundColor(currentColors[name])
        write("     ")
        term.setBackgroundColor(colors.black)
        
        -- Add to clickable areas
        table.insert(buttons, {
            x = 5,
            y = y,
            width = #name + 7,
            height = 1,
            type = "color",
            name = name
        })
    end
    
    -- Draw buttons at bottom
    local buttonY = h - 3
    local saveBtn = drawButton(5, buttonY, "Save", false)
    table.insert(buttons, {x = saveBtn.x, y = buttonY, width = saveBtn.width, height = 1, type = "save"})
    
    local resetBtn = drawButton(15, buttonY, "Reset", false)
    table.insert(buttons, {x = resetBtn.x, y = buttonY, width = resetBtn.width, height = 1, type = "reset"})
    
    local exitBtn = drawButton(25, buttonY, "Exit", false)
    table.insert(buttons, {x = exitBtn.x, y = buttonY, width = exitBtn.width, height = 1, type = "exit"})
    
    return buttons
end

local function handleClick(x, y, buttons)
    for _, button in ipairs(buttons) do
        if x >= button.x and x < button.x + button.width and
           y >= button.y and y < button.y + (button.height or 1) then
            return button
        end
    end
    return nil
end

-- Main loop
local function main()
    while true do
        local buttons = drawThemeEditor()
        
        local event, button, clickX, clickY = os.pullEvent("mouse_click")
        local clicked = handleClick(clickX, clickY, buttons)
        
        if clicked then
            if clicked.type == "color" then
                -- Show color picker
                local colorButtons = drawColorPicker(5, 5, 35, 15, "Choose Color", theme.getColor(clicked.name))
                local event, button, x, y = os.pullEvent("mouse_click")
                local selectedColor = handleClick(x, y, colorButtons)
                
                if selectedColor then
                    theme.setColor(clicked.name, selectedColor.color)
                end
                
            elseif clicked.type == "save" then
                theme.saveTheme()
                theme.drawInterface()
                term.setCursorPos(2, 2)
                term.setTextColor(colors.lime)
                write("Theme saved!")
                os.sleep(1)
                
            elseif clicked.type == "reset" then
                theme.resetToDefaults()
                theme.drawInterface()
                term.setCursorPos(2, 2)
                term.setTextColor(colors.yellow)
                write("Theme reset to defaults!")
                os.sleep(1)
                
            elseif clicked.type == "exit" then
                theme.drawInterface()
                return
            end
        end
    end
end

-- Return the module
return {
    run = main
}
