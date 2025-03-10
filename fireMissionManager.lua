local common = require "common"
local control = require "canonControl"
local missionTablePath = "mission_table.json"
local configFilePath = "config.json"

-- Physics constants
local GRAVITY = 0.05  -- Minecraft gravity in blocks/tick²
local MAX_ITERATIONS = 1000  -- Maximum number of simulation steps
local TIME_STEP = 1  -- Simulation time step in ticks

-- Function to calculate drag coefficient based on angle
local function getDragCoefficient(angle)
    angle = math.abs(angle)
    if angle >= 25 then
        return 0.009375
    elseif angle >= 20 then
        return 0.0096875
    elseif angle >= 15 then
        return 0.0095
    else
        return 0.01
    end
end

-- Function to simulate projectile trajectory
local function simulateProjectile(startX, startY, startZ, velocity, pitch, yaw)
    local vx = velocity * math.cos(math.rad(pitch)) * math.sin(math.rad(yaw))
    local vy = velocity * math.sin(math.rad(pitch))
    local vz = velocity * math.cos(math.rad(pitch)) * math.cos(math.rad(yaw))
    
    local x, y, z = startX, startY, startZ
    local dragCoeff = getDragCoefficient(pitch)
    
    for i = 1, MAX_ITERATIONS do
        -- Update position
        x = x + vx
        y = y + vy
        z = z + vz
        
        -- Apply drag
        local speed = math.sqrt(vx*vx + vy*vy + vz*vz)
        local dragFactor = 1 - dragCoeff * speed
        vx = vx * dragFactor
        vy = vy * dragFactor
        vz = vz * dragFactor
        
        -- Apply gravity
        vy = vy - GRAVITY
        
        -- Check if projectile has hit the ground
        if y <= 0 then
            return x, 0, z, i * TIME_STEP  -- Return landing coordinates and time
        end
    end
    
    -- If we reach here, the projectile didn't land within MAX_ITERATIONS
    return nil, nil, nil, nil
end

-- Function to calculate pitch angle for a target
local function calculatePitchForTarget(startX, startY, startZ, targetX, targetY, targetZ, yaw)
    local initialVelocity = 160.0  -- Initial projectile velocity in blocks/tick
    local bestPitch = 31  -- Default pitch if calculation fails
    local bestDistance = math.huge
    
    -- Try various pitch angles to find the best one
    for pitch = 0, 60, 1 do
        local landX, landY, landZ, flightTime = simulateProjectile(startX, startY, startZ, initialVelocity, pitch, yaw)
        
        if landX and landY and landZ then
            local distance = math.sqrt((landX - targetX)^2 + (landZ - targetZ)^2)
            
            if distance < bestDistance then
                bestDistance = distance
                bestPitch = pitch
            end
        end
    end
    
    -- Fine-tune the pitch
    for pitch = bestPitch - 0.9, bestPitch + 0.9, 0.1 do
        local landX, landY, landZ, flightTime = simulateProjectile(startX, startY, startZ, initialVelocity, pitch, yaw)
        
        if landX and landY and landZ then
            local distance = math.sqrt((landX - targetX)^2 + (landZ - targetZ)^2)
            
            if distance < bestDistance then
                bestDistance = distance
                bestPitch = pitch
            end
        end
    end
    
    return bestPitch, bestDistance
end


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
    local config = common.readFromJsonFile(configFilePath) or {
        centerPoint = {x=0, y=0, z=0},
        muzzlePoint = {x=0, y=0, z=0}
    }
    
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
        
        -- Calculate yaw
        local targetPoint = vector.new(mission.point.x, 0, mission.point.z)
        local yawAngle = findYaw(targetPoint)
        
        -- Calculate distance to target (2D)
        local startX = config.centerPoint.x
        local startY = config.centerPoint.y or 0
        local startZ = config.centerPoint.z
        local targetX = mission.point.x
        local targetY = mission.point.y or 0
        local targetZ = mission.point.z
        
        -- Calculate pitch using physics simulation
        print("Calculating optimal pitch angle...")
        local pitchAngle, expectedError = calculatePitchForTarget(
            startX, startY, startZ, 
            targetX, targetY, targetZ, 
            yawAngle
        )
        
        print("Calculated Yaw: " .. string.format("%.2f", yawAngle) .. "°")
        print("Calculated Pitch: " .. string.format("%.2f", pitchAngle) .. "°")
        print("Expected accuracy: " .. string.format("%.2f", expectedError) .. " blocks")
        sleep(1)
        
        local yawData = {}
        yawData['angle'] = yawAngle
        yawData['id'] = 0
        
        local pitchData = {}
        pitchData['angle'] = pitchAngle
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
