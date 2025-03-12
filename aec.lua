local common = require "common"
local controls = require "canonControl"

local configFilePath = "config.json"

local function modifyParameters()
    common.termClear()
    print("=====Modify Parameters=====")
    print("1. Modify Center Point")
    print("2. Modify Muzzle Point")
    print("3. Return to Main Menu")
    print("=====Select Option=====")
    
    local intOpt = tonumber(read())
    
    -- Load current config
    local config = common.readFromJsonFile(configFilePath)
    if not config then
        config = {
            centerPoint = { x = 0, y = 0, z = 0 },
            muzzlePoint = { x = 0, y = 0, z = 0 }
        }
    end
    
    if intOpt == 1 then
        -- Modify center point
        common.termClear()
        print("Current Center Point:")
        print("X: " .. (config.centerPoint and config.centerPoint.x or 0))
        print("Y: " .. (config.centerPoint and config.centerPoint.y or 0))
        print("Z: " .. (config.centerPoint and config.centerPoint.z or 0))
        print("\nEnter new values (leave blank to keep current):")
        
        print("Enter X coordinate:")
        local x = read()
        if x ~= "" then config.centerPoint.x = tonumber(x) end
        
        print("Enter Y coordinate:")
        local y = read()
        if y ~= "" then config.centerPoint.y = tonumber(y) end
        
        print("Enter Z coordinate:")
        local z = read()
        if z ~= "" then config.centerPoint.z = tonumber(z) end
        
        -- Save updated config
        if common.writeToJsonFile(config, configFilePath) then
            print("Center Point updated successfully!")
        else
            print("Failed to update Center Point.")
        end
        sleep(2)
        
    elseif intOpt == 2 then
        -- Modify muzzle point
        common.termClear()
        print("Current Muzzle Point:")
        print("X: " .. (config.muzzlePoint and config.muzzlePoint.x or 0))
        print("Y: " .. (config.muzzlePoint and config.muzzlePoint.y or 0))
        print("Z: " .. (config.muzzlePoint and config.muzzlePoint.z or 0))
        print("\nEnter new values (leave blank to keep current):")
        
        print("Enter X coordinate:")
        local x = read()
        if x ~= "" then config.muzzlePoint.x = tonumber(x) end
        
        print("Enter Y coordinate:")
        local y = read()
        if y ~= "" then config.muzzlePoint.y = tonumber(y) end
        
        print("Enter Z coordinate:")
        local z = read()
        if z ~= "" then config.muzzlePoint.z = tonumber(z) end
        
        -- Save updated config
        if common.writeToJsonFile(config, configFilePath) then
            print("Muzzle Point updated successfully!")
        else
            print("Failed to update Muzzle Point.")
        end
        sleep(2)
        
    elseif intOpt == 3 then
        return
    end
end

while true do
    common.redstoneToggle('top', true)
    common.termClear()
    print("=====Aegis Control=====")
    print("1. Fire Mission")
    print("2. Manual Override")
    print("3. Modify Parameters")
    print("4. Shutdown")
    print("=====Select Option=====")
    local intOpt = tonumber(read())
    if intOpt == 1 then
        shell.run("fireMissionManager.lua")
    elseif intOpt == 2 then
        common.termClear()
        print("Insert Yaw")
        local yawAngle = tonumber(read())
        print("Insert Pitch")
        local pitchAngle = tonumber(read())

        local yawData = {}
        local pitchData = {}

        yawData['angle'] = yawAngle
        yawData['id'] = 0

        pitchData['angle'] = pitchAngle
        pitchData['id'] = 1

        controls.moveCanon(yawData, pitchData, "back")

    elseif intOpt == 3 then
        modifyParameters()
    elseif intOpt == 4 then
        common.termClear()
        print("Shutting down...")
        common.redstoneToggle('top', false)
        sleep(2)
        common.termClear()
        return
    end
end
