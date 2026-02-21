local realconfigs = {
    logcheckcaller = false,
    autoblock = false,
    funcEnabled = true,
    advancedinfo = false,
    supersecretdevtoggle = false
}

local configs = newproxy(true)
local configsmetatable = getmetatable(configs)

configsmetatable.__index = function(self, index)
    return realconfigs[index]
end

if isfile and readfile and isfolder and makefolder and writefile then
    xpcall(function()
        if not isfolder("SimpleSpy") then
            makefolder("SimpleSpy")
        end
        if not isfolder("SimpleSpy/Assets") then
            makefolder("SimpleSpy/Assets")
        end
        
        local path = "SimpleSpy/Settings.json"
        if isfile(path) then
            local data = game:GetService("HttpService"):JSONDecode(readfile(path))
            for k, v in pairs(realconfigs) do
                if data[k] ~= nil then
                    realconfigs[k] = data[k]
                end
            end
        end
        
        configsmetatable.__newindex = function(_, key, value)
            realconfigs[key] = value
            writefile(path, game:GetService("HttpService"):JSONEncode(realconfigs))
        end
    end, function(err)
        warn("Config save/load error: " .. tostring(err))
    end)
else
    configsmetatable.__newindex = function(_, key, value)
        realconfigs[key] = value
    end
end

return configs
