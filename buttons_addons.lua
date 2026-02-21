local buttons_addons = {}

-- Зависимости из getgenv().SS
local SS              = getgenv().SS
local gui_elements    = SS.gui_elements
local gui_logic       = SS.gui_logic
local log_manager     = SS.log_manager
local remote_spy_core = SS.remote_spy_core
local serializer      = SS.serializer
local utils           = SS.utils

local ScrollingFrame  = gui_elements.ScrollingFrame
local LogList         = gui_elements.LogList
local TextLabel       = gui_elements.TextLabel
local SimpleSpy3      = gui_elements.SimpleSpy3

local makeToolTip         = gui_logic.makeToolTip
local updateFunctionCanvas = log_manager.updateFunctionCanvas
local logthread           = log_manager.logthread
local logs                = log_manager.logs
local clear               = log_manager.clear
local selected            = log_manager.selected
local blacklist           = log_manager.blacklist
local blocklist           = log_manager.blocklist
local history             = log_manager.history
local excluding           = log_manager.excluding
local DecompiledScripts   = log_manager.DecompiledScripts
local OldDebugId          = log_manager.OldDebugId
local codebox             = log_manager.codebox

local v2s        = serializer.v2s
local v2v        = serializer.v2v
local configs    = SS.configs or getgenv().SSConfigs

local RunService       = game:GetService("RunService")
local setclipboard     = utils.setclipboard
local islclosure       = utils.islclosure
local getinfo          = utils.getinfo
local deepclone        = utils.deepclone
local getconstants     = utils.getconstants
local getupvalues      = utils.getupvalues
local request          = utils.request

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
        gui_logic.makeToolTip(true, descriptionFunc())
    end)

    Button.MouseLeave:Connect(function()
        gui_logic.makeToolTip(false)
    end)

    FunctionTemplate.AncestryChanged:Connect(function()
        gui_logic.makeToolTip(false)
    end)

    Button.MouseButton1Click:Connect(function(...)
        log_manager.logthread(coroutine.running())
        onClick(FunctionTemplate, ...)
    end)

    log_manager.updateFunctionCanvas()
end

