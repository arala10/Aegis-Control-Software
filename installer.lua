local base_url = "https://raw.githubusercontent.com/arala10/Aegis-Control-Software/refs/heads/main/"

local files_to_install = {
    "startup.lua",
    "main.lua",
    "apps.lua",
    "logo.txt",
    "modules/utils.lua",
    "modules/ui.lua",
    "modules/config.lua",
    "modules/canon.lua",
    "modules/ballistics.lua",
    "modules/missions.lua"
}

local function download_file(path)
    local url = base_url .. path
    print("Downloading " .. url)
    
    local response = http.get(url)
    
    if not response then
        print("Error: Network request failed.")
        print("Please check your internet connection and the repository details.")
        return nil
    end
    
    local content = response.readAll()
    response.close()
    
    if response.getResponseCode() ~= 200 then
        print("Error: Received HTTP Status " .. response.getResponseCode())
        print("Please check that the file exists at the specified URL.")
        if content then
            print("Response: " .. content)
        end
        return nil
    end
    
    return content
end

local function install()
    print("--- Aegis Control Software Installer ---")

    local all_successful = true
    for _, path in ipairs(files_to_install) do
        local dir = path:match("(.*/)")
        if dir and not fs.exists(dir) then
            print("Creating directory: " .. dir)
            fs.makeDir(dir)
        end

        local content = download_file(path)

        if content then
            local file = fs.open(path, "w")
            file.write(content)
            file.close()
            print("Successfully installed: " .. path)
        else
            print("Failed to install: " .. path)
            all_successful = false
            break
        end
        print("")
    end
    
    if all_successful then
        print("--- Installation Complete! ---")
        print("You can now run the software by executing: startup.lua")
    else
        print("--- Installation Failed ---")
        print("Please check the errors above and try again.")
    end
end

install()