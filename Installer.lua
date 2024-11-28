-- SCI Sentinel OS Installer
local version = "1.2.0"

-- Initialize screen dimensions immediately
local screen = {
    width = term.getSize(),
    height = term.getSize()
}

-- Update screen dimensions function
local function updateScreenDimensions()
    screen.width, screen.height = term.getSize()
end

-- Enhanced GUI module with theme support
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
        progressBg = colors.gray,
        highlight = colors.yellow,
        error = colors.red
    },
    animations = {
        loadingFrames = {"|", "/", "-", "\\"},
        progressChars = {"░", "▒", "▓", "█"}
    },
    themes = {
        default = {
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
            progressBg = colors.gray,
            highlight = colors.yellow,
            error = colors.red
        },
        dark = {
            background = colors.black,
            windowBg = colors.gray,
            text = colors.white,
            border = colors.white,
            shadow = colors.black,
            buttonBg = colors.gray,
            buttonText = colors.white,
            titleBar = colors.black,
            titleText = colors.white,
            progressBar = colors.lime,
            progressBg = colors.gray,
            highlight = colors.yellow,
            error = colors.red
        }
    },
    currentTheme = "default"
}

-- ASCII Art for the title screen
local titleArt = {
    "   _____ _____ _____    _____ _____ ",
    "  / ____|_   _|  __ \\  / ____/ ____|",
    " | (___   | | | |  | || |   | (___  ",
    "  \\___ \\  | | | |  | || |    \\___ \\ ",
    "  ____) |_| |_| |__| || |________) |",
    " |_____/|_____|_____/  \\_____|_____/",
    "      Sentinel Control Interface      ",
    "          Operating System           "
}

-- Installation steps
local steps = {
    {
        title = "Welcome",
        description = "Welcome to SCI Sentinel OS Installation"
    },
    {
        title = "License",
        description = "License Agreement"
    },
    {
        title = "Components",
        description = "Select Components"
    },
    {
        title = "Installing",
        description = "Installing Components"
    },
    {
        title = "Complete",
        description = "Installation Complete"
    }
}

local currentStep = 1

