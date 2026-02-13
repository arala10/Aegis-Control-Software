local missions_module = {}

function missions_module.getMissions(AegisOS)
    return AegisOS.utils.readFromJsonFile(AegisOS, AegisOS.paths.missionTable) or {}
end

function missions_module.saveMissions(AegisOS, missions)
    return AegisOS.utils.writeToJsonFile(AegisOS, missions, AegisOS.paths.missionTable)
end

function missions_module.addMission(AegisOS)
    AegisOS.ui.drawHeader(AegisOS, "Add Fire Mission")
    local mission = {
        point = {
            x = tonumber(AegisOS.ui.prompt(AegisOS, "Enter Target X Coordinate:")),
            y = tonumber(AegisOS.ui.prompt(AegisOS, "Enter Target Y Coordinate:")),
            z = tonumber(AegisOS.ui.prompt(AegisOS, "Enter Target Z Coordinate:"))
        },
        munition = AegisOS.ui.prompt(AegisOS, "Enter Munition Type (solid, explosive, incendiary):", "solid")
    }
    local missions = AegisOS.missions.getMissions(AegisOS)
    table.insert(missions, mission)
    if AegisOS.missions.saveMissions(AegisOS, missions) then AegisOS.ui.showMessage(AegisOS, "Fire mission added successfully!", 2)
    else AegisOS.ui.showMessage(AegisOS, "Failed to add fire mission.", 2) end
end

function missions_module.listMissions(AegisOS)
    local missions = AegisOS.missions.getMissions(AegisOS)
    if #missions == 0 then AegisOS.ui.showMessage(AegisOS, "No fire missions found.", 2); return end
    local function display(m, i) return "Mission #"..i..": X="..m.point.x..", Y="..m.point.y..", Z="..m.point.z.." ("..m.munition..")" end
    local selection = AegisOS.ui.selectFromList(AegisOS, "Fire Mission List", missions, display)
    if selection then
        local mission = missions[selection]
        AegisOS.ui.drawHeader(AegisOS, "Mission Details")
        print("Mission #" .. selection .. " | Target: X=" .. mission.point.x .. ", Y=" .. mission.point.y .. ", Z=" .. mission.point.z .. " | Munition: " .. mission.munition)
        AegisOS.ui.showMessage(AegisOS, "")
    end
end

function missions_module.editMission(AegisOS)
    local missions = AegisOS.missions.getMissions(AegisOS)
    if #missions == 0 then AegisOS.ui.showMessage(AegisOS, "No fire missions found.", 2); return end
    local function display(m, i) return "Mission #"..i..": X="..m.point.x..", Y="..m.point.y..", Z="..m.point.z.." ("..m.munition..")" end
    local selection = AegisOS.ui.selectFromList(AegisOS, "Select Mission to Edit", missions, display)
    if not selection then return end
    local mission = missions[selection]
    AegisOS.utils.clearScreen(AegisOS)
    print("Editing Mission #" .. selection .. ". Leave blank to keep current values.")
    local x = AegisOS.ui.prompt(AegisOS, "Enter X coordinate ("..mission.point.x.."):"); if x ~= "" then mission.point.x = tonumber(x) end
    local y = AegisOS.ui.prompt(AegisOS, "Enter Y coordinate ("..mission.point.y.."):"); if y ~= "" then mission.point.y = tonumber(y) end
    local z = AegisOS.ui.prompt(AegisOS, "Enter Z coordinate ("..mission.point.z.."):"); if z ~= "" then mission.point.z = tonumber(z) end
    local munition = AegisOS.ui.prompt(AegisOS, "Enter Munition Type ("..mission.munition.."):"); if munition ~= "" then mission.munition = munition end
    if AegisOS.missions.saveMissions(AegisOS, missions) then AegisOS.ui.showMessage(AegisOS, "Fire mission updated successfully!", 2)
    else AegisOS.ui.showMessage(AegisOS, "Failed to update fire mission.", 2) end
end

