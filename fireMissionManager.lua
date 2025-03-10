local common = require "common"
local control = require "canonControl"
local missionTablePath = "mission_table.json"
local configFilePath = "config.json"

local function addFireMission()
    common.termClear()
    print("=====Add Fire Mission=====")
    
    print("Enter Target X Coordinate")
    local targetX = tonumber(read())
    print("Enter Target Y Coordinate")
    local targetY = tonumber(read())
    print("Enter Target Z Coordinate")
    local targetZ = tonumber(read())
    
    print("Enter Munition Type (solid, explosive, incendiary)")
    local munitionType = read()
    if munitionType == "" then
        munitionType = "solid"
    end
    
    local fireMissionData = {}
    fireMissionData['point'] = {
        x = targetX,
        y = targetY,
        z = targetZ
    }
    fireMissionData['munition'] = munitionType
    
    local missionList = common.readFromJsonFile(missionTablePath) or {}
    table.insert(missionList, fireMissionData)
    
    if common.writeToJsonFile(missionList, missionTablePath) then
        print("Fire mission added successfully!")
    else
        print("Failed to add fire mission.")
    end
    sleep(2)
end

local function listFireMissions()
    common.termClear()
    print("=====Fire Mission List=====")
    
    local missionList = common.readFromJsonFile(missionTablePath) or {}
    
    if #missionList == 0 then
        print("No fire missions found.")
        sleep(2)
        return
    end
    
    for index, mission in pairs(missionList) do
        print("Mission #" .. index)
        print("  Target: X=" .. mission.point.x .. ", Y=" .. mission.point.y .. ", Z=" .. mission.point.z)
        print("  Munition: " .. mission.munition)
        print("---------------------------")
    end
    
    print("\nPress Enter to continue...")
    read()
end

local function editFireMission()
    common.termClear()
    print("=====Edit Fire Mission=====")
    
    local missionList = common.readFromJsonFile(missionTablePath) or {}
    
    if #missionList == 0 then
        print("No fire missions found.")
        sleep(2)
        return
    end
    
    print("Available Missions:")
    for index, mission in pairs(missionList) do
        print("#" .. index .. ": X=" .. mission.point.x .. ", Y=" .. mission.point.y .. ", Z=" .. mission.point.z)
    end
    
    print("\nEnter mission number to edit:")
    local missionIndex = tonumber(read())
    
    if not missionIndex or not missionList[missionIndex] then
        print("Invalid mission number.")
        sleep(2)
        return
    end
    
    local mission = missionList[missionIndex]
    common.termClear()
    print("Editing Mission #" .. missionIndex)
    print("Current Target: X=" .. mission.point.x .. ", Y=" .. mission.point.y .. ", Z=" .. mission.point.z)
    print("Current Munition: " .. mission.munition)
    print("\nEnter new values (leave blank to keep current):")
    
    print("Enter X coordinate:")
    local x = read()
    if x ~= "" then mission.point.x = tonumber(x) end
    
    print("Enter Y coordinate:")
    local y = read()
    if y ~= "" then mission.point.y = tonumber(y) end
    
    print("Enter Z coordinate:")
    local z = read()
    if z ~= "" then mission.point.z = tonumber(z) end
    
    print("Enter Munition Type (solid, explosive, incendiary):")
    local munitionType = read()
    if munitionType ~= "" then mission.munition = munitionType end
    
    if common.writeToJsonFile(missionList, missionTablePath) then
        print("Fire mission updated successfully!")
    else
        print("Failed to update fire mission.")
    end
    sleep(2)
end

local function deleteFireMission()
    common.termClear()
    print("=====Delete Fire Mission=====")
    
    local missionList = common.readFromJsonFile(missionTablePath) or {}
    
    if #missionList == 0 then
        print("No fire missions found.")
        sleep(2)
        return
    end
    
    print("Available Missions:")
    for index, mission in pairs(missionList) do
        print("#" .. index .. ": X=" .. mission.point.x .. ", Y=" .. mission.point.y .. ", Z=" .. mission.point.z)
    end
    
    print("\nEnter mission number to delete (or 'all' to clear all):")
    local input = read()
    
    if input == "all" then
        if common.writeToJsonFile({}, missionTablePath) then
            print("All fire missions deleted successfully!")
        else
            print("Failed to delete fire missions.")
        end
    else
        local missionIndex = tonumber(input)
        if not missionIndex or not missionList[missionIndex] then
            print("Invalid mission number.")
            sleep(2)
            return
        end
        
        print("Are you sure you want to delete mission #" .. missionIndex .. "? (y/n)")
        local confirm = read()
        if confirm:lower() == "y" then
            table.remove(missionList, missionIndex)
            if common.writeToJsonFile(missionList, missionTablePath) then
                print("Fire mission deleted successfully!")
            else
                print("Failed to delete fire mission.")
            end
        else
            print("Deletion cancelled.")
        end
    end
    sleep(2)
end

local function findYaw(targetPoint)
    local baseData = common.readFromJsonFile(configFilePath)

    local basePoint = vector.new(baseData.centerPoint.x, 0, baseData.centerPoint.z)
    local muzzleEndPoint = vector.new(baseData.muzzlePoint.x, 0, baseData.muzzlePoint.z)

    local forwwadVector = muzzleEndPoint - basePoint
    forwwadVector = forwwadVector:normalize()
    
    local targetVector = targetPoint - basePoint
    targetVector = targetVector:normalize()

    local radian_angle = math.acos(forwwadVector:dot(targetVector))
    
    return math.deg(radian_angle)
end

local function executeFireMission()
    common.termClear()
    print("=====Execute Fire Missions=====")
    
    local missionList = common.readFromJsonFile(missionTablePath) or {}
    
    if #missionList == 0 then
        print("No fire missions found.")
        sleep(2)
        return
    end
    
    print("Total Missions: " .. #missionList)
    print("Starting execution in 3 seconds...")
    sleep(3)
    
    for index, mission in pairs(missionList) do
        common.termClear()
        print("Executing Mission #" .. index)
        print("Target: X=" .. mission.point.x .. ", Y=" .. mission.point.y .. ", Z=" .. mission.point.z)
        print("Munition: " .. mission.munition)
        
        local targetPoint = vector.new(mission.point.x, 0, mission.point.z)
        local yawAngle = findYaw(targetPoint)
        
        print("Calculated Yaw: " .. yawAngle)
        
        local yawData = {}
        yawData['angle'] = yawAngle
        yawData['id'] = 0
        
        local pitchData = {}
        pitchData['angle'] = 0  -- You might want to calculate pitch based on distance/elevation
        pitchData['id'] = 1
        
        print("Moving cannon...")
        control.moveCanon(yawData, pitchData)
        print("Fire mission completed!")
        sleep(2)
    end
    
    print("All fire missions executed successfully!")
    sleep(2)
end

while true do
    common.termClear()
    print("=====Fire Mission Manager=====")
    print("1. Add Fire Mission")
    print("2. List Fire Missions")
    print("3. Edit Fire Mission")
    print("4. Delete Fire Mission")
    print("5. Execute Fire Missions")
    print("6. Return To Menu")
    print("=====Select Option=====")
    local intOpt = tonumber(read())

    if intOpt == 1 then
        addFireMission()
    elseif intOpt == 2 then
        listFireMissions()
    elseif intOpt == 3 then
        editFireMission()
    elseif intOpt == 4 then
        deleteFireMission()
    elseif intOpt == 5 then
        executeFireMission()
    elseif intOpt == 6 then
        break
    end
end
