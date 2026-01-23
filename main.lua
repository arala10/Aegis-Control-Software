return function(AegisOS)
    AegisOS.utils.clearScreen(AegisOS)

    -- Ensure logo file exists in the data directory
    if not fs.exists(AegisOS.paths.logo) and fs.exists("logo.txt") then
        local logoFile = fs.open("logo.txt", "r")
        local logoContent = logoFile.readAll()
        logoFile.close()

        if not fs.exists("data") then fs.makeDir("data") end

        local destFile = fs.open(AegisOS.paths.logo, "w")
        destFile.write(logoContent)
        destFile.close()
    end

    -- Render startup sequence
    local success, lineAfterLogo = AegisOS.utils.renderCenteredAsciiArt(AegisOS, AegisOS.paths.logo)
    if success then
        AegisOS.utils.renderLoadingBar(AegisOS, lineAfterLogo, 30, 1, "Initializing AegisOS")
    else
        AegisOS.utils.clearScreen(AegisOS)
        print("AegisOS v" .. AegisOS.version)
        print("Initializing system...")
        sleep(2)
    end

    local config = AegisOS.config.getConfig(AegisOS)
    AegisOS.utils.redstoneToggle(AegisOS, config.redstoneDirections.power, true)

    -- Main application loop
    while true do
        local choice = AegisOS.ui.showMenu(AegisOS, "Aegis Control System v" .. AegisOS.version, {
            "Fire Mission",
            "Manual Override",
            "System Settings",
            "Shutdown"
        })

        if choice == 1 then
            AegisOS.apps.fireMissionManager(AegisOS)
        elseif choice == 2 then
            AegisOS.apps.manualOverride(AegisOS)
        elseif choice == 3 then
            AegisOS.apps.parameterSettings(AegisOS)
        elseif choice == 4 then
            AegisOS.utils.clearScreen(AegisOS)
            print("Shutting down...")
            AegisOS.utils.redstoneToggle(AegisOS, config.redstoneDirections.power, false)
            sleep(2)
            AegisOS.utils.clearScreen(AegisOS)
            return
        end
    end
end