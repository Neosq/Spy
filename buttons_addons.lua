local buttons_addons = {}

local function newButton(name, descriptionFunc, onClick)
    local FunctionTemplate = Instance.new("Frame")
    FunctionTemplate.Name = "FunctionTemplate"
    FunctionTemplate.Parent = ScrollingFrame
    FunctionTemplate.BackgroundColor3 = Color3.new(1, 1, 1)
    FunctionTemplate.BackgroundTransparency = 1
    FunctionTemplate.Size = UDim2.new(0, 117, 0, 23)

    local ColorBar = Instance.new("Frame")
    ColorBar.Name = "ColorBar"
    ColorBar.Parent = FunctionTemplate
    ColorBar.BackgroundColor3 = Color3.new(1, 1, 1)
    ColorBar.BorderSizePixel = 0
    ColorBar.Position = UDim2.new(0, 7, 0, 10)
    ColorBar.Size = UDim2.new(0, 7, 0, 18)
    ColorBar.ZIndex = 3

    local Text = Instance.new("TextLabel")
    Text.Text = name
    Text.Name = "Text"
    Text.Parent = FunctionTemplate
    Text.BackgroundColor3 = Color3.new(1, 1, 1)
    Text.BackgroundTransparency = 1
    Text.Position = UDim2.new(0, 19, 0, 10)
    Text.Size = UDim2.new(0, 69, 0, 18)
    Text.ZIndex = 2
    Text.Font = Enum.Font.SourceSans
    Text.TextColor3 = Color3.new(1, 1, 1)
    Text.TextSize = 14
    Text.TextXAlignment = Enum.TextXAlignment.Left

    local Button = Instance.new("TextButton")
    Button.Name = "Button"
    Button.Parent = FunctionTemplate
    Button.BackgroundColor3 = Color3.new(0, 0, 0)
    Button.BackgroundTransparency = 0.7
    Button.BorderColor3 = Color3.new(1, 1, 1)
    Button.Position = UDim2.new(0, 7, 0, 10)
    Button.Size = UDim2.new(0, 80, 0, 18)
    Button.AutoButtonColor = false
    Button.Font = Enum.Font.SourceSans
    Button.Text = ""
    Button.TextColor3 = Color3.new(0, 0, 0)
    Button.TextSize = 14

    Button.MouseEnter:Connect(function()
        makeToolTip(true, descriptionFunc())
    end)

    Button.MouseLeave:Connect(function()
        makeToolTip(false)
    end)

    FunctionTemplate.AncestryChanged:Connect(function()
        makeToolTip(false)
    end)

    Button.MouseButton1Click:Connect(function(...)
        logthread(coroutine.running())
        onClick(FunctionTemplate, ...)
    end)

    updateFunctionCanvas()
end

newButton(
    "Copy Code",
    function() return "Click to copy code" end,
    function()
        setclipboard(codebox:getString())
        TextLabel.Text = "Copied successfully!"
    end
)

newButton(
    "Copy Remote",
    function() return "Click to copy the path of the remote" end,
    function()
        if selected and selected.Remote then
            setclipboard(v2s(selected.Remote))
            TextLabel.Text = "Copied!"
        end
    end
)

newButton(
    "Run Code",
    function() return "Click to execute code" end,
    function()
        local Remote = selected and selected.Remote
        if Remote then
            TextLabel.Text = "Executing..."
            xpcall(function()
                local returnvalue
                if Remote:IsA("RemoteEvent") then
                    returnvalue = Remote:FireServer(unpack(selected.args))
                else
                    returnvalue = Remote:InvokeServer(unpack(selected.args))
                end
                TextLabel.Text = ("Executed successfully!\n%s"):format(v2s(returnvalue))
            end, function(err)
                TextLabel.Text = ("Execution error!\n%s"):format(err)
            end)
            return
        end
        TextLabel.Text = "Source not found"
    end
)

newButton(
    "Get Script",
    function() return "Click to copy calling script to clipboard\nWARNING: Not super reliable, nil == could not find" end,
    function()
        if selected then
            if not selected.Source then
                selected.Source = rawget(getfenv(selected.Function), "script")
            end
            setclipboard(v2s(selected.Source))
            TextLabel.Text = "Done!"
        end
    end
)

