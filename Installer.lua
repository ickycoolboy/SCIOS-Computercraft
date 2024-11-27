-- SCI Sentinel OS Installer
local version = "1.1.0" -- Major version bump due to significant changes in file handling and startup management

-- Try to load the GUI module
local gui = nil
local hasGUI = false
if fs.exists("GUI.lua") then
    gui = require("GUI")
    hasGUI = true
end

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

-- Create GitHub raw URL with cache busting
local function getGitHubRawURL(filepath)
    return string.format("https://raw.githubusercontent.com/%s/%s/%s/%s?cb=%d",
        config.repo_owner,
        config.repo_name,
        config.branch,
        filepath,
        os.epoch("utc"))
end

-- Download a file
local function downloadFile(url, path)
    local response = http.get(url)
    if response then
        local content = response.readAll()
        response.close()
        
        local file = fs.open(path, "w")
        if file then
            file.write(content)
            file.close()
            return true
        end
    end
    return false
end

-- Check for installer updates
local function checkForUpdates()
    showLoadingMessage()
    print("Checking for updates...")
    
    -- Get installer file info from config
    local installerFile = nil
    for _, file in ipairs(config.root_files) do
        if file.name == "Installer" then
            installerFile = file
            break
        end
    end
    
    if not installerFile then return false end
    
    -- Download the latest installer
    local installerURL = getGitHubRawURL(installerFile.file)
    local tempPath = "installer.tmp"
    
    if downloadFile(installerURL, tempPath) then
        -- Read the version from the downloaded file
        local file = fs.open(tempPath, "r")
        if file then
            local content = file.readAll()
            file.close()
            
            -- Extract version from the downloaded file
            local newVersion = string.match(content, 'local version = "([^"]+)"')
            if newVersion and newVersion ~= version then
                print("New version found: " .. newVersion)
                showLoadingMessage()
                print("Updating installer...")
                
                -- Backup current installer
                if fs.exists(installerFile.target) then
                    fs.delete(installerFile.target .. ".backup")
                    fs.copy(installerFile.target, installerFile.target .. ".backup")
                end
                
                -- Replace current installer with new version
                fs.delete(installerFile.target)
                fs.copy(tempPath, installerFile.target)
                fs.delete(tempPath)
                
                -- Re-run the new installer
                print("Update complete! Restarting installer...")
                os.sleep(1)
                shell.run(installerFile.target)
                return true
            else
                print("No updates found. Running current version: " .. version)
                os.sleep(1)
            end
        end
        fs.delete(tempPath)
    else
        print("Failed to check for updates. Continuing with installation...")
        os.sleep(1)
    end
    return false
end

-- Handle any pending updates first
if not checkForUpdates() then
    -- Main installation process
    term.clear()
    term.setCursorPos(1,1)

    if hasGUI then
        -- Draw main interface with GUI
        gui.drawBox(1, 1, 51, 16, "[ SCI Sentinel Installer ]")

        -- Draw welcome message
        term.setCursorPos(3, 3)
        term.setTextColor(colors.yellow)
        write("Welcome to SCI Sentinel")
        term.setTextColor(colors.white)
    else
        -- Fallback to basic terminal interface
        print("=== SCI Sentinel Installer ===")
        print("Welcome to SCI Sentinel")
        print("Version: " .. version)
        print("Press any key to begin installation...")
        os.pullEvent("key")
    end

    -- Draw installation options
    if hasGUI then
        term.setCursorPos(3, 9)
        term.setTextColor(colors.lime)
        write("Installation Options")
        term.setTextColor(colors.white)
    else
        print("Installation Options:")
    end

    -- Create buttons
    local installButton = nil
    local exitButton = nil
    if hasGUI then
        installButton = gui.drawButton(3, 11, "Install", colors.green)
        exitButton = gui.drawButton(15, 11, "Exit", colors.red)
    else
        print("1. Install")
        print("2. Exit")
    end

    -- Handle button input
    while true do
        if hasGUI then
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
                    {"sci_sentinel.lua", "scios/sci_sentinel.lua"},
                    {"GUI.lua", "scios/GUI.lua"},
                    {"Commands.lua", "scios/Commands.lua"},
                    {"Updater.lua", "scios/Updater.lua"}
                }
                
                for i, file in ipairs(files) do
                    term.setCursorPos(3, 5)
                    write(string.format("Downloading: %s", file[1]))
                    -- Download file from GitHub with cache busting
                    local success = downloadFile(getGitHubRawURL(file[1]), file[2])
                    if not success then
                        -- If download fails, try to use local copy as fallback
                        if fs.exists(file[1]) then
                            fs.copy(file[1], file[2])
                            write(" (using local copy)")
                        else
                            write(" (failed)")
                        end
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
        else
            local event, key = os.pullEvent("key")
            if key == 49 then
                -- Start installation
                print("Creating directories...")
                if not fs.exists("scios") then
                    fs.makeDir("scios")
                end
                
                -- Copy files
                local files = {
                    {"sci_sentinel.lua", "scios/sci_sentinel.lua"},
                    {"GUI.lua", "scios/GUI.lua"},
                    {"Commands.lua", "scios/Commands.lua"},
                    {"Updater.lua", "scios/Updater.lua"}
                }
                
                for i, file in ipairs(files) do
                    print(string.format("Downloading: %s", file[1]))
                    -- Download file from GitHub with cache busting
                    local success = downloadFile(getGitHubRawURL(file[1]), file[2])
                    if not success then
                        -- If download fails, try to use local copy as fallback
                        if fs.exists(file[1]) then
                            fs.copy(file[1], file[2])
                            print(" (using local copy)")
                        else
                            print(" (failed)")
                        end
                    end
                    os.sleep(0.3)
                end
                
                -- Configure startup
                print("Configuring startup...")
                local startup = fs.open("startup.lua", "w")
                if startup then
                    startup.write('shell.run("scios/sci_sentinel.lua")')
                    startup.close()
                end
                
                -- Show completion screen
                print("Installation Complete!")
                print("SCI Sentinel has been installed successfully.")
                print("The system will start automatically on boot.")
                
                print("What's Next?")
                print("Would you like to reboot now?")
                
                -- Handle reboot choice
                while true do
                    local event, key = os.pullEvent("key")
                    if key == 49 then
                        print("Rebooting...")
                        os.sleep(1)
                        os.reboot()
                    elseif key == 50 then
                        return
                    end
                end
            elseif key == 50 then
                term.clear()
                term.setCursorPos(1,1)
                return
            end
        end
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

-- Installer version and update URL
local github_base = "https://raw.githubusercontent.com/SkyTheCodeMaster/scios/main"

-- Function to get current timestamp
local function getTimestamp()
    return os.epoch("utc")
end

-- Function to get GitHub raw URL with cache busting
local function getGitHubRawURL(file)
    return string.format("%s/%s?token=%d", github_base, file, getTimestamp())
end

-- Function to download a file with cache busting
local function downloadFile(url, path)
    local response = http.get(url)
    if response then
        local content = response.readAll()
        response.close()
        
        local file = fs.open(path, "w")
        if file then
            file.write(content)
            file.close()
            return true
        end
    end
    return false
end
