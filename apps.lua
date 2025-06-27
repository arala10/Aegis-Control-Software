local apps = {}

function apps.fireMissionManager()
    while true do
        local choice = AegisOS.ui.showMenu("Fire Mission Manager", {
            "Add Fire Mission", "List Fire Missions", "Edit Fire Mission",
            "Delete Fire Mission", "Execute Fire Missions", "Return To Main Menu"
        })
        if choice == 1 then AegisOS.missions.addMission()
        elseif choice == 2 then AegisOS.missions.listMissions()
        elseif choice == 3 then AegisOS.missions.editMission()
        elseif choice == 4 then AegisOS.missions.deleteMission()
        elseif choice == 5 then AegisOS.missions.executeMissions()
        elseif choice == 6 then break end
    end
end

function apps.parameterSettings()
    while true do
        local choice = AegisOS.ui.showMenu("Modify Parameters", {
            "Modify Center Point", "Modify Muzzle Point", "Modify Physics Parameters",
            "Modify GearShift IDs", "Modify Redstone Signal Directions",
            "Calibrate Canon Position", "Return to Main Menu"
        })
        local config = AegisOS.config.getConfig()
        local saved = false
        if choice == 1 then
            config.centerPoint = AegisOS.config.modifyPoint("Center Point", config.centerPoint)
            if AegisOS.config.saveConfig(config) then AegisOS.ui.showMessage("Center Point updated successfully!", 2) else AegisOS.ui.showMessage("Failed to update Center Point.", 2) end
        elseif choice == 2 then
            config.muzzlePoint = AegisOS.config.modifyPoint("Muzzle Point", config.muzzlePoint)
            if AegisOS.config.saveConfig(config) then AegisOS.ui.showMessage("Muzzle Point updated successfully!", 2) else AegisOS.ui.showMessage("Failed to update Muzzle Point.", 2) end
        elseif choice == 3 then
            config.physics = AegisOS.config.modifyPhysics(config.physics or {})
            if AegisOS.config.saveConfig(config) then AegisOS.ui.showMessage("Physics Parameters updated successfully!", 2) else AegisOS.ui.showMessage("Failed to update Physics Parameters.", 2) end
        elseif choice == 4 then
            config.gearShiftIDs = AegisOS.config.modifyGearshiftIDs(config.gearShiftIDs or {})
            if AegisOS.config.saveConfig(config) then AegisOS.ui.showMessage("GearShift IDs updated successfully!", 2) else AegisOS.ui.showMessage("Failed to update GearShift IDs.", 2) end
        elseif choice == 5 then
            config.redstoneDirections = AegisOS.config.modifyRedstoneDirection(config.redstoneDirections or {})
            if AegisOS.config.saveConfig(config) then AegisOS.ui.showMessage("Redstone Directions updated successfully!", 2) else AegisOS.ui.showMessage("Failed to update Redstone Directions.", 2) end
        elseif choice == 6 then
            AegisOS.canon.calibrate()
        elseif choice == 7 then break end
    end
end

function apps.manualOverride()
    AegisOS.ui.drawHeader("Manual Override")
    local yawAngle = tonumber(AegisOS.ui.prompt("Insert Yaw:"))
    local pitchAngle = tonumber(AegisOS.ui.prompt("Insert Pitch:"))
    local config = AegisOS.config.getConfig()
    local yawData = { angle = yawAngle, id = config.gearShiftIDs.yaw }
    local pitchData = { angle = pitchAngle, id = config.gearShiftIDs.pitch }
    local triggerSide = config.redstoneDirections.trigger
    AegisOS.canon.moveCanon(yawData, pitchData, triggerSide)
    AegisOS.ui.showMessage("Manual movement completed.", 2)
end

return apps