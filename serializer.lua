local serializer = {}

local indent = 4
local prevTables = {}
local topstr = ""
local bottomstr = ""
local getnilrequired = false

local number_table = {
    ["inf"] = "math.huge",
    ["-inf"] = "-math.huge",
    ["nan"] = "0/0"
}

local CustomGeneration = {
    Vector3 = (function()
        local temp = {}
        for i,v in Vector3 do
            if type(v) == "vector" then
                temp[v] = `Vector3.{i}`
            end
        end
        return temp
    end)(),
    Vector2 = (function()
        local temp = {}
        for i,v in Vector2 do
            if type(v) == "userdata" then
                temp[v] = `Vector2.{i}`
            end
        end
        return temp
    end)(),
    CFrame = {
        [CFrame.identity] = "CFrame.identity"
    }
}

local ufunctions = {
    TweenInfo = function(u)
        return `TweenInfo.new({u.Time}, {u.EasingStyle}, {u.EasingDirection}, {u.RepeatCount}, {u.Reverses}, {u.DelayTime})`
    end,
    Ray = function(u)
        return `Ray.new(Vector3.new({u.Origin.X},{u.Origin.Y},{u.Origin.Z}), Vector3.new({u.Direction.X},{u.Direction.Y},{u.Direction.Z}))`
    end,
    BrickColor = function(u)
        return `BrickColor.new({u.Number})`
    end,
    NumberRange = function(u)
        return `NumberRange.new({u.Min}, {u.Max})`
    end,
    Region3 = function(u)
        local center = u.CFrame.Position
        local centersize = u.Size/2
        return `Region3.new(Vector3.new({center.X-centersize.X},{center.Y-centersize.Y},{center.Z-centersize.Z}), Vector3.new({center.X+centersize.X},{center.Y+centersize.Y},{center.Z+centersize.Z}))`
    end,
    Faces = function(u)
        local faces = {}
        if u.Top then table.insert(faces, "Top") end
        if u.Bottom then table.insert(faces, "Enum.NormalId.Bottom") end
        if u.Left then table.insert(faces, "Enum.NormalId.Left") end
        if u.Right then table.insert(faces, "Enum.NormalId.Right") end
        if u.Back then table.insert(faces, "Enum.NormalId.Back") end
        if u.Front then table.insert(faces, "Enum.NormalId.Front") end
        return `Faces.new({table.concat(faces, ", ")})`
    end,
    EnumItem = function(u)
        return tostring(u)
    end,
    Enum = function(u)
        return `Enum.{u}`
    end,
    Vector3 = function(u)
        return CustomGeneration.Vector3[u] or `Vector3.new({u.X}, {u.Y}, {u.Z})`
    end,
    Vector2 = function(u)
        return CustomGeneration.Vector2[u] or `Vector2.new({u.X}, {u.Y})`
    end,
    CFrame = function(u)
        return CustomGeneration.CFrame[u] or `CFrame.new({table.concat({u:GetComponents()}, ", ")})`
    end,
    PathWaypoint = function(u)
        return `PathWaypoint.new(Vector3.new({u.Position.X},{u.Position.Y},{u.Position.Z}), {u.Action}, "{u.Label}")`
    end,
    UDim = function(u)
        return `UDim.new({u.Scale}, {u.Offset})`
    end,
    UDim2 = function(u)
        return `UDim2.new({u.X.Scale}, {u.X.Offset}, {u.Y.Scale}, {u.Y.Offset})`
    end,
    Rect = function(u)
        return `Rect.new(Vector2.new({u.Min.X},{u.Min.Y}), Vector2.new({u.Max.X},{u.Max.Y}))`
    end,
    Color3 = function(u)
        return `Color3.new({u.R}, {u.G}, {u.B})`
    end
}

local typeofv2sfunctions = {
    number = function(v)
        local number = tostring(v)
        return number_table[number] or number
    end,
    boolean = function(v)
        return tostring(v)
    end,
    string = function(v, l)
        return serializer.formatstr(v, l)
    end,
    ["function"] = function(v)
        return serializer.f2s(v)
    end,
    table = function(v, l, p, n, vtv, i, pt, path, tables, tI)
        return serializer.t2s(v, l, p, n, vtv, i, pt, path, tables, tI)
    end,
    Instance = function(v)
        return serializer.i2p(v, generation[game:GetService("GetDebugId")(v)])
    end,
    userdata = function(v)
        if configs.advancedinfo then
            if getrawmetatable(v) then
                return "newproxy(true)"
            end
            return "newproxy(false)"
        end
        return "newproxy(true)"
    end
}

