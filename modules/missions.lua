local missions_module = {}

function missions_module.getMissions()
    return AegisOS.utils.readFromJsonFile(AegisOS.paths.missionTable) or {}
end

function missions_module.saveMissions(missions)
    return AegisOS.utils.writeToJsonFile(missions, AegisOS.paths.missionTable)
end

function missions_module.addMission()
    AegisOS.ui.drawHeader("Add Fire Mission")
    local mission = {
        point = {
            x = tonumber(AegisOS.ui.prompt("Enter Target X Coordinate:")),
            y = tonumber(AegisOS.ui.prompt("Enter Target Y Coordinate:")),
            z = tonumber(AegisOS.ui.prompt("Enter Target Z Coordinate:"))
        },
        munition = AegisOS.ui.prompt("Enter Munition Type (solid, explosive, incendiary):", "solid")
    }
    local missions = missions_module.getMissions()
    table.insert(missions, mission)
    if missions_module.saveMissions(missions) then AegisOS.ui.showMessage("Fire mission added successfully!", 2)
    else AegisOS.ui.showMessage("Failed to add fire mission.", 2) end
end

function missions_module.listMissions()
    local missions = missions_module.getMissions()
    if #missions == 0 then AegisOS.ui.showMessage("No fire missions found.", 2); return end
    local function display(m, i) return "Mission #"..i..": X="..m.point.x..", Y="..m.point.y..", Z="..m.point.z.." ("..m.munition..")" end
    local selection = AegisOS.ui.selectFromList("Fire Mission List", missions, display)
    if selection then
        local mission = missions[selection]
        AegisOS.ui.drawHeader("Mission Details")
        print("Mission #" .. selection .. " | Target: X=" .. mission.point.x .. ", Y=" .. mission.point.y .. ", Z=" .. mission.point.z .. " | Munition: " .. mission.munition)
        AegisOS.ui.showMessage("")
    end
end

function missions_module.editMission()
    local missions = missions_module.getMissions()
    if #missions == 0 then AegisOS.ui.showMessage("No fire missions found.", 2); return end
    local function display(m, i) return "Mission #"..i..": X="..m.point.x..", Y="..m.point.y..", Z="..m.point.z.." ("..m.munition..")" end
    local selection = AegisOS.ui.selectFromList("Select Mission to Edit", missions, display)
    if not selection then return end
    local mission = missions[selection]
    AegisOS.utils.clearScreen()
    print("Editing Mission #" .. selection .. ". Leave blank to keep current values.")
    local x = AegisOS.ui.prompt("Enter X coordinate ("..mission.point.x.."):"); if x ~= "" then mission.point.x = tonumber(x) end
    local y = AegisOS.ui.prompt("Enter Y coordinate ("..mission.point.y.."):"); if y ~= "" then mission.point.y = tonumber(y) end
    local z = AegisOS.ui.prompt("Enter Z coordinate ("..mission.point.z.."):"); if z ~= "" then mission.point.z = tonumber(z) end
    local munition = AegisOS.ui.prompt("Enter Munition Type ("..mission.munition.."):"); if munition ~= "" then mission.munition = munition end
    if missions_module.saveMissions(missions) then AegisOS.ui.showMessage("Fire mission updated successfully!", 2)
    else AegisOS.ui.showMessage("Failed to update fire mission.", 2) end
end

function missions_module.deleteMission()
    local missions = missions_module.getMissions()
    if #missions == 0 then AegisOS.ui.showMessage("No fire missions found.", 2); return end
    local displayOptions = {}
    for i, m in ipairs(missions) do table.insert(displayOptions, m) end
    table.insert(displayOptions, {special = "delete_all"})
    local function display(item, index)
        if item.special and item.special == "delete_all" then return "DELETE ALL MISSIONS"
        else return "Mission #"..index..": X="..item.point.x..", Y="..item.point.y..", Z="..item.point.z end
    end
    local selection, selectedItem = AegisOS.ui.selectFromList("Select Mission to Delete", displayOptions, display)
    if not selection then return end

    if selectedItem.special and selectedItem.special == "delete_all" then
        if AegisOS.ui.showMenu("Confirm Delete All", {"Yes, delete all", "No, cancel"}) == 1 then
            if missions_module.saveMissions({}) then AegisOS.ui.showMessage("All missions deleted.", 2) else AegisOS.ui.showMessage("Failed to delete missions.", 2) end
        else AegisOS.ui.showMessage("Deletion cancelled.", 2) end
    else
        if AegisOS.ui.showMenu("Confirm Delete Mission #"..selection, {"Yes, delete", "No, cancel"}) == 1 then
            table.remove(missions, selection)
            if missions_module.saveMissions(missions) then AegisOS.ui.showMessage("Mission deleted.", 2) else AegisOS.ui.showMessage("Failed to delete mission.", 2) end
        else AegisOS.ui.showMessage("Deletion cancelled.", 2) end
    end
end

function missions_module.executeMissions()
    local missions = missions_module.getMissions()
    local config = AegisOS.config.getConfig()
    if #missions == 0 then AegisOS.ui.showMessage("No fire missions found.", 2); return end
    local choice = AegisOS.ui.showMenu("Execute Fire Missions", {"Execute All", "Select Single Mission", "Cancel"})
    
    if choice == 3 then return
    elseif choice == 2 then
        local function display(m, i) return "Mission #"..i..": X="..m.point.x..", Y="..m.point.y..", Z="..m.point.z end
        local selection = AegisOS.ui.selectFromList("Select Mission to Execute", missions, display)
        if not selection then return end
        missions = {missions[selection]}
    end
    
    print("Total Missions to Execute: " .. #missions); sleep(3)
    
    for index, mission in ipairs(missions) do
        AegisOS.utils.clearScreen()
        print("Executing Mission #" .. index .. " | Target: X="..mission.point.x..", Y="..mission.point.y..", Z="..mission.point.z)
        local targetPoint = vector.new(mission.point.x, 0, mission.point.z)
        local yawAngle = AegisOS.ballistics.findYaw(targetPoint)
        local startX = config.centerPoint.x + config.physics.barrelLength * math.sin(math.rad(yawAngle))
        local startY = config.centerPoint.y - 0.5
        local startZ = config.centerPoint.z + config.physics.barrelLength * math.cos(math.rad(yawAngle))
        print("Calculating optimal pitch angle...")
        local pitchAngle, expectedError = AegisOS.ballistics.calculatePitchForTarget(startX, startY, startZ, mission.point.x, mission.point.y, mission.point.z, yawAngle)
        print("Calculated Yaw: " .. string.format("%.2f", yawAngle) .. "° | Pitch: " .. string.format("%.2f", pitchAngle) .. "° | Accuracy: " .. string.format("%.2f", expectedError) .. " blocks")
        sleep(1)
        
        local yawData = { angle = yawAngle, id = config.gearShiftIDs.yaw }
        local pitchData = { angle = pitchAngle, id = config.gearShiftIDs.pitch }
        print("Moving cannon...")
        AegisOS.canon.moveCanon(yawData, pitchData, config.redstoneDirections.trigger)
        print("Fire mission completed!")
        if index < #missions then print("\nPress Enter for next mission..."); read() else sleep(2) end
    end
    AegisOS.ui.showMessage("All fire missions executed successfully!", 2)
end

return missions_module