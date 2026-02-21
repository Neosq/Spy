local remote_spy_core = {}

local originalnamecall
local originalEvent = Instance.new("RemoteEvent").FireServer
local originalFunction = Instance.new("RemoteFunction").InvokeServer

local toggle = false
local blacklist = {}
local blocklist = {}
local connectedRemotes = {}
local history = {}
local excluding = {}

local NamecallHandler = Instance.new("BindableEvent")
local GetDebugIdHandler = Instance.new("BindableFunction")

local OldDebugId = game.GetDebugId

GetDebugIdHandler.OnInvoke = function(obj)
    return OldDebugId(obj)
end

local function ThreadGetDebugId(obj)
    return GetDebugIdHandler:Invoke(obj)
end

local function tablecheck(tabletocheck, instance, id)
    return tabletocheck[id] or tabletocheck[instance.Name]
end

local function remoteHandler(data)
    if configs.autoblock then
        local id = data.id
        if excluding[id] then
            return
        end
        if not history[id] then
            history[id] = {badOccurances = 0, lastCall = tick()}
        end
        if tick() - history[id].lastCall < 1 then
            history[id].badOccurances += 1
            if history[id].badOccurances > 3 then
                excluding[id] = true
                return
            end
        else
            history[id].badOccurances = 0
        end
        history[id].lastCall = tick()
    end

    if data.remote:IsA("RemoteEvent") and string.lower(data.method) == "fireserver" then
        newRemote("event", data)
    elseif data.remote:IsA("RemoteFunction") and string.lower(data.method) == "invokeserver" then
        newRemote("function", data)
    end
end

local function newindex(method, originalfunction, self, ...)
    if typeof(self) == "Instance" then
        local remote = cloneref(self)
        if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
            if not configs.logcheckcaller and checkcaller() then
                return originalfunction(self, ...)
            end
            local id = ThreadGetDebugId(remote)
            local blockcheck = tablecheck(blocklist, remote, id)
            local args = {...}

            if not tablecheck(blacklist, remote, id) and not IsCyclicTable(args) then
                local data = {
                    method = method,
                    remote = remote,
                    args = deepclone(args),
                    infofunc = nil,
                    callingscript = nil,
                    metamethod = "__index",
                    blocked = blockcheck,
                    id = id,
                    returnvalue = {}
                }

                if configs.funcEnabled then
                    data.infofunc = debug.info(2, "f")
                    local calling = getcallingscript and getcallingscript() or nil
                    data.callingscript = calling and cloneref(calling) or nil
                end

                schedule(remoteHandler, data)
            end

            if blockcheck then
                return
            end
        end
    end
    return originalfunction(self, ...)
end

local newnamecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    if method and (method == "FireServer" or method == "fireServer" or method == "InvokeServer" or method == "invokeServer") then
        if typeof(self) == "Instance" then
            local remote = cloneref(self)
            if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
                if not configs.logcheckcaller and checkcaller() then
                    return originalnamecall(self, ...)
                end
                local id = ThreadGetDebugId(remote)
                local blockcheck = tablecheck(blocklist, remote, id)
                local args = {...}

                if not tablecheck(blacklist, remote, id) and not IsCyclicTable(args) then
                    local data = {
                        method = method,
                        remote = remote,
                        args = deepclone(args),
                        infofunc = nil,
                        callingscript = nil,
                        metamethod = "__namecall",
                        blocked = blockcheck,
                        id = id,
                        returnvalue = {}
                    }

                    if configs.funcEnabled then
                        data.infofunc = debug.info(2, "f")
                        local calling = getcallingscript and getcallingscript() or nil
                        data.callingscript = calling and cloneref(calling) or nil
                    end

                    schedule(remoteHandler, data)
                end

                if blockcheck then
                    return
                end
            end
        end
    end
    return originalnamecall(self, ...)
end)

local newFireServer = newcclosure(function(self, ...)
    return newindex("FireServer", originalEvent, self, ...)
end)

local newInvokeServer = newcclosure(function(self, ...)
    return newindex("InvokeServer", originalFunction, self, ...)
end)

local function disablehooks()
    if syn and syn.v3 then
        syn.oth.unhook(getrawmetatable(game).__namecall, originalnamecall)
        syn.oth.unhook(Instance.new("RemoteEvent").FireServer, originalEvent)
        syn.oth.unhook(Instance.new("RemoteFunction").InvokeServer, originalFunction)
        restorefunction(originalnamecall)
        restorefunction(originalEvent)
        restorefunction(originalFunction)
    else
        if hookmetamethod then
            hookmetamethod(game, "__namecall", originalnamecall)
        else
            hookfunction(getrawmetatable(game).__namecall, originalnamecall)
        end
        hookfunction(Instance.new("RemoteEvent").FireServer, originalEvent)
        hookfunction(Instance.new("RemoteFunction").InvokeServer, originalFunction)
    end
end

local function toggleSpy()
    if not toggle then
        local oldnamecall
        if syn and syn.v3 then
            oldnamecall = syn.oth.hook(getrawmetatable(game).__namecall, clonefunction(newnamecall))
            originalEvent = syn.oth.hook(Instance.new("RemoteEvent").FireServer, clonefunction(newFireServer))
            originalFunction = syn.oth.hook(Instance.new("RemoteFunction").InvokeServer, clonefunction(newInvokeServer))
        else
            if hookmetamethod then
                oldnamecall = hookmetamethod(game, "__namecall", clonefunction(newnamecall))
            else
                oldnamecall = hookfunction(getrawmetatable(game).__namecall, clonefunction(newnamecall))
            end
            originalEvent = hookfunction(Instance.new("RemoteEvent").FireServer, clonefunction(newFireServer))
            originalFunction = hookfunction(Instance.new("RemoteFunction").InvokeServer, clonefunction(newInvokeServer))
        end
        originalnamecall = originalnamecall or function(...)
            return oldnamecall(...)
        end
    else
        disablehooks()
    end
end

remote_spy_core.toggleSpy = toggleSpy
remote_spy_core.disablehooks = disablehooks
remote_spy_core.toggle = toggle
remote_spy_core.blacklist = blacklist
remote_spy_core.blocklist = blocklist
remote_spy_core.connectedRemotes = connectedRemotes
remote_spy_core.history = history
remote_spy_core.excluding = excluding

return remote_spy_core
