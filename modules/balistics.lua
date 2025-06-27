local ballistics = {}

function ballistics.simulateProjectile(start_pos, initial_velocity, env_density, gravity_multiplier, targetY, verbose)
    local pos = vector.new(start_pos[1], start_pos[2], start_pos[3])
    local vel = vector.new(initial_velocity[1], initial_velocity[2], initial_velocity[3])
    local gravity = vector.new(0, -gravity_multiplier * AegisOS.constants.GRAVITY, 0)
    local trajectory = {vector.new(pos.x, pos.y, pos.z), vector.new(vel.x, vel.y, vel.z)}
    if verbose == nil then verbose = false end

    for tick = 1, AegisOS.constants.MAX_ITERATIONS do
        if (vel.x^2 + vel.y^2 + vel.z^2) < 1e-6 then break end
        local drag_force = vel:normalize():mul(-env_density * AegisOS.constants.DRAG * vel:length())
        local accel = drag_force + gravity
        local next_pos = pos + vel + accel:mul(0.5)
        local next_vel = vel + accel
        if next_pos.y < targetY then
            local dy = next_pos - pos
            local impact_pos = pos
            if dy.y ~= 0 then
                impact_pos = pos + dy:mul((targetY - pos.y) / dy.y)
            else
                impact_pos = next_pos
            end
            table.insert(trajectory, vector.new(impact_pos.x, impact_pos.y, impact_pos.z))
            break
        end
        pos, vel = next_pos, next_vel
        table.insert(trajectory, vector.new(pos.x, pos.y, pos.z)); table.insert(trajectory, vector.new(vel.x, vel.y, vel.z))
    end
    return trajectory
end

function ballistics.calculatePitchForTarget(startX, startY, startZ, targetX, targetY, targetZ, yawAngle)
    local config = AegisOS.config.getConfig()
    local phys = config.physics
    local dx = targetX - startX; local dz = targetZ - startZ
    local horizontalDistance = math.sqrt(dx^2 + dz^2)
    local dirX, dirZ = dx / horizontalDistance, dz / horizontalDistance
    local yawRad = math.rad(yawAngle)
    local forwardVec = vector.new(math.sin(yawRad), 0, math.cos(yawRad))
    local tipOffset = forwardVec * 0.5
    local bestAngle, minError = nil, math.huge
    local steps = { {min = -30, max = 60, step = 5}, {min = 0, max = 0, step = 0.45} }

    for pass = 1, 2 do
        local searchParams = steps[pass]
        if pass == 2 then
            if not bestAngle then break end
            searchParams.min = math.max(0, bestAngle - 5); searchParams.max = math.min(60, bestAngle + 5)
        end
        for angle = searchParams.min, searchParams.max, searchParams.step do
            local angleRad = math.rad(angle)
            local cosAngle = math.cos(angleRad); local sinAngle = math.sin(angleRad)
            local vx = phys.initialSpeed * cosAngle * dirX
            local vy = phys.initialSpeed * sinAngle
            local vz = phys.initialSpeed * cosAngle * dirZ
            local pitchVecY = phys.barrelLength * sinAngle
            local forwardOffset = forwardVec * (phys.barrelLength * cosAngle)
            local simStartX = config.centerPoint.x + forwardOffset.x + tipOffset.x
            local simStartY = startY + pitchVecY
            local simStartZ = config.centerPoint.z + forwardOffset.z + tipOffset.z

            local trajectory = AegisOS.ballistics.simulateProjectile({simStartX, simStartY, simStartZ}, {vx, vy, vz}, phys.environmentDensity, phys.gravityMultiplier, targetY)
            if #trajectory > 0 then
                local finalPos = trajectory[#trajectory]
                if finalPos and finalPos.x and finalPos.z then
                    local distError = math.sqrt((finalPos.x - targetX)^2 + (finalPos.y - targetY)^2 + (finalPos.z - targetZ)^2)
                    if distError < minError then minError, bestAngle = distError, angle end
                end
            end
        end
    end
    return bestAngle or 15, minError
end

function ballistics.findYaw(targetPoint)
    local config = AegisOS.config.getConfig()
    local basePoint = vector.new(config.centerPoint.x, 0, config.centerPoint.z)
    local muzzleEndPoint = vector.new(config.muzzlePoint.x, 0, config.muzzlePoint.z)
    local forwardVector = (muzzleEndPoint - basePoint):normalize()
    local targetVector = (targetPoint - basePoint):normalize()
    local dotProduct = forwardVector:dot(targetVector)
    local radian_angle = math.acos(math.min(1, math.max(-1, dotProduct)))
    local crossProduct = forwardVector.x * targetVector.z - forwardVector.z * targetVector.x
    if crossProduct < 0 then radian_angle = -radian_angle end
    return math.deg(radian_angle)
end

return ballistics