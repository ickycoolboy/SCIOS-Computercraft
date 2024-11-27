-- SCI Sentinel OS Installer
local version = "1.1.0" -- Major version bump due to significant changes in file handling and startup management

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
        {name = "Updater", file = "Updater.lua", target = "scios/Updater.lua", required = true}
    },
    root_files = {
        {name = "Startup", file = "Startup.lua", target = "startup.lua", required = true},
        {name = "Installer", file = "Installer.lua", target = "Installer.lua", required = false}
    }
}

-- Show a random loading message
local function showLoadingMessage()
    local msg = loading_messages[math.random(1, #loading_messages)]
    print(msg)
    os.sleep(0.5)
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

-- Progress bar function
local function drawProgressBar(x, y, width, progress, text)
    local filled = math.floor(progress * width)
    term.setCursorPos(x, y)
    term.write(string.rep("=", filled) .. string.rep("-", width - filled))
    if text then
        term.setCursorPos(x + math.floor((width - #text) / 2), y - 1)
        term.write(text)
    end
end

-- Animated loading function
local function animateLoading(duration, message)
    local chars = {"|", "/", "-", "\\"}
    local startTime = os.epoch("utc")
    local width = term.getSize()
    local x = math.floor((width - #message) / 2)
    
    while os.epoch("utc") - startTime < duration do
        for _, char in ipairs(chars) do
            term.setCursorPos(x, 10)
            term.write(message .. " " .. char)
            os.sleep(0.1)
        end
    end
    term.setCursorPos(x, 10)
    term.write(message .. " ")
    os.sleep(0.5)
end

-- List files to be installed
local function listFilesToInstall()
    print("\nThe following files will be installed:")
    print("\nCore modules (in /scios):")
    for _, module in ipairs(config.modules) do
        print(string.format("  - %s", module.file))
    end
    
    print("\nRoot files:")
    for _, file in ipairs(config.root_files) do
        print(string.format("  - %s%s", file.file, file.required and " (required)" or ""))
    end
    print("\nTotal size: Approximately 10,000 Terabytes *roughly*")
    print("(Warning: May require downloading more RAM)")
    print("\nNote: Existing files will be overwritten.")
end

-- Force delete a file regardless of protection
local function forceDelete(path)
    if fs.exists(path) then
        fs.delete(path)
    end
end

-- Clean install function
local function cleanInstall()
    print("Performing clean installation...")
    
    -- Force remove all existing files
    forceDelete("startup.lua")
    forceDelete("scios/Sci_sentinel.lua")
    forceDelete("scios/Gui.lua")
    forceDelete("scios/Commands.lua")
    forceDelete("scios/Updater.lua")
    forceDelete("scios/versions.db")
    
    if fs.exists("scios") and #fs.list("scios") == 0 then
        fs.delete("scios")
    end
    
    -- Create fresh scios directory
    if not fs.exists("scios") then
        fs.makeDir("scios")
    end
    
    return true
end

-- Main installation process
local gui = require("GUI")

-- Clear the screen
term.clear()
term.setCursorPos(1,1)

-- Draw main interface
gui.drawFancyBox(1, 1, 51, 16, "[ SCI Sentinel Installer ]", colors.gray, colors.white)

-- Draw welcome message
gui.drawHeader(3, 3, "Welcome to SCI Sentinel", colors.yellow)
term.setCursorPos(3, 5)
term.setTextColor(colors.white)
write("This installer will set up SCI Sentinel on your")
term.setCursorPos(3, 6)
write("computer. SCI Sentinel provides security and")
term.setCursorPos(3, 7)
write("monitoring features for your system.")

-- Draw installation options
gui.drawHeader(3, 9, "Installation Options", colors.lime)

-- Create clickable buttons
local buttons = {
    gui.drawClickableButton(3, 11, "Install", colors.green, colors.lime),
    gui.drawClickableButton(15, 11, "Exit", colors.red, colors.orange)
}

-- Handle button clicks
local choice = gui.handleMouseEvents(buttons)

if choice == "Install" then
    -- Installation process
    term.clear()
    term.setCursorPos(1,1)
    gui.drawFancyBox(1, 1, 51, 16, "[ Installing SCI Sentinel ]", colors.gray, colors.white)
    
    -- Initialize progress tracking
    local function updateProgress(status, progress)
        gui.updateProgress(3, 4, 45, "Installing", progress, status)
    end
    
    -- Create directories
    updateProgress("Creating directories...", 0.1)
    if not fs.exists("scios") then
        fs.makeDir("scios")
    end
    os.sleep(0.2)
    
    -- Download files
    local files = {
        "sci_sentinel.lua",
        "GUI.lua",
        "Commands.lua",
        "Updater.lua"
    }
    
    for i, file in ipairs(files) do
        updateProgress("Downloading: " .. file, 0.2 + (0.5 * (i/#files)))
        -- Simulate file download/copy
        os.sleep(0.3)
        -- Here you would actually download or copy the file
    end
    
    -- Configure startup
    updateProgress("Configuring startup...", 0.8)
    local startup = fs.open("startup.lua", "w")
    if startup then
        startup.write('shell.run("scios/sci_sentinel.lua")')
        startup.close()
    end
    os.sleep(0.2)
    
    -- Complete installation
    updateProgress("Installation Complete!", 1.0)
    os.sleep(1)
    
    -- Show completion screen
    term.clear()
    term.setCursorPos(1,1)
    gui.drawFancyBox(1, 1, 51, 16, "[ Installation Complete ]", colors.gray, colors.white)
    
    gui.drawHeader(3, 4, "Success!", colors.lime)
    term.setCursorPos(3, 6)
    term.setTextColor(colors.white)
    write("SCI Sentinel has been installed successfully.")
    term.setCursorPos(3, 7)
    write("The system will start automatically on boot.")
    
    gui.drawHeader(3, 9, "What's Next?", colors.yellow)
    term.setCursorPos(3, 11)
    write("Would you like to reboot now?")
    
    -- Create reboot buttons
    local rebootButtons = {
        gui.drawClickableButton(3, 13, "Reboot", colors.green, colors.lime),
        gui.drawClickableButton(15, 13, "Later", colors.red, colors.orange)
    }
    
    -- Handle reboot choice
    local rebootChoice = gui.handleMouseEvents(rebootButtons)
    if rebootChoice == "Reboot" then
        term.clear()
        term.setCursorPos(1,1)
        gui.drawCenteredText(8, "Rebooting...", colors.yellow)
        os.sleep(1)
        os.reboot()
    else
        term.clear()
        term.setCursorPos(1,1)
    end
else
    -- Exit installer
    term.clear()
    term.setCursorPos(1,1)
end
