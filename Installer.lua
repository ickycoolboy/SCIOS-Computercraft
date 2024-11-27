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
        {name = "Commands", file = "Commands.lua"},
        {name = "Startup", file = "Startup.lua"}
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
        
        -- Ensure parent directory exists
        local dir = fs.getDir(path)
        if dir and dir ~= "" and not fs.exists(dir) then
            fs.makeDir(dir)
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

-- Create startup file
local function createStartup()
    print("Creating startup file...")
    local startup = [[
-- SCI Sentinel OS Startup
local version = "1.0.1"

-- System file protection
local protected_files = {
    "scios/Sci_sentinel.lua",
    "scios/Gui.lua",
    "scios/Commands.lua",
    "scios/Updater.lua",
    "startup.lua",
    "scios/versions.db"
}

-- Override fs.delete for protected files
local original_delete = fs.delete
fs.delete = function(path)
    path = fs.combine("", path) -- Normalize path
    for _, protected in ipairs(protected_files) do
        if path == protected then
            return false -- Prevent deletion of protected files
        end
    end
    return original_delete(path)
end

-- Load the main OS file
if fs.exists("scios/Sci_sentinel.lua") then
    shell.run("scios/Sci_sentinel.lua")
else
    print("SCI Sentinel OS not found. Please run the installer.")
end
]]
    local file = fs.open("startup.lua", "w")
    if file then
        file.write(startup)
        file.close()
        return true
    end
    return false
end

-- Main installation process
print("Performing initial installation...")

-- Create install directory if it doesn't exist
if not fs.exists(config.install_dir) then
    fs.makeDir(config.install_dir)
end

-- Create startup file
if not createStartup() then
    print("Failed to create startup file!")
    return
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

print("Installation complete!")
print("Rebooting in 3 seconds...")
os.sleep(3)
os.reboot()
