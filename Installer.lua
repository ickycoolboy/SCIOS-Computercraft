-- SCI Sentinel OS Installer
local version = "1.0.1"

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
        {name = "Startup", file = "startup.lua"}
    }
}

-- Create GitHub raw URL
local function getGitHubRawURL(filepath)
    return string.format("https://raw.githubusercontent.com/%s/%s/%s/%s?cb=%d",
        config.repo_owner,
        config.repo_name,
        config.branch,
        filepath,
        os.epoch("utc")) -- Add timestamp to bust cache
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
        
        -- Delete existing file if it exists
        if fs.exists(path) then
            fs.delete(path)
        end
        
        local file = fs.open(path, "w")
        if file then
            file.write(content)
            file.close()
            return true, content
        end
    end
    return false
end

-- Check for installer updates
local function checkInstallerUpdate()
    local installerPath = shell.getRunningProgram()
    local url = getGitHubRawURL("Installer.lua")
    local success, content = downloadFile(url, "installer_new.lua")
    
    if success then
        -- Check if content is different
        local currentFile = fs.open(installerPath, "r")
        local currentContent = currentFile.readAll()
        currentFile.close()
        
        if content ~= currentContent then
            print("Installer update available. Installing...")
            fs.delete(installerPath)
            fs.move("installer_new.lua", installerPath)
            print("Installer updated. Restarting...")
            os.sleep(1)
            os.reboot()
        else
            fs.delete("installer_new.lua")
        end
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
        print(string.format("  - %s", file.file))
    end
    print("\nTotal size: Approximately 10,000 Terrabytes *roughly*")
    print("\nNote: Existing files will be overwritten.")
end

-- Main installation process
print("SCI Sentinel OS Installer v" .. version)

-- Check for installer updates first
print("\nChecking for installer updates...")
checkInstallerUpdate()

-- Ask for confirmation
listFilesToInstall()
write("\nDo you want to install SCI Sentinel OS? (y/n): ")
local input = read():lower()
if input ~= "y" and input ~= "yes" then
    print("Installation cancelled.")
    return
end

print("\nPerforming installation...")

-- Create install directory if it doesn't exist
if not fs.exists(config.install_dir) then
    fs.makeDir(config.install_dir)
end

-- Download and install core modules
for _, module in ipairs(config.modules) do
    print(string.format("Downloading %s module...", module.name))
    local success = downloadFile(
        getGitHubRawURL(module.file),
        config.install_dir .. "/" .. module.file
    )
    if not success then
        print(string.format("Failed to download %s module", module.name))
        print("Initial setup failed!")
        return
    end
end

-- Download and install root files
for _, file in ipairs(config.root_files) do
    print(string.format("Downloading %s file...", file.name))
    local success = downloadFile(
        getGitHubRawURL(file.file),
        file.file
    )
    if not success then
        print(string.format("Failed to download %s file", file.name))
        print("Initial setup failed!")
        return
    end
end

print("\nInstallation complete!")
print("Rebooting in 3 seconds...")
os.sleep(3)
os.reboot()
