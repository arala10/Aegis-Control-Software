local config_module = {}

function config_module.getConfig()
    local config = AegisOS.utils.readFromJsonFile(AegisOS.paths.config)
    local defaultConfig = {
        centerPoint = { x = 0, y = 0, z = 0 },
        muzzlePoint = { x = 0, y = 0, z = 0 },
        physics = { initialSpeed = 160.0, barrelLength = 9, environmentDensity = 1.0, gravityMultiplier = 1.0 },
        gearShiftIDs = { yaw = 0, pitch = 1 },
        redstoneDirections = { trigger = "back", power = "top" }
    }
    if not config then
        config = defaultConfig
    else
        if not config.centerPoint then config.centerPoint = defaultConfig.centerPoint end
        if not config.muzzlePoint then config.muzzlePoint = defaultConfig.muzzlePoint end
        if not config.physics then config.physics = defaultConfig.physics else
            if not config.physics.initialSpeed then config.physics.initialSpeed = defaultConfig.physics.initialSpeed end
            if not config.physics.barrelLength then config.physics.barrelLength = defaultConfig.physics.barrelLength end
            if not config.physics.environmentDensity then config.physics.environmentDensity = defaultConfig.physics.environmentDensity end
            if not config.physics.gravityMultiplier then config.physics.gravityMultiplier = defaultConfig.physics.gravityMultiplier end
        end
        if not config.gearShiftIDs then config.gearShiftIDs = defaultConfig.gearShiftIDs else
            if not config.gearShiftIDs.yaw then config.gearShiftIDs.yaw = defaultConfig.gearShiftIDs.yaw end
            if not config.gearShiftIDs.pitch then config.gearShiftIDs.pitch = defaultConfig.gearShiftIDs.pitch end
        end
        if not config.redstoneDirections then config.redstoneDirections = defaultConfig.redstoneDirections else
            if not config.redstoneDirections.trigger then config.redstoneDirections.trigger = defaultConfig.redstoneDirections.trigger end
            if not config.redstoneDirections.power then config.redstoneDirections.power = defaultConfig.redstoneDirections.power end
        end
    end
    AegisOS.config.saveConfig(config)
    return config
end

function config_module.saveConfig(config)
    return AegisOS.utils.writeToJsonFile(config, AegisOS.paths.config)
end

function config_module.modifyPoint(pointName, currentPoint)
    AegisOS.utils.clearScreen()
    print("Current " .. pointName .. ": X: " .. (currentPoint.x or 0) .. ", Y: " .. (currentPoint.y or 0) .. ", Z: " .. (currentPoint.z or 0))
    print("\nEnter new values (leave blank to keep current):")
    local x = AegisOS.ui.prompt("Enter X coordinate:")
    if x ~= "" then currentPoint.x = tonumber(x) end
    local y = AegisOS.ui.prompt("Enter Y coordinate:")
    if y ~= "" then currentPoint.y = tonumber(y) end
    local z = AegisOS.ui.prompt("Enter Z coordinate:")
    if z ~= "" then currentPoint.z = tonumber(z) end
    return currentPoint
end

function config_module.modifyPhysics(currentPhysics)
    AegisOS.utils.clearScreen()
    print("Current Physics: Speed=" .. (currentPhysics.initialSpeed or 160.0) .. ", Barrel=" .. (currentPhysics.barrelLength or 9) .. ", Density=" .. (currentPhysics.environmentDensity or 1.0) .. ", Gravity=" .. (currentPhysics.gravityMultiplier or 1.0))
    print("\nEnter new values (leave blank to keep current):")
    local speed = AegisOS.ui.prompt("Enter Initial Speed (default 160.0):")
    if speed ~= "" then currentPhysics.initialSpeed = tonumber(speed) end
    local length = AegisOS.ui.prompt("Enter Barrel Length (default 9):")
    if length ~= "" then currentPhysics.barrelLength = tonumber(length) end
    local density = AegisOS.ui.prompt("Enter Environment Density (default 1.0):")
    if density ~= "" then currentPhysics.environmentDensity = tonumber(density) end
    local gravity = AegisOS.ui.prompt("Enter Gravity Multiplier (default 1.0):")
    if gravity ~= "" then currentPhysics.gravityMultiplier = tonumber(gravity) end
    return currentPhysics
end

function config_module.modifyGearshiftIDs(currentIDs)
    AegisOS.utils.clearScreen()
    print("Current Gearshift IDs: Yaw=" .. (currentIDs.yaw or 0) .. ", Pitch=" .. (currentIDs.pitch or 0))
    print("\nEnter new values (leave blank to keep current):")
    local yawId = AegisOS.ui.prompt("Enter Yaw Sequenced Gearshift Id:")
    if yawId ~= "" then currentIDs.yaw = tonumber(yawId) end
    local pitchId = AegisOS.ui.prompt("Enter Pitch Sequenced Gearshift Id:")
    if pitchId ~= "" then currentIDs.pitch = tonumber(pitchId) end
    return currentIDs
end

function config_module.modifyRedstoneDirection(currentDirections)
    AegisOS.utils.clearScreen()
    print("Current Redstone Directions: Trigger=" .. (currentDirections.trigger or "back") .. ", Power=" .. (currentDirections.power or "top"))
    print("\nEnter new values (leave blank to keep current):")
    local directionMatrix = { [1] = "top", [2] = "right", [3] = "bottom", [4] = "left", [5] = "back" }
    local triggerDir = AegisOS.ui.prompt("Enter Redstone Directions for Trigger (1-5):")
    if triggerDir ~= "" then currentDirections.trigger = directionMatrix[tonumber(triggerDir)] end
    local powerDir = AegisOS.ui.prompt("Enter Redstone Directions for Power (1-5):")
    if powerDir ~= "" then currentDirections.power = directionMatrix[tonumber(powerDir)] end
    return currentDirections
end

return config_module