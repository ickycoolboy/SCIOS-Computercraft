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
            return true
        end
    end
    return false
end

-- Main installation process
print("Performing initial installation...")

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

print("Installation complete!")
print("Rebooting in 3 seconds...")
os.sleep(3)
os.reboot()
