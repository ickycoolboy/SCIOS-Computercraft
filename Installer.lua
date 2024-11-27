-- SCI Sentinel OS Installer
local version = "1.0.1"

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
        {name = "Core", file = "Sci_sentinel.lua"},
        {name = "Updater", file = "Updater.lua"},
        {name = "GUI", file = "Gui.lua"},
        {name = "Commands", file = "Commands.lua"}
    },
    root_files = {
        {name = "Startup", file = "startup.lua", required = true}  -- Mark as required
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
        os.epoch("utc")) -- Add timestamp to bust cache
end

-- Safe file write function for ComputerCraft
local function safeWrite(path, content)
    -- First try to delete the file if it exists
    if fs.exists(path) then
        local tries = 0
        while tries < 3 do
            if pcall(fs.delete, path) then
                break
            end
            tries = tries + 1
            os.sleep(0.5)  -- Give the system time to release file handles
        end
    end
    
    -- Now try to write the new file
    local tries = 0
    while tries < 3 do
        local file = fs.open(path, "w")
        if file then
            file.write(content)
            file.close()
            return true
        end
        tries = tries + 1
        os.sleep(0.5)  -- Wait before retrying
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
        
        -- Ensure parent directory exists if not a root file
        if not fs.getName(path) == path then
            local dir = fs.getDir(path)
            if dir and dir ~= "" and not fs.exists(dir) then
                fs.makeDir(dir)
            end
        end
        
        -- Use safe write function
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
        -- Check if content is different
        local currentFile = fs.open(installerPath, "r")
        local currentContent = currentFile.readAll()
        currentFile.close()
        
        if content ~= currentContent then
            print("Installer update available.")
            print("The installer will be updated on next run.")
            print("Please run the installer again after this installation completes.")
            
            -- Create a marker file that will trigger the update on next run
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
        
        -- Delete the old installer and move the new one in place
        fs.delete(installerPath)
        fs.move("installer_update.tmp", installerPath)
        fs.delete("installer_update_pending")
        
        print("Installer updated. Restarting...")
        os.sleep(1)
        os.reboot()
    end
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

-- Main installation process
print("SCI Sentinel OS Installer v" .. version)
print("Your friendly neighborhood OS installer")

-- Handle any pending updates first
handlePendingUpdate()

-- Check for installer updates
print("\nChecking for installer updates...")
local updateAvailable = checkInstallerUpdate()

-- Ask for confirmation
listFilesToInstall()
write("\nDo you want to install SCI Sentinel OS? (y/n): ")
local input = read():lower()
if input ~= "y" and input ~= "yes" then
    print("Installation cancelled. The digital future will have to wait...")
    return
end

print("\nPerforming installation...")

-- Create install directory if it doesn't exist
if not fs.exists(config.install_dir) then
    fs.makeDir(config.install_dir)
end

-- Download and install core modules
for _, module in ipairs(config.modules) do
    showLoadingMessage()
    print(string.format("Downloading %s module...", module.name))
    local success = downloadFile(
        getGitHubRawURL(module.file),
        config.install_dir .. "/" .. module.file
    )
    if not success then
        print(string.format("Failed to download %s module", module.name))
        print("Initial setup failed! (Have you tried turning it off and on again?)")
        return
    end
end

-- Download and install root files
local startup_installed = false
for _, file in ipairs(config.root_files) do
    showLoadingMessage()
    print(string.format("Downloading %s file...", file.name))
    
    -- Special handling for startup.lua
    if file.file == "startup.lua" then
        -- First try to download from GitHub
        local success = downloadFile(getGitHubRawURL(file.file), "temp_startup.lua")
        
        if success then
            -- Try to safely move the temp file to startup.lua
            if fs.exists("startup.lua") then
                print("Removing old startup file...")
                fs.delete("startup.lua")
                os.sleep(0.5)  -- Give the system time
            end
            
            print("Installing new startup file...")
            if pcall(fs.move, "temp_startup.lua", "startup.lua") then
                startup_installed = true
            else
                print("Failed to move startup file, trying direct write...")
                -- If move fails, try direct write
                local content = "-- SCI Sentinel OS Startup File\nshell.run(\"scios/sci_sentinel.lua\")"
                if safeWrite("startup.lua", content) then
                    startup_installed = true
                end
            end
        else
            print("Failed to download startup.lua, creating locally...")
            -- Create a basic startup file locally
            local content = "-- SCI Sentinel OS Startup File\nshell.run(\"scios/sci_sentinel.lua\")"
            if safeWrite("startup.lua", content) then
                startup_installed = true
            end
        end
        
        if not startup_installed then
            print("Failed to create startup file!")
            if file.required then
                return
            end
        end
    else
        -- Handle other root files normally
        local success = downloadFile(getGitHubRawURL(file.file), file.file)
        if not success and file.required then
            print(string.format("Failed to download required file: %s", file.name))
            print("Initial setup failed! (Error 404: Success not found)")
            return
        end
    end
end

if not startup_installed then
    print("Critical error: startup.lua not installed!")
    print("The computer needs this to boot properly.")
    return
end

print("\nInstallation complete!")
print("Your computer has been upgraded with approximately 10,000 Terabytes of awesomeness!")
print("Rebooting in 3 seconds...")
print("(Please ensure your quantum flux capacitor is properly aligned)")
os.sleep(3)
os.reboot()
