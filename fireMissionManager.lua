local common = require "common"
local control = require "canonControl"
local missionTablePath = "mission_table.json"
local configFilePath = "config.json"




local function addFireMission(fireMissionData)

    local oldMission = common.readFromJsonFile(missionTablePath)
    table.insert(oldMission, fireMissionData)
    common.writeToJsonFile(oldMission, missionTablePath)

end


local function findYaw(targetPoint)
    local baseData = common.readFromJsonFile(configFilePath)

    local basePoint = vector.new(baseData.centerPoint.x,0,baseData.centerPoint.z)
    local muzzleEndPoint = vector.new(baseData.muzzlePoint.x,0,baseData.muzzlePoint.z)

    local forwwadVector = muzzleEndPoint - basePoint
    forwwadVector = forwwadVector:normalize()
    
    local targetVector = targetPoint - basePoint
    targetVector = targetVector:normalize()

    local radian_angle = math.acos(forwwadVector:dot(targetVector))
    
    return math.deg(radian_angle)

end


local function executeFireMission()
   local missionList = common.readFromJsonFile(missionTablePath)
   
    print("Total Mission: "..table.getn(missionList))
    sleep(1)
    for index, value in pairs(missionList) do
        common.termClear()
        print("Mission Number: ".. index)
        local targetPoint = vector.new(value.point.x,0,value.point.z)
        local yawAngle = findYaw(targetPoint)
        
        local yawData = {}
        yawData['angle'] = yawAngle
        yawData['id'] = 0

        
        local pitchData = {}
        pitchData['angle'] = 0
        pitchData['id'] = 1
        
        control.moveCanon(yawData, pitchData)
    end
end


while true do
    common.termClear()
    print("=====Fire Mission Manager=====")
    print("1. Register Fire Mission")
    print("2. List Fire Mission")
    print("3. Edit Fire Mission")
    print("4. Execute Fire Mission")
    print("5. Return To Menu")
    print("=====Select Option=====")
    local intOpt = tonumber(read())

    if intOpt == 1 then
        common.termClear()
        print("Enter Target X Coordinate")
        local targetX = tonumber(read())
        print("Enter Target Y Coordinate")
        local targetY = tonumber(read())
        print("Enter Target Z Coordinate")
        local targetZ = tonumber(read())

        local fireMissionData = {}

        local targetPoint = vector.new(targetX, targetY, targetZ)

        fireMissionData['point'] = targetPoint
        fireMissionData['munition'] = "solid"

        addFireMission(fireMissionData)

    elseif intOpt == 2 then
    elseif intOpt == 3 then
    elseif intOpt == 4 then
        common.termClear()
        executeFireMission()
    elseif intOpt == 5 then
        break
    end

end