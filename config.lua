local configs = {
    logcheckcaller = false,
    autoblock = false,
    funcEnabled = true,
    advancedinfo = false,
    supersecretdevtoggle = false
}

if isfile and readfile and isfolder and makefolder and writefile then
    xpcall(function()
        if not isfolder("SimpleSpy") then makefolder("SimpleSpy") end
        if not isfolder("SimpleSpy/Assets") then makefolder("SimpleSpy/Assets") end
        
        local path = "SimpleSpy/Settings.json"
        if isfile(path) then
            local data = game:GetService("HttpService"):JSONDecode(readfile(path))
            for k, v in pairs(configs) do
                if data[k] ~= nil then
                    configs[k] = data[k]
                end
            end
        end
        
        local old_newindex = getmetatable(configs).__newindex or function(t,k,v) rawset(t,k,v) end
        setmetatable(configs, {
            __newindex = function(t, k, v)
                rawset(t, k, v)
                writefile(path, game:GetService("HttpService"):JSONEncode(t))
            end
        })
    end, function(err)
        warn("Config save/load error: " .. tostring(err))
    end)
end

return configs