-- Navigation buttons style
local navButtons = {
    back = {
        text = "[ BACK ]",
        colors = {
            bg = colors.blue,
            fg = colors.white,
            disabled = colors.gray
        }
    },
    next = {
        text = "[ NEXT ]",
        colors = {
            bg = colors.blue,
            fg = colors.white,
            disabled = colors.gray
        }
    },
    install = {
        text = "[ INSTALL ]",
        colors = {
            bg = colors.green,
            fg = colors.white,
            disabled = colors.gray
        }
    },
    finish = {
        text = "[ REBOOT ]",
        colors = {
            bg = colors.green,
            fg = colors.white,
            disabled = colors.gray
        }
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

-- Draw a styled navigation button
function gui.drawNavButton(x, y, button, active)
    local oldBg = term.getBackgroundColor()
    local oldFg = term.getTextColor()
    
    if active then
        term.setBackgroundColor(button.colors.bg)
        term.setTextColor(button.colors.fg)
    else
        term.setBackgroundColor(button.colors.disabled)
        term.setTextColor(colors.lightGray)
    end
    
    term.setCursorPos(x, y)
    write(button.text)
    
    term.setBackgroundColor(oldBg)
    term.setTextColor(oldFg)
end

-- Enhanced progress bar with smooth animation
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
        write(string.rep("█", fillWidth))
    end
    
    -- Text overlay
    if text then
        local textX = x + math.floor((width - #text) / 2)
        term.setCursorPos(textX, y)
        term.setTextColor(gui.colors.text)
        write(text)
    end
    
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

-- Draw the installation wizard window
function drawInstallationWizard()
    -- Clear screen
    term.setBackgroundColor(gui.colors.background)
    term.clear()
    
    -- Draw window
    gui.drawWindow(2, 1, screen.width - 2, screen.height - 1, "SCI Sentinel OS Installation - " .. steps[currentStep].title)
    
    -- Draw progress bar at the top
    local progressWidth = screen.width - 8
    local progress = 0
    
    -- Calculate actual progress based on step and installation progress
    if currentStep == 1 then
        progress = 0
    elseif currentStep == 2 then
        progress = 0.25
    elseif currentStep == 3 then
        progress = 0.5
    elseif currentStep == 4 then
        -- During installation, progress will be updated dynamically
        if not installationProgress then
            progress = 0.75
        else
            progress = 0.75 + (installationProgress * 0.25)
        end
    elseif currentStep == 5 then
        progress = 1
    end
    
    gui.drawAnimatedProgressBar(4, 3, progressWidth, string.format("Step %d of %d", currentStep, #steps), progress)
    
    -- Draw step description
    term.setBackgroundColor(gui.colors.windowBg)
    term.setTextColor(gui.colors.text)
    term.setCursorPos(4, 5)
    write(steps[currentStep].description)
    
    -- Draw navigation bar background
    term.setBackgroundColor(gui.colors.titleBar)
    for y = screen.height - 4, screen.height - 2 do
        term.setCursorPos(2, y)
        write(string.rep(" ", screen.width - 3))
    end
    
    -- Draw navigation buttons
    drawNavigationButtons()
end

-- Global installation progress tracker
local installationProgress = 0

-- Draw navigation buttons
function drawNavigationButtons()
    local y = screen.height - 3
    
    -- Back button (if not on first step)
    if currentStep > 1 and currentStep < 4 then
        gui.drawNavButton(4, y, navButtons.back, true)
    end
    
    -- Draw step indicator in the middle
    local stepText = string.format("Step %d of %d", currentStep, #steps)
    term.setBackgroundColor(gui.colors.titleBar)
    term.setTextColor(gui.colors.titleText)
    term.setCursorPos(math.floor((screen.width - #stepText) / 2), y)
    write(stepText)
    
    -- Next/Install/Finish button
    local nextButton
    if currentStep < 3 then
        nextButton = navButtons.next
    elseif currentStep == 3 then
        nextButton = navButtons.install
    elseif currentStep == 5 then
        nextButton = navButtons.finish
    else
        nextButton = navButtons.next
    end
    
    gui.drawNavButton(screen.width - #nextButton.text - 4, y, nextButton, true)
end

-- Handle navigation button clicks
function handleNavigation(x, y)
    local navY = screen.height - 3
    
    -- Back button
    if currentStep > 1 and currentStep < 4 then
        if x >= 4 and x < 4 + #navButtons.back.text then
            if y == navY then
                currentStep = currentStep - 1
                return true
            end
        end
    end
    
    -- Next/Install/Finish button
    local nextButton
    if currentStep < 3 then
        nextButton = navButtons.next
    elseif currentStep == 3 then
        nextButton = navButtons.install
    elseif currentStep == 5 then
        nextButton = navButtons.finish
    else
        nextButton = navButtons.next
    end
    
    if y == navY then
        if x >= screen.width - #nextButton.text - 4 and x < screen.width - 4 then
            if currentStep == 5 then
                -- Handle reboot
                term.setBackgroundColor(colors.black)
                term.setTextColor(colors.white)
                term.clear()
                term.setCursorPos(1,1)
                print("Rebooting system...")
                os.sleep(1)
                os.reboot()
                return false
            else
                currentStep = currentStep + 1
                return true
            end
        end
    end
    
    return false
end

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
        {name = "Help", file = "Help.lua", target = "scios/Help.lua", required = true},
        {name = "Theme", file = "Theme.lua", target = "scios/Theme.lua", required = true}
    },
    root_files = {
        {name = "Startup", file = "Startup.lua", target = "startup.lua", required = true},
        {name = "Installer", file = "Installer.lua", target = "Installer.lua", required = false}
    }
}

-- Initialize screen
local function initScreen()
    updateScreenDimensions()
    term.clear()
    term.setCursorPos(1, 1)
    term.setBackgroundColor(gui.colors.background)
    term.clear()
end

-- Draw title screen with ASCII art
function drawTitleScreen()
    term.clear()
    term.setCursorPos(1, 1)
    term.setBackgroundColor(colors.black)
    
    local startY = math.floor((screen.height - #titleArt) / 2) - 2
    
    -- Rainbow effect for title with animation
    for frame = 1, 3 do  -- Add animation frames
        for i, line in ipairs(titleArt) do
            term.setCursorPos(math.floor((screen.width - #line) / 2), startY + i)
            local color = ({colors.red, colors.yellow, colors.lime, colors.cyan, colors.blue, colors.magenta})[((i-1 + frame) % 6) + 1]
            term.setTextColor(color)
            write(line)
        end
        os.sleep(0.5)  -- Pause between frames
    end
    
    -- Version number with fade-in effect
    term.setTextColor(gui.colors.text)
    local versionText = "Version " .. version
    local versionX = math.floor((screen.width - #versionText) / 2)
    local versionY = startY + #titleArt + 2
    
    -- Fade in version text
    for i = 1, #versionText do
        term.setCursorPos(versionX + i - 1, versionY)
        write(versionText:sub(i,i))
        os.sleep(0.05)
    end
    
    -- Add a "Press any key to continue" message
    local pressKeyMsg = "Press any key to continue..."
    term.setCursorPos(math.floor((screen.width - #pressKeyMsg) / 2), versionY + 2)
    term.setTextColor(colors.lightGray)
    write(pressKeyMsg)
    
    -- Wait for keypress
    os.pullEvent("key")
end

-- Enhanced error handling with humor
function showError(message, suggestion)
    term.setBackgroundColor(gui.colors.windowBg)
    term.setTextColor(gui.colors.error)
    term.setCursorPos(4, screen.height - 3)
    write("Error: " .. message)
    term.setCursorPos(4, screen.height - 2)
    term.setTextColor(gui.colors.text)
    write(suggestion or "Have you tried turning it off and on again?")
    os.sleep(3)
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
function checkInstallerUpdate()
    term.setBackgroundColor(colors.black)
    term.clear()
    term.setCursorPos(1, 1)
    print("Checking for installer updates...")
    
    local installerPath = shell.getRunningProgram()
    local url = getGitHubRawURL("Installer.lua")
    
    -- Create temp directory if it doesn't exist
    if not fs.exists("scios/temp") then
        fs.makeDir("scios/temp")
    end
    
    local tempPath = "scios/temp/installer_update.tmp"
    
    -- Clean up any existing temp files
    if fs.exists(tempPath) then
        fs.delete(tempPath)
    end
    
    -- Try to download the latest version
    local success, content = downloadFile(url, tempPath)
    
    if success then
        local currentFile = fs.open(installerPath, "r")
        if not currentFile then
            print("Error: Could not read current installer file.")
            fs.delete(tempPath)
            return false
        end
        
        local currentContent = currentFile.readAll()
        currentFile.close()
        
        if content ~= currentContent then
            print("New installer version found!")
            print("The installer will be updated now.")
            os.sleep(1)
            
            -- Create backup in temp directory
            local backupPath = "scios/temp/installer.backup"
            if fs.exists(backupPath) then
                fs.delete(backupPath)
            end
            fs.copy(installerPath, backupPath)
            
            -- Apply update
            if fs.exists(installerPath) then
                fs.delete(installerPath)
            end
            fs.move(tempPath, installerPath)
            
            -- Clean up
            if fs.exists(backupPath) then
                fs.delete(backupPath)
            end
            
            print("Update applied successfully!")
            print("Restarting installer...")
            os.sleep(1)
            
            -- Restart the installer
            os.run({}, installerPath)
            return true
        else
            print("Installer is up to date!")
            fs.delete(tempPath)
            os.sleep(1)
            return false
        end
    else
        print("Could not check for updates. Continuing with current version.")
        if fs.exists(tempPath) then
            fs.delete(tempPath)
        end
        os.sleep(1)
        return false
    end
end

-- Loading message animation
local loadingFrame = 1
local function showLoadingMessage(message)
    message = message or "Installing..."
    local x = math.floor((screen.width - #message - 2) / 2)
    local y = math.floor(screen.height / 2)
    
    term.setCursorPos(x, y)
    term.setBackgroundColor(gui.colors.windowBg)
    term.setTextColor(gui.colors.text)
    write(message .. " " .. gui.animations.loadingFrames[loadingFrame])
    
    loadingFrame = loadingFrame + 1
    if loadingFrame > #gui.animations.loadingFrames then
        loadingFrame = 1
    end
end

-- Main entry point
local function main()
    -- Always check for updates first
    if checkInstallerUpdate() then
        return  -- Exit if we updated (the new version will be running)
    end
    
    -- Handle any pending updates from previous runs
    if fs.exists("installer_update_pending") and fs.exists("installer_update.tmp") then
        local installerPath = shell.getRunningProgram()
        print("Applying pending installer update...")
        
        fs.delete(installerPath)
        fs.move("installer_update.tmp", installerPath)
        fs.delete("installer_update_pending")
        
        print("Installer updated. Restarting...")
        os.sleep(1)
        os.reboot()
        return
    end
    
    -- Proceed with installation
    updateScreenDimensions()  -- Update dimensions at start
    initScreen()
    drawTitleScreen()
    
    while currentStep <= #steps do
        updateScreenDimensions()  -- Update dimensions each iteration
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
                showLoadingMessage("Installing " .. module.name .. "...")
                installationProgress = filesInstalled / totalFiles
                drawInstallationWizard()  -- Redraw to update progress
                -- Download and install module
                local success = downloadFile(getGitHubRawURL(module.file), module.target)
                if not success and module.required then
                    showError("Failed to download " .. module.name .. " module", "Have you tried turning it off and on again?")
                    return
                end
                filesInstalled = filesInstalled + 1
                os.sleep(0.5)  -- Add slight delay for visual effect
            end
            
            for _, file in ipairs(config.root_files) do
                showLoadingMessage("Installing " .. file.name .. "...")
                installationProgress = filesInstalled / totalFiles
                drawInstallationWizard()  -- Redraw to update progress
                -- Download and install file
                local success = downloadFile(getGitHubRawURL(file.file), file.target)
                if not success and file.required then
                    showError("Failed to download " .. file.name, "Error 404: Success not found")
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
            write("SCI Sentinel OS has been successfully installed.")
            term.setCursorPos(4, 9)
            write("Click the REBOOT button to complete installation.")
        end
        
        -- Wait for user input
        local event, button, x, y = os.pullEvent("mouse_click")
        
        -- Handle navigation buttons
        if handleNavigation(x, y) then
            -- Redraw the wizard window
            drawInstallationWizard()
        end
    end
end

-- Start the program
main()