local typev2sfunctions = {
    userdata = function(v, vtypeof)
        if ufunctions[vtypeof] then
            return ufunctions[vtypeof](v)
        end
        return `{vtypeof}({rawtostring(v)}) --[[Generation Failure]]`
    end,
    vector = ufunctions.Vector3
}

function serializer.v2s(v, l, p, n, vtv, i, pt, path, tables, tI)
    local vtypeof = typeof(v)
    local vtypeoffunc = typeofv2sfunctions[vtypeof]
    local vtypefunc = typev2sfunctions[type(v)]
    if not tI then tI = {0} else tI[1] += 1 end
    if vtypeoffunc then
        return vtypeoffunc(v, l, p, n, vtv, i, pt, path, tables, tI)
    elseif vtypefunc then
        return vtypefunc(v, vtypeof)
    end
    return `{vtypeof}({rawtostring(v)}) --[[Generation Failure]]`
end

function serializer.v2v(t)
    topstr = ""
    bottomstr = ""
    getnilrequired = false
    local ret = ""
    local count = 1
    for i, v in next, t do
        if type(i) == "string" and i:match("^[%a_]+[%w_]*$") then
            ret = ret .. "local " .. i .. " = " .. serializer.v2s(v, nil, nil, i, true) .. "\n"
        elseif rawtostring(i):match("^[%a_]+[%w_]*$") then
            ret = ret .. "local " .. string.lower(rawtostring(i)) .. "_" .. rawtostring(count) .. " = " .. serializer.v2s(v, nil, nil, string.lower(rawtostring(i)) .. "_" .. rawtostring(count), true) .. "\n"
        else
            ret = ret .. "local " .. type(v) .. "_" .. rawtostring(count) .. " = " .. serializer.v2s(v, nil, nil, type(v) .. "_" .. rawtostring(count), true) .. "\n"
        end
        count = count + 1
    end
    if getnilrequired then
        topstr = "function getNil(name,class) for _,v in next, getnilinstances() do if v.ClassName==class and v.Name==name then return v;end end end\n" .. topstr
    end
    if #topstr > 0 then
        ret = topstr .. "\n" .. ret
    end
    if #bottomstr > 0 then
        ret = ret .. bottomstr
    end
    return ret
end