newButton(
    "Function Info",
    function() return "Click to view calling function information" end,
    function()
        local func = selected and selected.Function
        if func then
            local typeoffunc = typeof(func)
            if typeoffunc ~= 'string' then
                codebox:setRaw("--[[Generating Function Info please wait]]")
                RunService.Heartbeat:Wait()
                local lclosure = islclosure(func)
                local SourceScript = rawget(getfenv(func), "script")
                local CallingScript = selected.Source or nil
                local info = {
                    info = getinfo(func),
                    constants = lclosure and deepclone(getconstants(func)) or "N/A --Lua Closure expected got C Closure",
                    upvalues = deepclone(getupvalues(func)),
                    script = {
                        SourceScript = SourceScript or 'nil',
                        CallingScript = CallingScript or 'nil'
                    }
                }
                if configs.advancedinfo then
                    local Remote = selected.Remote
                    info["advancedinfo"] = {
                        Metamethod = selected.metamethod,
                        DebugId = {
                            SourceScriptDebugId = SourceScript and typeof(SourceScript) == "Instance" and OldDebugId(SourceScript) or "N/A",
                            CallingScriptDebugId = CallingScript and typeof(CallingScript) == "Instance" and OldDebugId(CallingScript) or "N/A",
                            RemoteDebugId = OldDebugId(Remote)
                        },
                        Protos = lclosure and getprotos(func) or "N/A --Lua Closure expected got C Closure"
                    }
                    if Remote:IsA("RemoteFunction") then
                        info["advancedinfo"]["OnClientInvoke"] = getcallbackmember and (getcallbackmember(Remote, "OnClientInvoke") or "N/A") or "N/A --Missing function getcallbackmember"
                    elseif getconnections then
                        info["advancedinfo"]["OnClientEvents"] = {}
                        for i, v in next, getconnections(Remote.OnClientEvent) do
                            info["advancedinfo"]["OnClientEvents"][i] = {
                                Function = v.Function or "N/A",
                                State = v.State or "N/A"
                            }
                        end
                    end
                end
                codebox:setRaw("--[[Converting table to string please wait]]")
                selected.Function = v2v({functionInfo = info})
            end
            codebox:setRaw("-- Calling function info\n-- Generated by the SimpleSpy V3 serializer\n\n" .. selected.Function)
            TextLabel.Text = "Done! Function info generated by the SimpleSpy V3 Serializer."
        else
            TextLabel.Text = "Error! Selected function was not found."
        end
    end
)

newButton(
    "Clr Logs",
    function() return "Click to clear logs" end,
    function()
        TextLabel.Text = "Clearing..."
        clear(logs)
        for _, v in next, LogList:GetChildren() do
            if not v:IsA("UIListLayout") then
                v:Destroy()
            end
        end
        codebox:setRaw("")
        selected = nil
        TextLabel.Text = "Logs cleared!"
    end
)

newButton(
    "Exclude (i)",
    function() return "Click to exclude this Remote.\nExcluding a remote makes SimpleSpy ignore it, but it will continue to be usable." end,
    function()
        if selected then
            blacklist[OldDebugId(selected.Remote)] = true
            TextLabel.Text = "Excluded!"
        end
    end
)

newButton(
    "Exclude (n)",
    function() return "Click to exclude all remotes with this name.\nExcluding a remote makes SimpleSpy ignore it, but it will continue to be usable." end,
    function()
        if selected then
            blacklist[selected.Name] = true
            TextLabel.Text = "Excluded!"
        end
    end
)

newButton(
    "Clr Blacklist",
    function() return "Click to clear the blacklist.\nExcluding a remote makes SimpleSpy ignore it, but it will continue to be usable." end,
    function()
        blacklist = {}
        TextLabel.Text = "Blacklist cleared!"
    end
)

newButton(
    "Block (i)",
    function() return "Click to stop this remote from firing.\nBlocking a remote won't remove it from SimpleSpy logs, but it will not continue to fire the server." end,
    function()
        if selected then
            blocklist[OldDebugId(selected.Remote)] = true
            TextLabel.Text = "Blocked!"
        end
    end
)

newButton(
    "Block (n)",
    function() return "Click to stop remotes with this name from firing.\nBlocking a remote won't remove it from SimpleSpy logs, but it will not continue to fire the server." end,
    function()
        if selected then
            blocklist[selected.Name] = true
            TextLabel.Text = "Blocked!"
        end
    end
)

newButton(
    "Clr Blocklist",
    function() return "Click to stop blocking remotes.\nBlocking a remote won't remove it from SimpleSpy logs, but it will not continue to fire the server." end,
    function()
        blocklist = {}
        TextLabel.Text = "Blocklist cleared!"
    end
)

