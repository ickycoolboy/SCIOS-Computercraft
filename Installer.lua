-- SCI Sentinel OS Installer
local version = "1.2.0"

-- Embedded GUI module for installer
local gui = {
    colors = {
        background = colors.blue,
        windowBg = colors.lightGray,
        text = colors.white,
        border = colors.white,
        shadow = colors.black,
        buttonBg = colors.lightGray,
        buttonText = colors.black,
        titleBar = colors.blue,
        titleText = colors.white,
        progressBar = colors.lime,
        progressBg = colors.gray
    }
}

-- Draw a Windows 9x style window
function gui.drawWindow(x, y, width, height, title)
    -- Background
    local oldBg = term.getBackgroundColor()
    local oldFg = term.getTextColor()
    
    -- Draw shadow
    term.setBackgroundColor(gui.colors.shadow)
    for i = 1, height do
        term.setCursorPos(x + width, y + i)
        write(" ")
    end
    for i = 1, width do
        term.setCursorPos(x + i, y + height)
        write(" ")
    end
    
    -- Draw main window
    term.setBackgroundColor(gui.colors.windowBg)
    for i = 1, height-1 do
        term.setCursorPos(x, y + i - 1)
        write(string.rep(" ", width-1))
    end
    
    -- Draw title bar
    term.setBackgroundColor(gui.colors.titleBar)
    term.setCursorPos(x, y)
    write(string.rep(" ", width-1))
    
    -- Draw title
    term.setCursorPos(x + 1, y)
    term.setTextColor(gui.colors.titleText)
    write(" " .. title .. " ")
    
    -- Reset colors
    term.setBackgroundColor(oldBg)
    term.setTextColor(oldFg)
end

