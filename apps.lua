local apps = {}

function apps.fireMissionManager(AegisOS)
    while true do
        local choice = AegisOS.ui.showMenu(AegisOS, "Fire Mission Manager", {
            "Add Fire Mission", "List Fire Missions", "Edit Fire Mission",
            "Delete Fire Mission", "Execute Fire Missions", "Return To Main Menu"
        })
        if choice == 1 then AegisOS.missions.addMission(AegisOS)
        elseif choice == 2 then AegisOS.missions.listMissions(AegisOS)
        elseif choice == 3 then AegisOS.missions.editMission(AegisOS)
        elseif choice == 4 then AegisOS.missions.deleteMission(AegisOS)
        elseif choice == 5 then AegisOS.missions.executeMissions(AegisOS)
        elseif choice == 6 then break end
    end
end

function apps.parameterSettings(AegisOS)
    while true do
        local choice = AegisOS.ui.showMenu(AegisOS, "Modify Parameters", {
            "Modify Center Point", "Modify Muzzle Point", "Modify Physics Parameters",
            "Modify GearShift IDs", "Modify Redstone Signal Directions",
            "Calibrate Canon Position", "Return to Main Menu"
        })
        local config = AegisOS.config.getConfig(AegisOS)
        local saved = false
        if choice == 1 then
            config.centerPoint = AegisOS.config.modifyPoint(AegisOS, "Center Point", config.centerPoint)
            if AegisOS.config.saveConfig(AegisOS, config) then AegisOS.ui.showMessage(AegisOS, "Center Point updated successfully!", 2) else AegisOS.ui.showMessage(AegisOS, "Failed to update Center Point.", 2) end
        elseif choice == 2 then
            config.muzzlePoint = AegisOS.config.modifyPoint(AegisOS, "Muzzle Point", config.muzzlePoint)
            if AegisOS.config.saveConfig(AegisOS, config) then AegisOS.ui.showMessage(AegisOS, "Muzzle Point updated successfully!", 2) else AegisOS.ui.showMessage(AegisOS, "Failed to update Muzzle Point.", 2) end
        elseif choice == 3 then
            config.physics = AegisOS.config.modifyPhysics(AegisOS, config.physics or {})
            if AegisOS.config.saveConfig(AegisOS, config) then AegisOS.ui.showMessage(AegisOS, "Physics Parameters updated successfully!", 2) else AegisOS.ui.showMessage(AegisOS, "Failed to update Physics Parameters.", 2) end
        elseif choice == 4 then
            config.gearShiftIDs = AegisOS.config.modifyGearshiftIDs(AegisOS, config.gearShiftIDs or {})
            if AegisOS.config.saveConfig(AegisOS, config) then AegisOS.ui.showMessage(AegisOS, "GearShift IDs updated successfully!", 2) else AegisOS.ui.showMessage(AegisOS, "Failed to update GearShift IDs.", 2) end
        elseif choice == 5 then
            config.redstoneDirections = AegisOS.config.modifyRedstoneDirection(AegisOS, config.redstoneDirections or {})
            if AegisOS.config.saveConfig(AegisOS, config) then AegisOS.ui.showMessage(AegisOS, "Redstone Directions updated successfully!", 2) else AegisOS.ui.showMessage(AegisOS, "Failed to update Redstone Directions.", 2) end
        elseif choice == 6 then
            AegisOS.canon.calibrate(AegisOS)
        elseif choice == 7 then break end
    end
end

-- apps.lua
function apps.manualOverride(AegisOS)
    AegisOS.ui.drawHeader(AegisOS, "Manual Override")
    local yawAngle = tonumber(AegisOS.ui.prompt(AegisOS, "Insert Yaw:")) or 0
    local pitchAngle = tonumber(AegisOS.ui.prompt(AegisOS, "Insert Pitch:")) or 0
    
    local config = AegisOS.config.getConfig(AegisOS)
    local yawData = { angle = yawAngle, id = config.gearShiftIDs.yaw }
    local pitchData = { angle = pitchAngle, id = config.gearShiftIDs.pitch }
    
    -- UPDATED: Passing the full redstoneDirections table
    AegisOS.canon.moveCanon(AegisOS, yawData, pitchData, config.redstoneDirections)
end

return apps