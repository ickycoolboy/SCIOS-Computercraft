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

-- Add the current directory to package path
local currentDir = shell.dir()
package.path = currentDir .. "/?.lua;" .. package.path

-- Try to load GUI module, create basic functions if not available
local gui
local function initGUI()
    if fs.exists("GUI.lua") then
        gui = require("GUI")
    else
        -- Create temporary basic GUI functions if module not available
        gui = {
            drawBox = function(x, y, width, height, title)
                term.setCursorPos(x, y)
                write("+" .. string.rep("-", width-2) .. "+")
                for i = 1, height-2 do
                    term.setCursorPos(x, y+i)
                    write("|" .. string.rep(" ", width-2) .. "|")
                end
                term.setCursorPos(x, y+height-1)
                write("+" .. string.rep("-", width-2) .. "+")
                if title then
                    term.setCursorPos(x + math.floor((width - #title) / 2), y)
                    write(title)
                end
            end,
            drawCenteredText = function(y, text, color)
                local w, _ = term.getSize()
                term.setCursorPos(math.floor((w - #text) / 2), y)
                if color then term.setTextColor(color) end
                write(text)
                term.setTextColor(colors.white)
            end,
            drawButton = function(x, y, text, color)
                local oldColor = term.getBackgroundColor()
                if color then term.setBackgroundColor(color) end
                term.setCursorPos(x, y)
                write(" " .. text .. " ")
                term.setBackgroundColor(oldColor)
                return {
                    x = x,
                    y = y,
                    width = #text + 2,
                    text = text
                }
            end
        }
    end
    return gui
end

-- Initialize GUI
gui = initGUI()

-- Main installation process
term.clear()
term.setCursorPos(1,1)

-- Draw main interface
gui.drawBox(1, 1, 51, 16, "[ SCI Sentinel Installer ]")

-- Draw welcome message
term.setCursorPos(3, 3)
term.setTextColor(colors.yellow)
write("Welcome to SCI Sentinel")
term.setTextColor(colors.white)
term.setCursorPos(3, 5)
write("This installer will set up SCI Sentinel on your")
term.setCursorPos(3, 6)
write("computer. SCI Sentinel provides security and")
term.setCursorPos(3, 7)
write("monitoring features for your system.")

-- Draw installation options
term.setCursorPos(3, 9)
term.setTextColor(colors.lime)
write("Installation Options")
term.setTextColor(colors.white)

-- Create buttons
local installButton = gui.drawButton(3, 11, "Install", colors.green)
local exitButton = gui.drawButton(15, 11, "Exit", colors.red)

-- Handle button input
while true do
    local event, button, x, y = os.pullEvent("mouse_click")
    
    -- Check Install button
    if y == installButton.y and x >= installButton.x and x < installButton.x + installButton.width then
        -- Start installation
        term.clear()
        term.setCursorPos(1,1)
        gui.drawBox(1, 1, 51, 16, "[ Installing SCI Sentinel ]")
        
        -- Create directories
        term.setCursorPos(3, 4)
        write("Creating directories...")
        if not fs.exists("scios") then
            fs.makeDir("scios")
        end
        os.sleep(0.2)
        
        -- Copy files
        local files = {
            {"GUI.lua", "scios/GUI.lua"},
            {"Commands.lua", "scios/Commands.lua"},
            {"sci_sentinel.lua", "scios/sci_sentinel.lua"},
            {"Updater.lua", "scios/Updater.lua"}
        }
        
        for i, file in ipairs(files) do
            term.setCursorPos(3, 5)
            write(string.format("Installing: %s", file[1]))
            if fs.exists(file[1]) then
                fs.copy(file[1], file[2])
            end
            os.sleep(0.3)
        end
        
        -- Configure startup
        term.setCursorPos(3, 6)
        write("Configuring startup...")
        local startup = fs.open("startup.lua", "w")
        if startup then
            startup.write('shell.run("scios/sci_sentinel.lua")')
            startup.close()
        end
        os.sleep(0.2)
        
        -- Show completion screen
        term.clear()
        term.setCursorPos(1,1)
        gui.drawBox(1, 1, 51, 16, "[ Installation Complete ]")
        
        term.setCursorPos(3, 4)
        term.setTextColor(colors.lime)
        write("Success!")
        term.setTextColor(colors.white)
        term.setCursorPos(3, 6)
        write("SCI Sentinel has been installed successfully.")
        term.setCursorPos(3, 7)
        write("The system will start automatically on boot.")
        
        term.setCursorPos(3, 9)
        term.setTextColor(colors.yellow)
        write("What's Next?")
        term.setTextColor(colors.white)
        term.setCursorPos(3, 11)
        write("Would you like to reboot now?")
        
        -- Create reboot buttons
        local rebootButton = gui.drawButton(3, 13, "Reboot", colors.green)
        local laterButton = gui.drawButton(15, 13, "Later", colors.red)
        
        -- Handle reboot choice
        while true do
            local event, button, x, y = os.pullEvent("mouse_click")
            if y == rebootButton.y then
                if x >= rebootButton.x and x < rebootButton.x + rebootButton.width then
                    term.clear()
                    term.setCursorPos(1,1)
                    gui.drawCenteredText(8, "Rebooting...", colors.yellow)
                    os.sleep(1)
                    os.reboot()
                elseif x >= laterButton.x and x < laterButton.x + laterButton.width then
                    term.clear()
                    term.setCursorPos(1,1)
                    return
                end
            end
        end
        
    -- Check Exit button
    elseif y == exitButton.y and x >= exitButton.x and x < exitButton.x + exitButton.width then
        term.clear()
        term.setCursorPos(1,1)
        return
    end
end
