return function(AegisOS)
    AegisOS.utils.clearScreen(AegisOS)

    if not fs.exists(AegisOS.paths.config) then
        AegisOS.config.firstTimeSetup(AegisOS)
    end

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
    AegisOS.redstoneController.redstoneToggle(AegisOS, config.redstoneDirections.power, true)

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
            AegisOS.redstoneController.redstoneToggle(AegisOS, config.redstoneDirections.power, false)
            sleep(2)
            AegisOS.utils.clearScreen(AegisOS)
            return
        end
    end
end