local utils = {}

local cloneref = cloneref or function(x) return x end
local clonefunction = clonefunction or function(x) return x end
local newcclosure = newcclosure or function(x) return x end
local hookfunction = hookfunction or function() end
local hookmetamethod = hookmetamethod or function() end
local getrawmetatable = getrawmetatable or function() end
local makewriteable = makewriteable or function(tbl) setreadonly(tbl, false) end
local makereadonly = makereadonly or function(tbl) setreadonly(tbl, true) end
local isreadonly = isreadonly or table.isfrozen or function() return false end

utils.blankfunction = function(...) return ... end

utils.get_thread_identity = (syn and syn.get_thread_identity) or getidentity or getthreadidentity
utils.set_thread_identity = (syn and syn.set_thread_identity) or setidentity
utils.islclosure = islclosure or is_l_closure
utils.threadfuncs = (utils.get_thread_identity and utils.set_thread_identity and true) or false

utils.getinfo = getinfo or utils.blankfunction
utils.getupvalues = getupvalues or debug.getupvalues or utils.blankfunction
utils.getconstants = getconstants or debug.getconstants or utils.blankfunction

utils.getcustomasset = getsynasset or getcustomasset
utils.getcallingscript = getcallingscript or utils.blankfunction

utils.request = request or (syn and syn.request)

utils.setclipboard = setclipboard or toclipboard or set_clipboard or (Clipboard and Clipboard.set) or function(...) warn("Clipboard not supported") end

utils.jsone = function(str) return game:GetService("HttpService"):JSONEncode(str) end
utils.jsond = function(str)
    local suc, err = pcall(game:GetService("HttpService").JSONDecode, game:GetService("HttpService"), str)
    return suc and err or suc
end

utils.ErrorPrompt = function(Message, state)
    if getrenv then
        local ErrorPrompt = getrenv().require(game:GetService("CoreGui"):WaitForChild("RobloxGui"):WaitForChild("Modules"):WaitForChild("ErrorPrompt"))
        local prompt = ErrorPrompt.new("Default", {HideErrorCode = true})
        local ErrorStorage = Create("ScreenGui", {Parent = game:GetService("CoreGui"), ResetOnSpawn = false})
        local thread = state and coroutine.running()
        prompt:setParent(ErrorStorage)
        prompt:setErrorTitle("Simple Spy V3 Error")
        prompt:updateButtons({{
            Text = "Proceed",
            Callback = function()
                prompt:_close()
                ErrorStorage:Destroy()
                if thread then coroutine.resume(thread) end
            end,
            Primary = true
        }}, 'Default')
        prompt:_open(Message)
        if thread then coroutine.yield() end
    else
        warn(Message)
    end
end

utils.deepclone = function(args, copies)
    copies = copies or {}
    local copy
    if type(args) == 'table' then
        if copies[args] then
            copy = copies[args]
        else
            copy = {}
            copies[args] = copy
            for i, v in next, args do
                copy[utils.deepclone(i, copies)] = utils.deepclone(v, copies)
            end
        end
    elseif typeof(args) == "Instance" then
        copy = cloneref(args)
    else
        copy = args
    end
    return copy
end

utils.IsCyclicTable = function(tbl)
    local checkedtables = {}
    local function SearchTable(tbl)
        table.insert(checkedtables, tbl)
        for _, v in next, tbl do
            if type(v) == "table" then
                if table.find(checkedtables, v) then
                    return true
                end
                if SearchTable(v) then
                    return true
                end
            end
        end
        return false
    end
    return SearchTable(tbl)
end

utils.rawtostring = function(userdata)
    if type(userdata) == "table" or typeof(userdata) == "userdata" then
        local rawmetatable = getrawmetatable(userdata)
        local cachedstring = rawmetatable and rawget(rawmetatable, "__tostring")
        if cachedstring then
            local wasreadonly = isreadonly(rawmetatable)
            if wasreadonly then makewriteable(rawmetatable) end
            rawset(rawmetatable, "__tostring", nil)
            local safestring = tostring(userdata)
            rawset(rawmetatable, "__tostring", cachedstring)
            if wasreadonly then makereadonly(rawmetatable) end
            return safestring
        end
    end
    return tostring(userdata)
end

utils.getPlayerFromInstance = function(instance)
    for _, v in next, game:GetService("Players"):GetPlayers() do
        if v.Character and (instance:IsDescendantOf(v.Character) or instance == v.Character) then
            return v
        end
    end
end

utils.schedule = function(f, ...)
    table.insert(scheduled, {f, ...})
end

utils.scheduleWait = function()
    local thread = coroutine.running()
    utils.schedule(function()
        coroutine.resume(thread)
    end)
    coroutine.yield()
end

utils.getScriptFromSrc = function(src)
    local realPath
    local runningTest
    local s, e
    local match = false
    if src:sub(1, 1) == "=" then
        realPath = game
        s = 2
    else
        runningTest = src:sub(2, e and e - 1 or -1)
        for _, v in next, getnilinstances() do
            if v.Name == runningTest then
                realPath = v
                break
            end
        end
        s = #runningTest + 1
    end
    if realPath then
        e = src:sub(s, -1):find("%.")
        local i = 0
        repeat
            i += 1
            if not e then
                runningTest = src:sub(s, -1)
                local test = realPath:FindFirstChild(runningTest)
                if test then realPath = test end
                match = true
            else
                runningTest = src:sub(s, e)
                local test = realPath:FindFirstChild(runningTest)
                local yeOld = e
                if test then
                    realPath = test
                    s = e + 2
                    e = src:sub(e + 2, -1):find("%.")
                    e = e and e + yeOld or e
                else
                    e = src:sub(e + 2, -1):find("%.")
                    e = e and e + yeOld or e
                end
            end
        until match or i >= 50
    end
    return realPath
end

return utils