-- Draw a Windows 9x style button
function gui.drawButton(x, y, width, text, active)
    local oldBg = term.getBackgroundColor()
    local oldFg = term.getTextColor()
    
    -- Button background
    term.setBackgroundColor(gui.colors.buttonBg)
    term.setCursorPos(x, y)
    write(string.rep(" ", width))
    
    -- Button text
    term.setTextColor(gui.colors.buttonText)
    term.setCursorPos(x + math.floor((width - #text) / 2), y)
    write(text)
    
    -- Button border
    if active then
        term.setTextColor(colors.black)
        term.setCursorPos(x, y)
        write("▄")
        term.setCursorPos(x + width - 1, y)
        write("▄")
    end
    
    term.setBackgroundColor(oldBg)
    term.setTextColor(oldFg)
end

-- Draw a Windows 9x style progress bar with animation
function gui.drawAnimatedProgressBar(x, y, width, text, progress)
    local oldBg = term.getBackgroundColor()
    local oldFg = term.getTextColor()
    
    -- Progress bar background
    term.setBackgroundColor(gui.colors.progressBg)
    term.setCursorPos(x, y)
    write(string.rep(" ", width))
    
    -- Progress fill
    local fillWidth = math.floor(progress * width)
    if fillWidth > 0 then
        term.setBackgroundColor(gui.colors.progressBar)
        term.setCursorPos(x, y)
        write(string.rep(" ", fillWidth))
    end
    
    -- Progress text
    if text then
        term.setCursorPos(x, y - 1)
        term.setBackgroundColor(gui.colors.windowBg)
        term.setTextColor(gui.colors.text)
        write(text)
    end
    
    -- Percentage
    local percent = math.floor(progress * 100)
    term.setCursorPos(x + width + 1, y)
    term.setBackgroundColor(gui.colors.windowBg)
    term.setTextColor(gui.colors.text)
    write(percent .. "%")
    
    term.setBackgroundColor(oldBg)
    term.setTextColor(oldFg)
end

-- First, ensure we have the GUI module
-- if not fs.exists("Gui.lua") then
--     print("Downloading GUI module...")
--     local response = http.get("https://raw.githubusercontent.com/ickycoolboy/SCIOS-Computercraft/Github-updating-test/Gui.lua")
--     if response then
--         local content = response.readAll()
--         response.close()
--         local file = fs.open("Gui.lua", "w")
--         file.write(content)
--         file.close()
--     else
--         error("Failed to download GUI module. Please check your internet connection.")
--     end
-- end

-- local gui = require("Gui")

-- Fun loading messages
local loading_messages = {
    "Downloading more RAM...",
    "Reticulating splines...",
    "Converting caffeine to code...",
    "Generating witty dialog...",
    "Swapping time and space...",
    "Spinning violently around the y-axis...",
    "Tokenizing real life...",
    "Bending the spoon...",
    "Filtering morale...",
    "Don't think of purple hippos...",
    "Solving for X...",
    "Dividing by zero...",
    "Debugging the universe...",
    "Loading your digital future...",
    "Preparing to turn it off and on again..."
}

-- Configuration
local config = {
    repo_owner = "ickycoolboy",
    repo_name = "SCIOS-Computercraft",
    branch = "Github-updating-test",
    install_dir = "scios",
    modules = {
        {name = "Core", file = "Sci_sentinel.lua", target = "scios/Sci_sentinel.lua", required = true},
        {name = "GUI", file = "Gui.lua", target = "scios/Gui.lua", required = true},
        {name = "Commands", file = "Commands.lua", target = "scios/Commands.lua", required = true},
        {name = "Updater", file = "Updater.lua", target = "scios/Updater.lua", required = true},
        {name = "Login", file = "Login.lua", target = "scios/Login.lua", required = true},
        {name = "DisplayManager", file = "DisplayManager.lua", target = "scios/DisplayManager.lua", required = true},
        {name = "Network", file = "Network.lua", target = "scios/Network.lua", required = true},
        {name = "Help", file = "Help.lua", target = "scios/Help.lua", required = true}
    },
    root_files = {
        {name = "Startup", file = "Startup.lua", target = "startup.lua", required = true},
        {name = "Installer", file = "Installer.lua", target = "Installer.lua", required = false}
    }
}

-- Installation steps
local steps = {
    {name = "Welcome", description = "Welcome to SCI Sentinel OS Installation"},
    {name = "License", description = "Please review the license agreement"},
    {name = "Components", description = "Choose components to install"},
    {name = "Installing", description = "Installing SCI Sentinel OS..."},
    {name = "Complete", description = "Installation complete!"}
}

local currentStep = 1
local screen = {width = 0, height = 0}

-- Initialize screen
local function initScreen()
    screen.width, screen.height = term.getSize()
    term.setBackgroundColor(gui.colors.background)
    term.clear()
end

-- Draw installation wizard
local function drawInstallationWizard()
    -- Draw main window
    gui.drawWindow(2, 2, screen.width - 2, screen.height - 2, "SCI Sentinel OS Installation")
    
    -- Draw step title
    term.setBackgroundColor(gui.colors.windowBg)
    term.setTextColor(gui.colors.text)
    term.setCursorPos(4, 4)
    write(steps[currentStep].name)
    term.setCursorPos(4, 5)
    write(steps[currentStep].description)
    
    -- Draw navigation buttons
    if currentStep > 1 then
        gui.drawButton(screen.width - 20, screen.height - 4, 8, "< Back", false)
    end
    if currentStep < #steps then
        gui.drawButton(screen.width - 10, screen.height - 4, 8, "Next >", true)
    end
end

-- Show a random loading message with animation
local function showLoadingMessage()
    local msg = loading_messages[math.random(1, #loading_messages)]
    term.setBackgroundColor(gui.colors.windowBg)
    term.setTextColor(gui.colors.text)
    term.setCursorPos(4, screen.height - 6)
    write(string.rep(" ", screen.width - 8))  -- Clear previous message
    term.setCursorPos(4, screen.height - 6)
    write(msg)
end

-- Draw installation progress
local function drawProgress(current, total, message)
    local progress = current / total
    gui.drawAnimatedProgressBar(4, screen.height - 4, screen.width - 8, message, progress)
end

-- Create GitHub raw URL
local function getGitHubRawURL(filepath)
    return string.format("https://raw.githubusercontent.com/%s/%s/%s/%s?cb=%d",
        config.repo_owner,
        config.repo_name,
        config.branch,
        filepath,
        os.epoch("utc")) 
end

-- Safe file write function for ComputerCraft
local function safeWrite(path, content)
    if fs.exists(path) then
        local tries = 0
        while tries < 3 do
            if pcall(fs.delete, path) then
                break
            end
            tries = tries + 1
            os.sleep(0.5)  
        end
    end
    
    local tries = 0
    while tries < 3 do
        local file = fs.open(path, "w")
        if file then
            file.write(content)
            file.close()
            return true
        end
        tries = tries + 1
        os.sleep(0.5)  
    end
    return false
end

-- Download a file from GitHub
local function downloadFile(url, path)
    print(string.format("Downloading from: %s", url))
    local response = http.get(url)
    if response then
        local content = response.readAll()
        response.close()
        
        if not fs.getName(path) == path then
            local dir = fs.getDir(path)
            if dir and dir ~= "" and not fs.exists(dir) then
                fs.makeDir(dir)
            end
        end
        
        if safeWrite(path, content) then
            return true, content
        end
    end
    return false
end

-- Check for installer updates
local function checkInstallerUpdate()
    local installerPath = shell.getRunningProgram()
    local url = getGitHubRawURL("Installer.lua")
    local tempPath = "installer_update.tmp"
    local success, content = downloadFile(url, tempPath)
    
    if success then
        local currentFile = fs.open(installerPath, "r")
        local currentContent = currentFile.readAll()
        currentFile.close()
        
        if content ~= currentContent then
            print("Installer update available.")
            print("The installer will be updated on next run.")
            print("Please run the installer again after this installation completes.")
            
            local markerFile = fs.open("installer_update_pending", "w")
            markerFile.write("pending")
            markerFile.close()
            
            return true
        else
            fs.delete(tempPath)
            return false
        end
    end
    return false
end

-- Check for pending updates from previous run
local function handlePendingUpdate()
    if fs.exists("installer_update_pending") and fs.exists("installer_update.tmp") then
        local installerPath = shell.getRunningProgram()
        print("Applying pending installer update...")
        
        fs.delete(installerPath)
        fs.move("installer_update.tmp", installerPath)
        fs.delete("installer_update_pending")
        
        print("Installer updated. Restarting...")
        os.sleep(1)
        os.reboot()
    end
end

-- Main installation process
local function install()
    initScreen()
    
    while currentStep <= #steps do
        drawInstallationWizard()
        
        if currentStep == 1 then
            -- Welcome screen
            term.setCursorPos(4, 7)
            term.setBackgroundColor(gui.colors.windowBg)
            term.setTextColor(gui.colors.text)
            write("Welcome to SCI Sentinel OS Installation Wizard")
            term.setCursorPos(4, 9)
            write("This wizard will guide you through the installation")
            term.setCursorPos(4, 10)
            write("of SCI Sentinel OS version " .. version)
            
        elseif currentStep == 2 then
            -- License screen
            term.setCursorPos(4, 7)
            term.setBackgroundColor(gui.colors.windowBg)
            term.setTextColor(gui.colors.text)
            write("By continuing, you agree to the terms of use")
            
        elseif currentStep == 3 then
            -- Components selection
            term.setCursorPos(4, 7)
            term.setBackgroundColor(gui.colors.windowBg)
            term.setTextColor(gui.colors.text)
            write("The following components will be installed:")
            
            for i, module in ipairs(config.modules) do
                term.setCursorPos(6, 8 + i)
                write("[ ] " .. module.name)
            end
            
        elseif currentStep == 4 then
            -- Installation progress
            local totalFiles = #config.modules + #config.root_files
            local filesInstalled = 0
            
            for _, module in ipairs(config.modules) do
                showLoadingMessage()
                drawProgress(filesInstalled / totalFiles, "Installing: " .. module.name)
                -- Download and install module
                local success = downloadFile(getGitHubRawURL(module.file), module.target)
                if not success and module.required then
                    print("\nFailed to download " .. module.name .. " module")
                    print("Installation failed! (Have you tried turning it off and on again?)")
                    return
                end
                filesInstalled = filesInstalled + 1
                os.sleep(0.5)  -- Add slight delay for visual effect
            end
            
            for _, file in ipairs(config.root_files) do
                showLoadingMessage()
                drawProgress(filesInstalled / totalFiles, "Installing: " .. file.name)
                -- Download and install file
                local success = downloadFile(getGitHubRawURL(file.file), file.target)
                if not success and file.required then
                    print("\nFailed to download " .. file.name)
                    print("Installation failed! (Error 404: Success not found)")
                    return
                end
                filesInstalled = filesInstalled + 1
                os.sleep(0.5)  -- Add slight delay for visual effect
            end
            
            currentStep = currentStep + 1
            
        elseif currentStep == 5 then
            -- Complete screen
            term.setCursorPos(4, 7)
            term.setBackgroundColor(gui.colors.windowBg)
            term.setTextColor(gui.colors.text)
            write("Installation Complete!")
            term.setCursorPos(4, 9)
            write("SCI Sentinel OS has been successfully installed.")
            term.setCursorPos(4, 10)
            write("Press any key to restart...")
            os.pullEvent("key")
            os.reboot()
        end
        
        -- Wait for user input
        local event, button, x, y = os.pullEvent("mouse_click")
        
        -- Handle navigation buttons
        if y == screen.height - 4 then
            if currentStep > 1 and x >= screen.width - 20 and x < screen.width - 12 then
                currentStep = currentStep - 1
            elseif currentStep < #steps and x >= screen.width - 10 and x < screen.width - 2 then
                currentStep = currentStep + 1
            end
        end
    end
end

-- Main entry point
handlePendingUpdate()
install()