function serializer.t2s(t, l, p, n, vtv, i, pt, path, tables, tI)
    local globalIndex = table.find(getgenv(), t)
    if type(globalIndex) == "string" then
        return globalIndex
    end
    if not tI then tI = {0} end
    if not path then path = "" end
    if not l then l = 0 tables = {} end
    if not p then p = t end
    for _, v in next, tables do
        if n and rawequal(v, t) then
            bottomstr = bottomstr .. "\n" .. rawtostring(n) .. rawtostring(path) .. " = " .. rawtostring(n) .. rawtostring(({serializer.v2p(v, p)})[2])
            return "{} --[[DUPLICATE]]"
        end
    end
    table.insert(tables, t)
    local s = "{"
    local size = 0
    l += indent
    for k, v in next, t do
        size = size + 1
        if size > (getgenv().SimpleSpyMaxTableSize or 1000) then
            s = s .. "\n" .. string.rep(" ", l) .. "-- MAXIMUM TABLE SIZE REACHED, CHANGE 'getgenv().SimpleSpyMaxTableSize' TO ADJUST MAXIMUM SIZE "
            break
        end
        if rawequal(k, t) then
            bottomstr = bottomstr .. `\n{n}{path}[{n}{path}] = {(rawequal(v,k) and `{n}{path}` or serializer.v2s(v, l, p, n, vtv, k, t, `{path}[{n}{path}]`, tables))}`
            size -= 1
            continue
        end
        local currentPath = ""
        if type(k) == "string" and k:match("^[%a_]+[%w_]*$") then
            currentPath = "." .. k
        else
            currentPath = "[" .. serializer.v2s(k, l, p, n, vtv, k, t, path .. currentPath, tables, tI) .. "]"
        end
        if size % 100 == 0 then
            task.wait()
        end
        s = s .. "\n" .. string.rep(" ", l) .. "[" .. serializer.v2s(k, l, p, n, vtv, k, t, path .. currentPath, tables, tI) .. "] = " .. serializer.v2s(v, l, p, n, vtv, k, t, path .. currentPath, tables, tI) .. ","
    end
    if #s > 1 then
        s = s:sub(1, #s - 1)
    end
    if size > 0 then
        s = s .. "\n" .. string.rep(" ", l - indent)
    end
    return s .. "}"
end

function serializer.f2s(f)
    for k, x in next, getgenv() do
        local isgucci, gpath
        if rawequal(x, f) then
            isgucci, gpath = true, ""
        elseif type(x) == "table" then
            isgucci, gpath = serializer.v2p(f, x)
        end
        if isgucci and type(k) ~= "function" then
            if type(k) == "string" and k:match("^[%a_]+[%w_]*$") then
                return k .. gpath
            else
                return "getgenv()[" .. serializer.v2s(k) .. "]" .. gpath
            end
        end
    end
    if configs.funcEnabled then
        local funcname = debug.info(f, "n")
        if funcname and funcname:match("^[%a_]+[%w_]*$") then
            return `function {funcname}() end -- Function Called: {funcname}`
        end
    end
    return tostring(f)
end

function serializer.i2p(i, customgen)
    if customgen then return customgen end
    local player = getPlayerFromInstance(i)
    local parent = i
    local out = ""
    if parent == nil then
        return "nil"
    elseif player then
        while true do
            if parent and parent == player.Character then
                if player == Players.LocalPlayer then
                    return 'game:GetService("Players").LocalPlayer.Character' .. out
                else
                    return serializer.i2p(player) .. ".Character" .. out
                end
            else
                if parent.Name:match("[%a_]+[%w+]*") ~= parent.Name then
                    out = ':FindFirstChild(' .. serializer.formatstr(parent.Name) .. ')' .. out
                else
                    out = "." .. parent.Name .. out
                end
            end
            parent = parent.Parent
        end
    elseif parent ~= game then
        while true do
            if parent and parent.Parent == game then
                if game:FindService(parent.ClassName) then
                    if string.lower(parent.ClassName) == "workspace" then
                        return `workspace{out}`
                    else
                        return 'game:GetService("' .. parent.ClassName .. '")' .. out
                    end
                else
                    if parent.Name:match("[%a_]+[%w_]*") then
                        return "game." .. parent.Name .. out
                    else
                        return 'game:FindFirstChild(' .. serializer.formatstr(parent.Name) .. ')' .. out
                    end
                end
            elseif not parent.Parent then
                getnilrequired = true
                return 'getNil(' .. serializer.formatstr(parent.Name) .. ', "' .. parent.ClassName .. '")' .. out
            else
                if parent.Name:match("[%a_]+[%w_]*") ~= parent.Name then
                    out = ':WaitForChild(' .. serializer.formatstr(parent.Name) .. ')' .. out
                else
                    out = ':WaitForChild("' .. parent.Name .. '")' .. out
                end
            end
            if i:IsDescendantOf(Players.LocalPlayer) then
                return 'game:GetService("Players").LocalPlayer' .. out
            end
            parent = parent.Parent
        end
    else
        return "game"
    end
end

function serializer.v2p(x, t, path, prev)
    if not path then path = "" end
    if not prev then prev = {} end
    if rawequal(x, t) then
        return true, ""
    end
    for i, v in next, t do
        if rawequal(v, x) then
            if type(i) == "string" and i:match("^[%a_]+[%w_]*$") then
                return true, (path .. "." .. i)
            else
                return true, (path .. "[" .. serializer.v2s(i) .. "]")
            end
        end
        if type(v) == "table" then
            local duplicate = false
            for _, y in next, prev do
                if rawequal(y, v) then
                    duplicate = true
                end
            end
            if not duplicate then
                table.insert(prev, t)
                local found, p = serializer.v2p(x, v, path, prev)
                if found then
                    if type(i) == "string" and i:match("^[%a_]+[%w_]*$") then
                        return true, "." .. i .. p
                    else
                        return true, "[" .. serializer.v2s(i) .. "]" .. p
                    end
                end
            end
        end
    end
    return false, ""
end

function serializer.formatstr(s, indentation)
    if not indentation then indentation = 0 end
    local handled, reachedMax = serializer.handlespecials(s, indentation)
    return '"' .. handled .. '"' .. (reachedMax and " --[[ MAXIMUM STRING SIZE REACHED, CHANGE 'getgenv().SimpleSpyMaxStringSize' TO ADJUST MAXIMUM SIZE ]]" or "")
end

function serializer.handlespecials(s, indentation)
    local i = 0
    local n = 1
    local coroutines = {}
    local coroutineFunc = function(i, r)
        s = s:sub(0, i - 1) .. r .. s:sub(i + 1, -1)
    end
    local timeout = 0
    repeat
        i += 1
        if timeout >= 10 then
            task.wait()
            timeout = 0
        end
        local char = s:sub(i, i)
        if string.byte(char) then
            timeout += 1
            local c = coroutine.create(coroutineFunc)
            table.insert(coroutines, c)
            if char == "\n" then
                coroutine.resume(c, i, "\\n")
                i += 1
            elseif char == "\t" then
                coroutine.resume(c, i, "\\t")
                i += 1
            elseif char == "\\" then
                coroutine.resume(c, i, "\\\\")
                i += 1
            elseif char == '"' then
                coroutine.resume(c, i, "\\\"")
                i += 1
            elseif string.byte(char) > 126 or string.byte(char) < 32 then
                coroutine.resume(c, i, "\\" .. string.byte(char))
                i += #tostring(string.byte(char))
            end
            if i >= n * 100 then
                local extra = '" ..\n' .. string.rep(" ", indentation + indent) .. '"'
                s = s:sub(0, i) .. extra .. s:sub(i + 1, -1)
                i += #extra
                n += 1
            end
        end
    until char == "" or i > (getgenv().SimpleSpyMaxStringSize or 10000)
    while true do
        local allDead = true
        for _, co in next, coroutines do
            if coroutine.status(co) ~= "dead" then
                allDead = false
                break
            end
        end
        if allDead then break end
        RunService.Heartbeat:Wait()
    end
    table.clear(coroutines)
    if i > (getgenv().SimpleSpyMaxStringSize or 10000) then
        s = string.sub(s, 0, getgenv().SimpleSpyMaxStringSize or 10000)
        return s, true
    end
    return s, false
end

function serializer.genScript(remote, args)
    prevTables = {}
    local gen = ""
    if #args > 0 then
        xpcall(function()
            gen = serializer.v2v({args = args}) .. "\n"
        end, function(err)
            gen = gen .. "-- An error has occured:\n--" .. err .. "\n-- TableToString failure! Reverting to legacy functionality (results may vary)\nlocal args = {"
            xpcall(function()
                for i, v in next, args do
                    if type(i) ~= "Instance" and type(i) ~= "userdata" then
                        gen = gen .. "\n    [object] = "
                    elseif type(i) == "string" then
                        gen = gen .. '\n    ["' .. i .. '"] = '
                    elseif type(i) == "userdata" and typeof(i) ~= "Instance" then
                        gen = gen .. "\n    [" .. string.format("nil --[[%s]]", typeof(v)) .. ")] = "
                    elseif type(i) == "userdata" then
                        gen = gen .. "\n    [game." .. i:GetFullName() .. ")] = "
                    end
                    if type(v) ~= "Instance" and type(v) ~= "userdata" then
                        gen = gen .. "object"
                    elseif type(v) == "string" then
                        gen = gen .. '"' .. v .. '"'
                    elseif type(v) == "userdata" and typeof(v) ~= "Instance" then
                        gen = gen .. string.format("nil --[[%s]]", typeof(v))
                    elseif type(v) == "userdata" then
                        gen = gen .. "game." .. v:GetFullName()
                    end
                end
                gen = gen .. "\n}\n\n"
            end, function()
                gen = gen .. "}\n-- Legacy tableToString failure! Unable to decompile."
            end)
        end)
        if not remote:IsDescendantOf(game) and not getnilrequired then
            gen = "function getNil(name,class) for _,v in next, getnilinstances()do if v.ClassName==class and v.Name==name then return v;end end end\n\n" .. gen
        end
        if remote:IsA("RemoteEvent") then
            gen = gen .. serializer.v2s(remote) .. ":FireServer(unpack(args))"
        elseif remote:IsA("RemoteFunction") then
            gen = gen .. serializer.v2s(remote) .. ":InvokeServer(unpack(args))"
        end
    else
        if remote:IsA("RemoteEvent") then
            gen = gen .. serializer.v2s(remote) .. ":FireServer()"
        elseif remote:IsA("RemoteFunction") then
            gen = gen .. serializer.v2s(remote) .. ":InvokeServer()"
        end
    end
    prevTables = {}
    return gen
end

return serializer
