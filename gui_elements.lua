local gui_elements = {}

local Create = function(class, props, children)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do
        obj[k] = v
    end
    for _, child in ipairs(children or {}) do
        child.Parent = obj
    end
    return obj
end

gui_elements.SimpleSpy3 = Create("ScreenGui", {
    Name = "SimpleSpy",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling
})

gui_elements.Storage = Create("Folder", {})

gui_elements.Background = Create("Frame", {
    Parent = gui_elements.SimpleSpy3,
    BackgroundColor3 = Color3.new(1, 1, 1),
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 500, 0, 200),
    Size = UDim2.new(0, 450, 0, 268)
})

gui_elements.LeftPanel = Create("Frame", {
    Parent = gui_elements.Background,
    BackgroundColor3 = Color3.fromRGB(53, 52, 55),
    BorderSizePixel = 0,
    Position = UDim2.new(0, 0, 0, 19),
    Size = UDim2.new(0, 131, 0, 249)
})

gui_elements.LogList = Create("ScrollingFrame", {
    Parent = gui_elements.LeftPanel,
    Active = true,
    BackgroundColor3 = Color3.new(1, 1, 1),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Position = UDim2.new(0, 0, 0, 9),
    Size = UDim2.new(0, 131, 0, 232),
    CanvasSize = UDim2.new(0, 0, 0, 0),
    ScrollBarThickness = 4
})

Create("UIListLayout", {
    Parent = gui_elements.LogList,
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
    SortOrder = Enum.SortOrder.LayoutOrder
})

gui_elements.RightPanel = Create("Frame", {
    Parent = gui_elements.Background,
    BackgroundColor3 = Color3.fromRGB(37, 36, 38),
    BorderSizePixel = 0,
    Position = UDim2.new(0, 131, 0, 19),
    Size = UDim2.new(0, 319, 0, 249)
})

gui_elements.CodeBox = Create("Frame", {
    Parent = gui_elements.RightPanel,
    BackgroundColor3 = Color3.new(0.0823529, 0.0745098, 0.0784314),
    BorderSizePixel = 0,
    Size = UDim2.new(0, 319, 0, 119)
})

gui_elements.ScrollingFrame = Create("ScrollingFrame", {
    Parent = gui_elements.RightPanel,
    Active = true,
    BackgroundColor3 = Color3.new(1, 1, 1),
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 0, 0.5, 0),
    Size = UDim2.new(1, 0, 0.5, -9),
    CanvasSize = UDim2.new(0, 0, 0, 0),
    ScrollBarThickness = 4
})

Create("UIGridLayout", {
    Parent = gui_elements.ScrollingFrame,
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
    SortOrder = Enum.SortOrder.LayoutOrder,
    CellPadding = UDim2.new(0, 0, 0, 0),
    CellSize = UDim2.new(0, 94, 0, 27)
})

gui_elements.TopBar = Create("Frame", {
    Parent = gui_elements.Background,
    BackgroundColor3 = Color3.fromRGB(37, 35, 38),
    BorderSizePixel = 0,
    Size = UDim2.new(0, 450, 0, 19)
})

gui_elements.Simple = Create("TextButton", {
    Parent = gui_elements.TopBar,
    BackgroundColor3 = Color3.new(1, 1, 1),
    AutoButtonColor = false,
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 5, 0, 0),
    Size = UDim2.new(0, 57, 0, 18),
    Font = Enum.Font.SourceSansBold,
    Text = "SimpleSpy",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 14,
    TextXAlignment = Enum.TextXAlignment.Left
})

gui_elements.CloseButton = Create("TextButton", {
    Parent = gui_elements.TopBar,
    BackgroundColor3 = Color3.new(0.145098, 0.141176, 0.14902),
    BorderSizePixel = 0,
    Position = UDim2.new(1, -19, 0, 0),
    Size = UDim2.new(0, 19, 0, 19),
    Font = Enum.Font.SourceSans,
    Text = "",
    TextColor3 = Color3.new(0, 0, 0),
    TextSize = 14
})

Create("ImageLabel", {
    Parent = gui_elements.CloseButton,
    BackgroundColor3 = Color3.new(1, 1, 1),
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 5, 0, 5),
    Size = UDim2.new(0, 9, 0, 9),
    Image = "http://www.roblox.com/asset/?id=5597086202"
})

gui_elements.MaximizeButton = Create("TextButton", {
    Parent = gui_elements.TopBar,
    BackgroundColor3 = Color3.new(0.145098, 0.141176, 0.14902),
    BorderSizePixel = 0,
    Position = UDim2.new(1, -38, 0, 0),
    Size = UDim2.new(0, 19, 0, 19),
    Font = Enum.Font.SourceSans,
    Text = "",
    TextColor3 = Color3.new(0, 0, 0),
    TextSize = 14
})

Create("ImageLabel", {
    Parent = gui_elements.MaximizeButton,
    BackgroundColor3 = Color3.new(1, 1, 1),
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 5, 0, 5),
    Size = UDim2.new(0, 9, 0, 9),
    Image = "http://www.roblox.com/asset/?id=5597108117"
})

gui_elements.MinimizeButton = Create("TextButton", {
    Parent = gui_elements.TopBar,
    BackgroundColor3 = Color3.new(0.145098, 0.141176, 0.14902),
    BorderSizePixel = 0,
    Position = UDim2.new(1, -57, 0, 0),
    Size = UDim2.new(0, 19, 0, 19),
    Font = Enum.Font.SourceSans,
    Text = "",
    TextColor3 = Color3.new(0, 0, 0),
    TextSize = 14
})

Create("ImageLabel", {
    Parent = gui_elements.MinimizeButton,
    BackgroundColor3 = Color3.new(1, 1, 1),
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 5, 0, 5),
    Size = UDim2.new(0, 9, 0, 9),
    Image = "http://www.roblox.com/asset/?id=5597105827"
})

gui_elements.ToolTip = Create("Frame", {
    Parent = gui_elements.SimpleSpy3,
    BackgroundColor3 = Color3.fromRGB(26, 26, 26),
    BackgroundTransparency = 0.1,
    BorderColor3 = Color3.new(1, 1, 1),
    Size = UDim2.new(0, 200, 0, 50),
    ZIndex = 3,
    Visible = false
})

gui_elements.TextLabel = Create("TextLabel", {
    Parent = gui_elements.ToolTip,
    BackgroundColor3 = Color3.new(1, 1, 1),
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 2, 0, 2),
    Size = UDim2.new(0, 196, 0, 46),
    ZIndex = 3,
    Font = Enum.Font.SourceSans,
    Text = "This is some slightly longer text.",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 14,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top
})

gui_elements.Icon = Create("ImageButton", {
    Name = "SimpleSpyIcon",
    Parent = game:GetService("CoreGui"),
    BackgroundTransparency = 0.3,
    Image = "rbxassetid://7072718362",
    Size = UDim2.fromOffset(60, 60),
    Position = UDim2.new(0.5, -30, 0.2, 0),
    ZIndex = 1000,
    AutoButtonColor = false
})

gui_elements.SimpleSpy3.Parent = (gethui and gethui()) or game:GetService("CoreGui")
gui_elements.Icon.Parent = (gethui and gethui()) or game:GetService("CoreGui")

return gui_elements