function missions_module.deleteMission(AegisOS)
    local missions = AegisOS.missions.getMissions(AegisOS)
    if #missions == 0 then AegisOS.ui.showMessage(AegisOS, "No fire missions found.", 2); return end
    local displayOptions = {}
    for i, m in ipairs(missions) do table.insert(displayOptions, m) end
    table.insert(displayOptions, {special = "delete_all"})
    local function display(item, index)
        if item.special and item.special == "delete_all" then return "DELETE ALL MISSIONS"
        else return "Mission #"..index..": X="..item.point.x..", Y="..item.point.y..", Z="..item.point.z end
    end
    local selection, selectedItem = AegisOS.ui.selectFromList(AegisOS, "Select Mission to Delete", displayOptions, display)
    if not selection then return end

    if selectedItem.special and selectedItem.special == "delete_all" then
        if AegisOS.ui.showMenu(AegisOS, "Confirm Delete All", {"Yes, delete all", "No, cancel"}) == 1 then
            if AegisOS.missions.saveMissions(AegisOS, {}) then AegisOS.ui.showMessage(AegisOS, "All missions deleted.", 2) else AegisOS.ui.showMessage(AegisOS, "Failed to delete missions.", 2) end
        else AegisOS.ui.showMessage(AegisOS, "Deletion cancelled.", 2) end
    else
        if AegisOS.ui.showMenu(AegisOS, "Confirm Delete Mission #"..selection, {"Yes, delete", "No, cancel"}) == 1 then
            table.remove(missions, selection)
            if AegisOS.missions.saveMissions(AegisOS, missions) then AegisOS.ui.showMessage(AegisOS, "Mission deleted.", 2) else AegisOS.ui.showMessage(AegisOS, "Failed to delete mission.", 2) end
        else AegisOS.ui.showMessage(AegisOS, "Deletion cancelled.", 2) end
    end
end

function missions_module.executeMissions(AegisOS)
    local missions = AegisOS.missions.getMissions(AegisOS)
    local config = AegisOS.config.getConfig(AegisOS)
    if #missions == 0 then AegisOS.ui.showMessage(AegisOS, "No fire missions found.", 2); return end
    local choice = AegisOS.ui.showMenu(AegisOS, "Execute Fire Missions", {"Execute All", "Select Single Mission", "Cancel"})
    
    if choice == 3 then return
    elseif choice == 2 then
        local function display(m, i) return "Mission #"..i..": X="..m.point.x..", Y="..m.point.y..", Z="..m.point.z end
        local selection = AegisOS.ui.selectFromList(AegisOS, "Select Mission to Execute", missions, display)
        if not selection then return end
        missions = {missions[selection]}
    end
    
    print("Total Missions to Execute: " .. #missions); sleep(3)
    
    for index, mission in ipairs(missions) do
        AegisOS.utils.clearScreen(AegisOS)
        print("Executing Mission #" .. index .. " | Target: X="..mission.point.x..", Y="..mission.point.y..", Z="..mission.point.z)
        local targetPoint = vector.new(mission.point.x, 0, mission.point.z)
        local yawAngle = AegisOS.ballistics.findYaw(AegisOS, targetPoint)
        local startX = config.centerPoint.x + config.physics.barrelLength * math.sin(math.rad(yawAngle))
        local startY = config.centerPoint.y - 0.5
        local startZ = config.centerPoint.z + config.physics.barrelLength * math.cos(math.rad(yawAngle))
        print("Calculating optimal pitch angle...")
        local pitchAngle, expectedError = AegisOS.ballistics.calculatePitchForTarget(AegisOS, startX, startY, startZ, mission.point.x, mission.point.y, mission.point.z, yawAngle)
        print("Calculated Yaw: " .. string.format("%.2f", yawAngle) .. "° | Pitch: " .. string.format("%.2f", pitchAngle) .. "° | Accuracy: " .. string.format("%.2f", expectedError) .. " blocks")
        sleep(1)
        
        local yawData = { angle = yawAngle, id = config.gearShiftIDs.yaw }
        local pitchData = { angle = pitchAngle, id = config.gearShiftIDs.pitch }
        print("Moving cannon...")
        AegisOS.canon.moveCanon(AegisOS, yawData, pitchData, config.redstoneDirections)
        print("Fire mission completed!")
        if index < #missions then print("\nPress Enter for next mission..."); read() else sleep(2) end
    end
    AegisOS.ui.showMessage(AegisOS, "All fire missions executed successfully!", 2)
end

return missions_module