local function createButtons()
    newButton(
        "Copy Code",
        function() return "Click to copy code" end,
        function()
            setclipboard(log_manager.codebox:getString())
            TextLabel.Text = "Copied successfully!"
        end
    )

    newButton(
        "Copy Remote",
        function() return "Click to copy the path of the remote" end,
        function()
            local sel = log_manager.selected
            if sel and sel.Remote then
                setclipboard(serializer.v2s(sel.Remote))
                TextLabel.Text = "Copied!"
            end
        end
    )

    newButton(
        "Run Code",
        function() return "Click to execute code" end,
        function()
            local sel = log_manager.selected
            local Remote = sel and sel.Remote
            if Remote then
                TextLabel.Text = "Executing..."
                xpcall(function()
                    local returnvalue
                    if Remote:IsA("RemoteEvent") then
                        returnvalue = Remote:FireServer(unpack(sel.args))
                    else
                        returnvalue = Remote:InvokeServer(unpack(sel.args))
                    end
                    TextLabel.Text = ("Executed successfully!\n%s"):format(serializer.v2s(returnvalue))
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
            local sel = log_manager.selected
            if sel then
                if not sel.Source then
                    sel.Source = rawget(getfenv(sel.Function), "script")
                end
                setclipboard(serializer.v2s(sel.Source))
                TextLabel.Text = "Done!"
            end
        end
    )

    newButton(
        "Function Info",
        function() return "Click to view calling function information" end,
        function()
            local sel = log_manager.selected
            local func = sel and sel.Function
            if func then
                local typeoffunc = typeof(func)
                if typeoffunc ~= 'string' then
                    log_manager.codebox:setRaw("--[[Generating Function Info please wait]]")
                    RunService.Heartbeat:Wait()
                    local lclosure = utils.islclosure(func)
                    local SourceScript = rawget(getfenv(func), "script")
                    local CallingScript = sel.Source or nil
                    local info = {
                        info = utils.getinfo(func),
                        constants = lclosure and utils.deepclone(utils.getconstants(func)) or "N/A --Lua Closure expected got C Closure",
                        upvalues = utils.deepclone(utils.getupvalues(func)),
                        script = {
                            SourceScript = SourceScript or 'nil',
                            CallingScript = CallingScript or 'nil'
                        }
                    }
                    if configs.advancedinfo then
                        local Remote = sel.Remote
                        local OldDebugId = log_manager.OldDebugId
                        info["advancedinfo"] = {
                            Metamethod = sel.metamethod,
                            DebugId = {
                                SourceScriptDebugId = SourceScript and typeof(SourceScript) == "Instance" and OldDebugId(SourceScript) or "N/A",
                                CallingScriptDebugId = CallingScript and typeof(CallingScript) == "Instance" and OldDebugId(CallingScript) or "N/A",
                                RemoteDebugId = OldDebugId(Remote)
                            },
                            Protos = lclosure and (getprotos and getprotos(func) or "N/A") or "N/A --Lua Closure expected got C Closure"
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
                    log_manager.codebox:setRaw("--[[Converting table to string please wait]]")
                    sel.Function = serializer.v2v({functionInfo = info})
                end
                log_manager.codebox:setRaw("-- Calling function info\n-- Generated by the SimpleSpy V3 serializer\n\n" .. sel.Function)
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
            log_manager.clear(log_manager.logs)
            for _, v in next, LogList:GetChildren() do
                if not v:IsA("UIListLayout") then
                    v:Destroy()
                end
            end
            log_manager.codebox:setRaw("")
            log_manager.selected = nil
            TextLabel.Text = "Logs cleared!"
        end
    )

    newButton(
        "Exclude (i)",
        function() return "Click to exclude this Remote.\nExcluding a remote makes SimpleSpy ignore it, but it will continue to be usable." end,
        function()
            local sel = log_manager.selected
            if sel then
                log_manager.blacklist[log_manager.OldDebugId(sel.Remote)] = true
                TextLabel.Text = "Excluded!"
            end
        end
    )

    newButton(
        "Exclude (n)",
        function() return "Click to exclude all remotes with this name.\nExcluding a remote makes SimpleSpy ignore it, but it will continue to be usable." end,
        function()
            local sel = log_manager.selected
            if sel then
                log_manager.blacklist[sel.Name] = true
                TextLabel.Text = "Excluded!"
            end
        end
    )

    newButton(
        "Clr Blacklist",
        function() return "Click to clear the blacklist.\nExcluding a remote makes SimpleSpy ignore it, but it will continue to be usable." end,
        function()
            log_manager.blacklist = {}
            TextLabel.Text = "Blacklist cleared!"
        end
    )

    newButton(
        "Block (i)",
        function() return "Click to stop this remote from firing.\nBlocking a remote won't remove it from SimpleSpy logs, but it will not continue to fire the server." end,
        function()
            local sel = log_manager.selected
            if sel then
                log_manager.blocklist[log_manager.OldDebugId(sel.Remote)] = true
                TextLabel.Text = "Blocked!"
            end
        end
    )

    newButton(
        "Block (n)",
        function() return "Click to stop remotes with this name from firing.\nBlocking a remote won't remove it from SimpleSpy logs, but it will not continue to fire the server." end,
        function()
            local sel = log_manager.selected
            if sel then
                log_manager.blocklist[sel.Name] = true
                TextLabel.Text = "Blocked!"
            end
        end
    )

    newButton(
        "Clr Blocklist",
        function() return "Click to stop blocking remotes.\nBlocking a remote won't remove it from SimpleSpy logs, but it will not continue to fire the server." end,
        function()
            log_manager.blocklist = {}
            TextLabel.Text = "Blocklist cleared!"
        end
    )

    newButton(
        "Decompile",
        function() return "Decompile source script" end,
        function()
            if decompile then
                local sel = log_manager.selected
                if sel and sel.Source then
                    local Source = sel.Source
                    if not log_manager.DecompiledScripts[Source] then
                        log_manager.codebox:setRaw("--[[Decompiling]]")
                        xpcall(function()
                            local decompiledsource = decompile(Source):gsub("-- Decompiled with the Synapse X Luau decompiler.", "")
                            local Sourcev2s = serializer.v2s(Source)
                            if decompiledsource:find("script") and Sourcev2s then
                                log_manager.DecompiledScripts[Source] = ("local script = %s\n%s"):format(Sourcev2s, decompiledsource)
                            end
                        end, function(err)
                            log_manager.codebox:setRaw(("--[[\nAn error has occured\n%s\n]]"):format(err))
                        end)
                    end
                    log_manager.codebox:setRaw(log_manager.DecompiledScripts[Source] or "--No Source Found")
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
            log_manager.history = {}
            log_manager.excluding = {}
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
                local random = listfiles and listfiles("Music") or {}
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
end

buttons_addons.create = createButtons

return buttons_addons