newButton(
    "Decompile",
    function() return "Decompile source script" end,
    function()
        if decompile then
            if selected and selected.Source then
                local Source = selected.Source
                if not DecompiledScripts[Source] then
                    codebox:setRaw("--[[Decompiling]]")
                    xpcall(function()
                        local decompiledsource = decompile(Source):gsub("-- Decompiled with the Synapse X Luau decompiler.", "")
                        local Sourcev2s = v2s(Source)
                        if decompiledsource:find("script") and Sourcev2s then
                            DecompiledScripts[Source] = ("local script = %s\n%s"):format(Sourcev2s, decompiledsource)
                        end
                    end, function(err)
                        codebox:setRaw(("--[[\nAn error has occured\n%s\n]]"):format(err))
                    end)
                end
                codebox:setRaw(DecompiledScripts[Source] or "--No Source Found")
                TextLabel.Text = "Done!"
            else
                TextLabel.Text = "Source not found!"
            end
        else
            TextLabel.Text = "Missing function (decompile)"
        end
    end
)

newButton(
    "Disable Info",
    function() return string.format("[%s] Toggle function info (because it can cause lag in some games)", configs.funcEnabled and "ENABLED" or "DISABLED") end,
    function()
        configs.funcEnabled = not configs.funcEnabled
        TextLabel.Text = string.format("[%s] Toggle function info (because it can cause lag in some games)", configs.funcEnabled and "ENABLED" or "DISABLED")
    end
)

newButton(
    "Autoblock",
    function() return string.format("[%s] [BETA] Intelligently detects and excludes spammy remote calls from logs", configs.autoblock and "ENABLED" or "DISABLED") end,
    function()
        configs.autoblock = not configs.autoblock
        TextLabel.Text = string.format("[%s] [BETA] Intelligently detects and excludes spammy remote calls from logs", configs.autoblock and "ENABLED" or "DISABLED")
        history = {}
        excluding = {}
    end
)

newButton(
    "Logcheckcaller",
    function() return string.format("[%s] Log remotes fired by the client", configs.logcheckcaller and "ENABLED" or "DISABLED") end,
    function()
        configs.logcheckcaller = not configs.logcheckcaller
        TextLabel.Text = string.format("[%s] Log remotes fired by the client", configs.logcheckcaller and "ENABLED" or "DISABLED")
    end
)

newButton(
    "Advanced Info",
    function() return string.format("[%s] Display more remoteinfo", configs.advancedinfo and "ENABLED" or "DISABLED") end,
    function()
        configs.advancedinfo = not configs.advancedinfo
        TextLabel.Text = string.format("[%s] Display more remoteinfo", configs.advancedinfo and "ENABLED" or "DISABLED")
    end
)

newButton(
    "Join Discord",
    function() return "Joins The Simple Spy Discord" end,
    function()
        setclipboard("https://discord.com/invite/AWS6ez9")
        TextLabel.Text = "Copied invite to your clipboard"
        if request then
            request({
                Url = 'http://127.0.0.1:6463/rpc?v=1',
                Method = 'POST',
                Headers = {['Content-Type'] = 'application/json', Origin = 'https://discord.com'},
                Body = game:GetService("HttpService"):JSONEncode({
                    cmd = 'INVITE_BROWSER',
                    nonce = game:GetService("HttpService"):GenerateGUID(false),
                    args = {code = 'AWS6ez9'}
                })
            })
        end
    end
)

if configs.supersecretdevtoggle then
    newButton(
        "Load SSV2.2",
        function() return "Load's Simple Spy V2.2" end,
        function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/exxtremestuffs/SimpleSpySource/master/SimpleSpy.lua"))()
        end
    )

    newButton(
        "Load SSV3",
        function() return "Load's Simple Spy V3" end,
        function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/78n/SimpleSpy/main/SimpleSpySource.lua"))()
        end
    )

    newButton(
        "SUPER SECRET BUTTON",
        function() return "You dont need a discription you already know what it does" end,
        function()
            local SuperSecretFolder = Instance.new("Folder")
            SuperSecretFolder.Parent = SimpleSpy3
            local random = listfiles("Music") or {}
            if #random > 0 then
                local NotSound = Instance.new("Sound")
                NotSound.Parent = SuperSecretFolder
                NotSound.Looped = false
                NotSound.Volume = math.random(1,5)
                NotSound.SoundId = getsynasset and getsynasset(random[math.random(1,#random)]) or ""
                NotSound:Play()
            end
        end
    )
end

return buttons_addons
