-- SCI Sentinel Theme Editor
local theme = require("Theme")
local gui = require("Gui")

local function drawColorPicker(x, y, width, height, title, selectedColor)
    -- Draw window
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    
    -- Draw border
    for i = y, y + height - 1 do
        term.setCursorPos(x, i)
        write("|")
        term.setCursorPos(x + width - 1, i)
        write("|")
    end
    
    term.setCursorPos(x, y)
    write("+" .. string.rep("-", width - 2) .. "+")
    term.setCursorPos(x, y + height - 1)
    write("+" .. string.rep("-", width - 2) .. "+")
    
    -- Draw title
    term.setCursorPos(x + 2, y)
    write(" " .. title .. " ")
    
    -- Draw color options
    local colorButtons = {}
    local row, col = 0, 0
    for name, color in pairs(colors) do
        if type(color) == "number" then
            local bx = x + 2 + (col * 8)
            local by = y + 2 + row
            
            -- Draw color button
            term.setCursorPos(bx, by)
            term.setBackgroundColor(color)
            write("      ")
            
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
    
    -- Reset colors
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    
    return colorButtons
end

local function drawThemeEditor()
    local w, h = term.getSize()
    
    -- Clear screen
    term.setBackgroundColor(colors.black)
    term.clear()
    
    -- Draw title
    term.setCursorPos(2, 1)
    term.setTextColor(colors.purple)
    write("SCI Sentinel Theme Editor")
    
    -- Get current theme colors
    local currentColors = theme.getColors()
    local colorNames = theme.getColorNames()
    
    -- Draw color options
    local buttons = {}
    for i, name in ipairs(colorNames) do
        local y = 3 + (i * 2)
        term.setCursorPos(2, y)
        term.setTextColor(colors.white)
        write(name .. ": ")
        term.setBackgroundColor(currentColors[name])
        write("     ")
        
        -- Add to clickable areas
        table.insert(buttons, {
            x = 2,
            y = y,
            width = #name + 7,
            height = 1,
            type = "color",
            name = name
        })
    end
    
    -- Draw buttons
    local buttonY = h - 3
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    
    -- Save button
    term.setCursorPos(2, buttonY)
    term.setBackgroundColor(colors.green)
    write(" Save ")
    table.insert(buttons, {
        x = 2,
        y = buttonY,
        width = 6,
        height = 1,
        type = "save"
    })
    
    -- Reset button
    term.setCursorPos(10, buttonY)
    term.setBackgroundColor(colors.red)
    write(" Reset ")
    table.insert(buttons, {
        x = 10,
        y = buttonY,
        width = 7,
        height = 1,
        type = "reset"
    })
    
    -- Exit button
    term.setCursorPos(19, buttonY)
    term.setBackgroundColor(colors.gray)
    write(" Exit ")
    table.insert(buttons, {
        x = 19,
        y = buttonY,
        width = 6,
        height = 1,
        type = "exit"
    })
    
    term.setBackgroundColor(colors.black)
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

main()
