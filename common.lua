local common = {}

function common.termClear()
    term.clear()
    term.setCursorPos(1,1)
    return nil
end

function common.redstoneBlink(side, duration)

    sleep(duration / 2)
    redstone.setOutput(side, not redstone.getOutput(side))
    sleep(duration / 2)
    redstone.setOutput(side, not redstone.getOutput(side))
    return nil
end

function common.redstoneToggle(side, toggle)

    if redstone.getOutput(side) == toggle then
        return
    end
    redstone.setOutput(side, toggle)

    return nil

end

function common.readFromJsonFile(filePath)
    -- Check if the file exists
    if not fs.exists(filePath) then
        print("Warning: Mission table file does not exist at " .. filePath)
        return {}
    end
    
    -- Open and read the file
    local file = fs.open(filePath, "r")
    if not file then
        print("Error: Unable to open mission table file at " .. filePath)
        return {}
    end
    
    -- Read the entire content
    local content = file.readAll()
    file.close()
    
    -- Parse the JSON data
    local success, data = pcall(textutils.unserializeJSON, content)
    if not success or type(data) ~= "table" then
        print("Error: Failed to parse mission table JSON data. File may be corrupted.")
        return {}
    end
    
    return data
end

function common.writeToJsonFile(data, filePath)
    -- Input validation
    if not data then
        print("Error: No data provided to write to mission table")
        return false
    end
    
    if type(data) ~= "table" then
        print("Error: Data must be a table to write to mission table")
        return false
    end
    
    local isEmpty = true
    for _ in pairs(data) do
        isEmpty = false
        break
    end
    
    if isEmpty then
        print("Warning: Writing empty table to mission table")
    end
    
    if not filePath then
        print("Error: Mission table path is not defined")
        return false
    end
    
    -- Serialize the table to JSON format
    local success, serialized = pcall(textutils.serializeJSON, data)
    if not success then
        print("Error: Failed to serialize data to JSON")
        return false
    end
    
    -- Write to file
    local file = fs.open(filePath, "w")
    if not file then
        print("Error: Unable to create mission table file at " .. filePath)
        return false
    end
    
    file.write(serialized)
    file.close()
    
    return true
end

return common