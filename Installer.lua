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
term.clear()
term.setCursorPos(1, 1)
print("SCI Sentinel OS Installer v" .. version)
print("===============================")
print("\nYour friendly neighborhood OS installer")
print("(Now with 100% more progress bars!)")

handlePendingUpdate()

write("\nProceed with installation? (y/n): ")
local input = read():lower()
if input ~= "y" and input ~= "yes" then
    print("\nInstallation cancelled.")
    print("The digital future will have to wait...")
    return
end

term.clear()
term.setCursorPos(1, 1)
print("SCI Sentinel OS Installation")
print("===========================")

-- Check for force flag
local args = {...}
local forceInstall = false
for _, arg in ipairs(args) do
    if arg == "--force" then
        forceInstall = true
        break
    end
end

if forceInstall then
    animateLoading(2000, "Force cleaning old installation...")
    if not cleanInstall() then
        print("Failed to clean existing installation")
        return
    end
end

if not fs.exists(config.install_dir) then
    fs.makeDir(config.install_dir)
end

local totalFiles = #config.modules + #config.root_files
local filesInstalled = 0

-- Install modules
for _, module in ipairs(config.modules) do
    filesInstalled = filesInstalled + 1
    local progress = filesInstalled / totalFiles
    
    drawProgressBar(2, 15, 40, progress, "Installing: " .. module.name)
    animateLoading(1000, "Downloading " .. module.name .. " module")
    
    local success = downloadFile(
        getGitHubRawURL(module.file),
        module.target
    )
    
    if not success and module.required then
        print("\nFailed to download " .. module.name .. " module")
        print("Installation failed! (Have you tried turning it off and on again?)")
        return
    end
end

-- Install root files
for _, file in ipairs(config.root_files) do
    filesInstalled = filesInstalled + 1
    local progress = filesInstalled / totalFiles
    
    drawProgressBar(2, 15, 40, progress, "Installing: " .. file.name)
    animateLoading(1000, "Setting up " .. file.name)
    
    local success = downloadFile(getGitHubRawURL(file.file), file.target)
    if not success and file.required then
        print("\nFailed to download " .. file.name)
        print("Installation failed! (Error 404: Success not found)")
        return
    end
end

term.clear()
term.setCursorPos(1, 1)
print("Installation Complete!")
print("=====================")
print("\nYour computer has been upgraded with")
print("approximately 10,000 Terabytes of awesomeness!")
print("\nRebooting in 3 seconds...")
print("(Please ensure your quantum flux capacitor")
print("is properly aligned)")
os.sleep(3)
os.reboot()
