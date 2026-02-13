local config_module = {}

-- Returns the full configuration table, merging with defaults if keys are missing
function config_module.getConfig(AegisOS)
    local config = AegisOS.utils.readFromJsonFile(AegisOS, AegisOS.paths.config)
    
    local defaultConfig = {
        centerPoint = { x = 0, y = 0, z = 0 },
        muzzlePoint = { x = 0, y = 0, z = 0 },
        physics = { initialSpeed = 160.0, barrelLength = 9, environmentDensity = 1.0, gravityMultiplier = 1.0 },
        gearShiftIDs = { yaw = 0, pitch = 1 },
        redstoneDirections = { 
            trigger = { controllerSide = "right", linkSide = "back" }, 
            power = { controllerSide = "right", linkSide = "top" },
            precision = { controllerSide = "right", linkSide = "front" }
        },
        blockReaderID = "blockReader_0"
    }

    if not config or next(config) == nil then
        config = defaultConfig
    else
        -- Ensure sub-tables exist to prevent nil errors
        config.centerPoint = config.centerPoint or defaultConfig.centerPoint
        config.muzzlePoint = config.muzzlePoint or defaultConfig.muzzlePoint
        config.physics = config.physics or defaultConfig.physics
        config.gearShiftIDs = config.gearShiftIDs or defaultConfig.gearShiftIDs
        config.redstoneDirections = config.redstoneDirections or defaultConfig.redstoneDirections
        config.blockReaderID = config.blockReaderID or defaultConfig.blockReaderID
        
        -- Ensure the new precision key exists
        if not config.redstoneDirections.precision then
            config.redstoneDirections.precision = defaultConfig.redstoneDirections.precision
        end
    end
    return config
end

function config_module.saveConfig(AegisOS, config)
    return AegisOS.utils.writeToJsonFile(AegisOS, config, AegisOS.paths.config)
end

function config_module.modifyPoint(AegisOS, name, currentPoint)
    AegisOS.utils.clearScreen(AegisOS)
    print("Modifying " .. name)
    print("Current: X=" .. currentPoint.x .. ", Y=" .. currentPoint.y .. ", Z=" .. currentPoint.z)
    
    local x = AegisOS.ui.prompt(AegisOS, "Enter X:")
    if x ~= "" then currentPoint.x = tonumber(x) end
    local y = AegisOS.ui.prompt(AegisOS, "Enter Y:")
    if y ~= "" then currentPoint.y = tonumber(y) end
    local z = AegisOS.ui.prompt(AegisOS, "Enter Z:")
    if z ~= "" then currentPoint.z = tonumber(z) end
    
    return currentPoint
end

function config_module.modifyPhysics(AegisOS, currentPhysics)
    AegisOS.utils.clearScreen(AegisOS)
    print("Physics Parameters")
    local speed = AegisOS.ui.prompt(AegisOS, "Initial Speed (" .. currentPhysics.initialSpeed .. "):")
    if speed ~= "" then currentPhysics.initialSpeed = tonumber(speed) end
    local length = AegisOS.ui.prompt(AegisOS, "Barrel Length (" .. currentPhysics.barrelLength .. "):")
    if length ~= "" then currentPhysics.barrelLength = tonumber(length) end
    local gravity = AegisOS.ui.prompt(AegisOS, "Gravity Mult (" .. currentPhysics.gravityMultiplier .. "):")
    if gravity ~= "" then currentPhysics.gravityMultiplier = tonumber(gravity) end
    return currentPhysics
end

function config_module.modifyGearshiftIDs(AegisOS, currentIDs)
    AegisOS.utils.clearScreen(AegisOS)
    local yId = AegisOS.ui.prompt(AegisOS, "Yaw Gearshift ID (" .. (currentIDs.yaw or 0) .. "):")
    if yId ~= "" then currentIDs.yaw = tonumber(yId) end
    local pId = AegisOS.ui.prompt(AegisOS, "Pitch Gearshift ID (" .. (currentIDs.pitch or 0) .. "):")
    if pId ~= "" then currentIDs.pitch = tonumber(pId) end
    return currentIDs
end

function config_module.modifyBlockReaderID(AegisOS, currentID)
    AegisOS.utils.clearScreen(AegisOS)
    print("Current Block Reader ID: " .. (currentID or "blockReader_0"))
    local newID = AegisOS.ui.prompt(AegisOS, "Enter new ID (e.g. blockReader_1):")
    return (newID ~= "") and newID or currentID
end

-- Simplified Wizard for Redstone Links and Computer Sides
function config_module.modifyRedstoneDirection(AegisOS, currentDirections)
    local function configureSignal(label, data)
        AegisOS.utils.clearScreen(AegisOS)
        print("Configuring: " .. string.upper(label))
        print("--------------------------------")
        print("Controller: " .. (data.controllerSide or "local"))
        print("Output Face: " .. (data.linkSide or "N/A"))
        print("--------------------------------")
        
        print("Use a Redstone Link/Integrator peripheral? (y/n)")
        local isPeripheral = string.lower(read()) == "y"
        
        local newController = "computer"
        if isPeripheral then
            print("\nConnected Peripherals:")
            local found = false
            for _, name in ipairs(peripheral.getNames()) do
                if peripheral.getType(name):find("redstone") then
                    print("- " .. name)
                    found = true
                end
            end
            if not found then print("(No redstone peripherals found on network)") end
            newController = AegisOS.ui.prompt(AegisOS, "Enter Peripheral Name:")
        else
            print("\nEnter Computer Side (top, bottom, left, right, front, back):")
            newController = read()
        end

        local faces = { "top", "bottom", "front", "back", "left", "right" }
        print("\nSelect Output Face:")
        for i, face in ipairs(faces) do print(i .. ". " .. face) end
        local choice = tonumber(read())
        local newFace = faces[choice] or data.linkSide

        return { controllerSide = newController, linkSide = newFace }
    end

    while true do
        local choice = AegisOS.ui.showMenu(AegisOS, "Redstone Interface Setup", {
            "Trigger (Fire)",
            "Power (Main)",
            "Precision (Gearbox)",
            "Back"
        })

        if choice == 1 then
            currentDirections.trigger = configureSignal("Trigger", currentDirections.trigger)
        elseif choice == 2 then
            currentDirections.power = configureSignal("Power", currentDirections.power)
        elseif choice == 3 then
            currentDirections.precision = configureSignal("Precision", currentDirections.precision)
        elseif choice == 4 then
            break
        end
    end
    return currentDirections
end

return config_module