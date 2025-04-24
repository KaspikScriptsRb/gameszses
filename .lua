local GamesenseUI = {}
GamesenseUI.__index = GamesenseUI

-- Services
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- Styling Constants (Gamesense Inspired)
local COLORS = {
    Background = Color3.fromRGB(18, 18, 18),       -- Darker Background
    Frame = Color3.fromRGB(30, 30, 30),          -- Element Background
    Accent = Color3.fromRGB(170, 255, 0),        -- Lime Green Accent
    Text = Color3.fromRGB(240, 240, 240),       -- Light Text
    TextDisabled = Color3.fromRGB(100, 100, 100), -- Disabled Text
    Border = Color3.fromRGB(40, 40, 40)          -- Slightly darker Border Color
}

local FONTS = {
    Primary = Enum.Font.GothamSemibold,         -- For Titles/Labels
    Secondary = Enum.Font.Gotham               -- For Content/Values
}

local PADDING = 5
local TITLE_BAR_HEIGHT = 25
local BORDER_SIZE = 1
local ELEMENT_SPACING = 8 -- Vertical spacing between elements in a list

-- Helper function to create a styled frame (Removed border creation here, handled individually)
local function createStyledFrame(parent, name, size, position)
    local frame = Instance.new("Frame")
    frame.Name = name
    frame.BackgroundColor3 = COLORS.Frame -- Use element background as base for main frames too
    frame.BorderSizePixel = 0 -- Set to 0 initially, borders added manually where needed
    frame.Size = size
    frame.Position = position
    frame.Parent = parent
    return frame
end

-- Window dragging logic (MODIFIED TO MOVE mainFrame)
local function enableDragging(guiObject, mainFrame)
    local dragging = false
    local dragInput = nil
    local dragStart = nil
    local startPos = nil

    guiObject.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            -- print("Drag InputBegan on TitleBar!") -- Keep for debugging if needed
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position -- Get the main frame's position
            local conn
            conn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    conn:Disconnect() -- Disconnect the changed event when input ends
                end
            end)
        end
    end)

    guiObject.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    -- Listen globally for mouse movement when dragging
    local moveConn
    moveConn = UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            -- Update the MAIN FRAME's position
            mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        elseif not dragging and moveConn then -- Optimization: disconnect if not dragging (might need adjustment)
            -- Be careful with disconnecting this, might be needed by other things.
            -- Consider disconnecting only when the UI is closed.
            -- For now, let's keep it connected.
            -- moveConn:Disconnect()
        end
    end)

    -- Add cleanup for the connection when the guiObject is destroyed (important!)
    guiObject.Destroying:Connect(function()
        if moveConn then
            moveConn:Disconnect()
        end
    end)
end

-- Internal helper function to activate a tab (now accepts window object)
local function _activateTabLogic(window, tabDataToActivate)
    if not window or not tabDataToActivate then
        warn("_activateTabLogic error: Invalid arguments")
        return
    end

    if window._activeTab then
        -- Deactivate previous
        if window._activeTab.Button and window._activeTab.Button.Parent then
            window._activeTab.Button.BackgroundColor3 = COLORS.Frame
        end
        if window._activeTab.Content and window._activeTab.Content.Parent then
             window._activeTab.Content.Visible = false
        end
    end

    -- Activate new
    if tabDataToActivate.Button and tabDataToActivate.Button.Parent then
        tabDataToActivate.Button.BackgroundColor3 = COLORS.Border
    end
    if tabDataToActivate.Content and tabDataToActivate.Content.Parent then
         tabDataToActivate.Content.Visible = true
    end
    window._activeTab = tabDataToActivate
end

--[[
    Creates the main UI window.
    Args:
        options (table): { Name (string), Size (UDim2, optional), Position (UDim2, optional) }
    Returns:
        Window object (table) with methods like CreateTab.
--]]
function GamesenseUI:CreateWindow(options)
    local window = {}
    setmetatable(window, GamesenseUI) -- Inherit methods if needed later

    options = options or {}
    local windowName = options.Name or "GamesenseUI"
    local screenGuiName = windowName .. "_ScreenGui"

    -- << NEW: Check for and remove existing UI >>
    local coreGui = game:GetService("CoreGui")
    local existingGui = coreGui:FindFirstChild(screenGuiName)
    if existingGui then
        print("GamesenseUI: Removing existing UI instance.")
        existingGui:Destroy()
    end
    -- << END NEW >>

    local windowSize = options.Size or UDim2.new(0, 500, 0, 350)
    local windowPosition = options.Position or UDim2.new(0.5, -windowSize.X.Offset / 2, 0.5, -windowSize.Y.Offset / 2) -- Center by default
    local SIDEBAR_WIDTH = 60 -- Width for the left sidebar

    -- 1. Create ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = screenGuiName -- Use the defined name
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling -- Use Sibling for easier layering

    -- 2. Create Main Window Frame (Using updated helper)
    local mainFrame = createStyledFrame(screenGui, "MainFrame", windowSize, windowPosition)
    mainFrame.BackgroundColor3 = COLORS.Background -- Override background color
    mainFrame.ClipsDescendants = true -- Important for containing elements
    -- Add the main outer border
    local mainBorder = Instance.new("Frame")
    mainBorder.Name = "OuterBorder"
    mainBorder.BackgroundColor3 = COLORS.Border
    mainBorder.BorderSizePixel = 0
    mainBorder.Size = UDim2.new(1, BORDER_SIZE * 2, 1, BORDER_SIZE * 2)
    mainBorder.Position = UDim2.new(0, -BORDER_SIZE, 0, -BORDER_SIZE)
    mainBorder.ZIndex = mainFrame.ZIndex - 1
    mainBorder.Parent = mainFrame

    -- 3. Create Title Bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.BackgroundColor3 = COLORS.Frame
    titleBar.BorderSizePixel = 0
    titleBar.Size = UDim2.new(1, 0, 0, TITLE_BAR_HEIGHT)
    titleBar.Position = UDim2.new(0, 0, 0, 0)
    titleBar.ZIndex = mainFrame.ZIndex + 2
    titleBar.Parent = mainFrame

    -- Title Bar Border (bottom)
    local titleBorder = Instance.new("Frame")
    titleBorder.Name = "BottomBorder"
    titleBorder.BackgroundColor3 = COLORS.Border
    titleBorder.Size = UDim2.new(1, 0, 0, BORDER_SIZE)
    titleBorder.Position = UDim2.new(0, 0, 1, -BORDER_SIZE)
    titleBorder.BorderSizePixel = 0
    titleBorder.ZIndex = titleBar.ZIndex + 1
    titleBorder.Parent = titleBar

    -- Title Label
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, -(PADDING * 2), 1, 0)
    titleLabel.Position = UDim2.new(0, PADDING, 0, 0)
    titleLabel.BackgroundColor3 = COLORS.Frame
    titleLabel.BackgroundTransparency = 1
    titleLabel.BorderSizePixel = 0
    titleLabel.Font = FONTS.Primary
    titleLabel.TextColor3 = COLORS.Text
    titleLabel.TextScaled = false
    titleLabel.TextSize = 14
    titleLabel.Text = windowName
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.TextYAlignment = Enum.TextYAlignment.Center
    titleLabel.ZIndex = titleBar.ZIndex + 1
    titleLabel.Parent = titleBar

    -- 4. Enable Dragging (Pass mainFrame now)
    enableDragging(titleBar, mainFrame)

    -- 5. Create Left Sidebar for Tabs
    local sidebarFrame = Instance.new("Frame")
    sidebarFrame.Name = "SidebarFrame"
    sidebarFrame.BackgroundColor3 = COLORS.Frame -- Same as TitleBar/Elements
    sidebarFrame.BorderSizePixel = 0
    sidebarFrame.Size = UDim2.new(0, SIDEBAR_WIDTH, 1, -(TITLE_BAR_HEIGHT + BORDER_SIZE)) -- Fill height below title bar
    sidebarFrame.Position = UDim2.new(0, 0, 0, TITLE_BAR_HEIGHT + BORDER_SIZE)
    sidebarFrame.ZIndex = mainFrame.ZIndex + 1
    sidebarFrame.Parent = mainFrame

    -- Sidebar Border (Right)
    local sidebarBorder = Instance.new("Frame")
    sidebarBorder.Name = "RightBorder"
    sidebarBorder.BackgroundColor3 = COLORS.Border
    sidebarBorder.Size = UDim2.new(0, BORDER_SIZE, 1, 0)
    sidebarBorder.Position = UDim2.new(1, -BORDER_SIZE, 0, 0)
    sidebarBorder.BorderSizePixel = 0
    sidebarBorder.ZIndex = sidebarFrame.ZIndex + 1
    sidebarBorder.Parent = sidebarFrame

    -- Layout for Tab Buttons within Sidebar
    local sidebarLayout = Instance.new("UIListLayout")
    sidebarLayout.FillDirection = Enum.FillDirection.Vertical
    sidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
    sidebarLayout.Padding = UDim.new(0, ELEMENT_SPACING) -- Use consistent spacing
    sidebarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left -- Align elements left
    sidebarLayout.Parent = sidebarFrame

    -- 6. Create Content Container (Adjusted for Sidebar)
    local contentContainer = Instance.new("Frame")
    contentContainer.Name = "ContentContainer"
    contentContainer.BackgroundColor3 = COLORS.Background -- Match main background
    contentContainer.BorderSizePixel = 0
    -- Position right of the sidebar, fill remaining space
    contentContainer.Size = UDim2.new(1, -(SIDEBAR_WIDTH + BORDER_SIZE + PADDING * 2), 1, -(TITLE_BAR_HEIGHT + BORDER_SIZE + PADDING * 2))
    contentContainer.Position = UDim2.new(0, SIDEBAR_WIDTH + BORDER_SIZE + PADDING, 0, TITLE_BAR_HEIGHT + BORDER_SIZE + PADDING)
    contentContainer.ClipsDescendants = true
    contentContainer.ZIndex = mainFrame.ZIndex + 1
    contentContainer.Parent = mainFrame

    -- Store references for later use
    window._screenGui = screenGui
    window._mainFrame = mainFrame
    window._sidebarFrame = sidebarFrame        -- Changed from _tabContainer
    window._contentContainer = contentContainer
    window._tabs = {} -- Store tab buttons and content frames
    window._activeTab = nil

    -- Add parent setting last
    screenGui.Parent = coreGui

    -- Define methods for the window object here (like CreateTab)


    return window
end

--[[
    Creates a new Tab button/icon in the sidebar and its corresponding content frame.
    Args:
        options (table): { Name (string), Icon (string, optional), Order (number, optional) }
    Returns:
        Tab object (table) with methods like CreateSection, CreateButton, etc.
--]]
function GamesenseUI:CreateTab(options)
    local window = self
    options = options or {}
    -- Tab Name is now mostly for internal reference, Icon is primary visual
    local tabName = options.Name or "Tab" .. (#window._tabs + 1)
    local iconId = options.Icon or "4483362458" -- Default Icon ID
    local layoutOrder = options.Order or #window._tabs + 1

    -- 1. Create Content Frame
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = tabName .. "_Content"
    contentFrame.BackgroundColor3 = COLORS.Background
    contentFrame.BorderSizePixel = 0
    contentFrame.Size = UDim2.new(1, 0, 1, 0) -- Fill the content container
    contentFrame.Position = UDim2.new(0, 0, 0, 0)
    contentFrame.Visible = false -- Hide by default
    contentFrame.LayoutOrder = layoutOrder -- Match button order
    contentFrame.Parent = window._contentContainer

    -- Add layout for elements within tab
    local contentLayout = Instance.new("UIListLayout")
    contentLayout.FillDirection = Enum.FillDirection.Vertical
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    contentLayout.Padding = UDim.new(0, ELEMENT_SPACING) -- Use consistent spacing
    contentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left -- Align elements left
    contentLayout.Parent = contentFrame

    -- 2. Create Tab Button (CHANGED TO ImageButton)
    local tabButton = Instance.new("ImageButton")
    tabButton.Name = tabName .. "_Button"
    tabButton.Size = UDim2.new(1, -PADDING * 2, 0, window._sidebarFrame.Size.X.Offset - PADDING * 2) -- Make it square-ish
    tabButton.BackgroundColor3 = COLORS.Frame -- Inactive background
    tabButton.BorderSizePixel = 0
    tabButton.Image = "rbxassetid://" .. tostring(iconId)
    tabButton.ScaleType = Enum.ScaleType.Fit -- Fit the icon within the button
    tabButton.AutoButtonColor = false
    tabButton.LayoutOrder = layoutOrder
    tabButton.ZIndex = window._sidebarFrame.ZIndex + 1
    tabButton.Parent = window._sidebarFrame

    -- 3. Store Tab Info
    local tabData = {
        Name = tabName,
        Button = tabButton,
        Content = contentFrame,
        Layout = contentLayout,
        Elements = {}
    }
    window._tabs[tabName] = tabData

    -- 4. Add Click Logic
    tabButton.MouseButton1Click:Connect(function()
        _activateTabLogic(window, tabData) -- Call the external helper
    end)

    -- Return a 'tab' object
    local tabObject = {}
    setmetatable(tabObject, { __index = GamesenseUI })
    tabObject._window = window
    tabObject._tabData = tabData

    return tabObject
end

--[[
    Creates a visual section divider with a title within a tab.
    Args:
        options (table): { Name (string), Order (number, optional) }
    Returns:
        nil (or a Section object if more control is needed later)
--]]
function GamesenseUI:CreateSection(options)
    local tab = self -- Reference to the tab object the method is called on
    options = options or {}
    local sectionName = options.Name or "Section"
    local layoutOrder = options.Order -- Use LayoutOrder from the tab's contentLayout

    -- Create the Title Label for the section
    local sectionTitle = Instance.new("TextLabel")
    sectionTitle.Name = sectionName .. "_Title"
    sectionTitle.Text = " " .. string.upper(sectionName) -- Add space before title
    sectionTitle.Size = UDim2.new(1, 0, 0, 18) -- Slightly smaller height
    sectionTitle.BackgroundColor3 = COLORS.Background -- Match tab background
    sectionTitle.BackgroundTransparency = 1 -- Transparent background
    sectionTitle.BorderSizePixel = 0
    sectionTitle.TextColor3 = COLORS.Text -- Standard text color
    sectionTitle.Font = FONTS.Primary -- Use primary font for titles
    sectionTitle.TextSize = 11 -- Smaller font size
    sectionTitle.TextXAlignment = Enum.TextXAlignment.Left
    sectionTitle.TextYAlignment = Enum.TextYAlignment.Center
    sectionTitle.LayoutOrder = layoutOrder or (#tab._tabData.Layout.Parent:GetChildren() + 1) -- Position it correctly
    sectionTitle.Parent = tab._tabData.Content -- Add directly to the tab's content frame

    -- Separator Line (below title now)
    local line = Instance.new("Frame")
    line.Name = "SeparatorLine"
    line.BackgroundColor3 = COLORS.Border
    line.BorderSizePixel = 0
    line.Size = UDim2.new(1, 0, 0, BORDER_SIZE)
    line.Position = UDim2.new(0, 0, 1, PADDING / 2) -- Position below text
    line.ZIndex = sectionTitle.ZIndex - 1
    line.Parent = sectionTitle -- Parent to title to move with it

    -- We don't return a specific section object for now,
    -- elements will be added directly to the tab after calling CreateSection.
    -- The UIListLayout in the tab's contentFrame will handle the vertical arrangement.

    -- Make sure the layout accounts for the new title
    -- No explicit action needed if using UIListLayout correctly.
end

-- ============================================================
-- ================== Element Creation Methods ==================
-- ============================================================

local ELEMENT_HEIGHT = 18 -- Reduced height for denser look

--[[
    Creates a Toggle (Checkbox) element.
    Args:
        options (table): { Name (string), CurrentValue (boolean, optional), Order (number, optional), Callback (function, optional) }
    Returns:
        Toggle object (table) with methods like Set, GetValue.
--]]
function GamesenseUI:CreateToggle(options)
    local tab = self
    options = options or {}
    local name = options.Name or "Toggle"
    local currentValue = options.CurrentValue or false
    local layoutOrder = options.Order or (#tab._tabData.Layout.Parent:GetChildren() + 1)
    local callback = options.Callback or function() end

    local elementFrame = Instance.new("Frame")
    elementFrame.Name = name .. "_Frame"
    elementFrame.Size = UDim2.new(1, 0, 0, ELEMENT_HEIGHT)
    elementFrame.BackgroundColor3 = COLORS.Background
    elementFrame.BackgroundTransparency = 1
    elementFrame.BorderSizePixel = 0
    elementFrame.LayoutOrder = layoutOrder
    elementFrame.Parent = tab._tabData.Content

    local checkboxSize = ELEMENT_HEIGHT * 0.7
    local checkbox = Instance.new("Frame")
    checkbox.Name = "Checkbox"
    checkbox.Size = UDim2.new(0, checkboxSize, 0, checkboxSize)
    checkbox.Position = UDim2.new(0, PADDING, 0.5, -checkboxSize / 2) -- Add padding
    checkbox.BackgroundColor3 = COLORS.Frame
    checkbox.BorderSizePixel = BORDER_SIZE
    checkbox.BorderColor3 = COLORS.Border
    checkbox.Parent = elementFrame

    local checkmark = Instance.new("Frame")
    checkmark.Name = "Checkmark"
    checkmark.Size = UDim2.new(1, -4, 1, -4) -- Smaller inner frame
    checkmark.Position = UDim2.new(0, 2, 0, 2)
    checkmark.BackgroundColor3 = COLORS.Accent
    checkmark.BorderSizePixel = 0
    checkmark.Visible = currentValue -- Show if initially true
    checkmark.Parent = checkbox

    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, -(checkboxSize + PADDING * 3), 1, 0)
    label.Position = UDim2.new(0, checkboxSize + PADDING * 2, 0, 0) -- More padding
    label.BackgroundColor3 = COLORS.Background
    label.BackgroundTransparency = 1
    label.BorderSizePixel = 0
    label.Font = FONTS.Secondary
    label.TextColor3 = COLORS.Text
    label.Text = name
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.Parent = elementFrame

    local clickButton = Instance.new("TextButton") -- Invisible button overlay
    clickButton.Name = "ClickArea"
    clickButton.Size = UDim2.new(1, 0, 1, 0)
    clickButton.Position = UDim2.new(0, 0, 0, 0)
    clickButton.Text = ""
    clickButton.BackgroundTransparency = 1
    clickButton.ZIndex = elementFrame.ZIndex + 1
    clickButton.Parent = elementFrame

    local toggleObject = {}
    toggleObject.Value = currentValue

    function toggleObject:SetValue(newValue)
        self.Value = newValue
        checkmark.Visible = newValue
        pcall(callback, self.Value) -- Call callback safely
    end

    function toggleObject:GetValue()
        return self.Value
    end

    clickButton.MouseButton1Click:Connect(function()
        toggleObject:SetValue(not toggleObject.Value)
    end)

    -- Store reference if needed for config saving later
    tab._tabData.Elements[name] = toggleObject

    return toggleObject
end
GamesenseUI.CreateToggle = GamesenseUI.CreateToggle

--[[
    Creates a Slider element.
    Args:
        options (table): { Name (string), Range (table {min, max}), Increment (number, optional),
                           CurrentValue (number, optional), Suffix (string, optional),
                           Order (number, optional), Callback (function, optional) }
    Returns:
        Slider object (table) with methods like Set, GetValue.
--]]
function GamesenseUI:CreateSlider(options)
    local tab = self
    options = options or {}
    local name = options.Name or "Slider"
    local minVal, maxVal = options.Range and options.Range[1] or 0, options.Range and options.Range[2] or 100
    local increment = options.Increment or 1
    local suffix = options.Suffix or ""
    local currentValue = options.CurrentValue or minVal
    local layoutOrder = options.Order or (#tab._tabData.Layout.Parent:GetChildren() + 1)
    local callback = options.Callback or function() end

    local SLIDER_HEIGHT = 6 -- Thinner slider bar
    local elementFrame = Instance.new("Frame")
    elementFrame.Name = name .. "_Frame"
    elementFrame.Size = UDim2.new(1, 0, 0, ELEMENT_HEIGHT * 1.8) -- Adjust height for spacing
    elementFrame.BackgroundColor3 = COLORS.Background
    elementFrame.BackgroundTransparency = 1
    elementFrame.BorderSizePixel = 0
    elementFrame.LayoutOrder = layoutOrder
    elementFrame.Parent = tab._tabData.Content

    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(0.6, 0, 0, ELEMENT_HEIGHT)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.BackgroundColor3 = COLORS.Background
    label.BackgroundTransparency = 1
    label.BorderSizePixel = 0
    label.Font = FONTS.Secondary
    label.TextColor3 = COLORS.Text
    label.Text = name
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.Parent = elementFrame

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Name = "ValueLabel"
    valueLabel.Size = UDim2.new(0.4, -PADDING, 0, ELEMENT_HEIGHT)
    valueLabel.Position = UDim2.new(0.6, PADDING, 0, 0)
    valueLabel.BackgroundColor3 = COLORS.Background
    valueLabel.BackgroundTransparency = 1
    valueLabel.BorderSizePixel = 0
    valueLabel.Font = FONTS.Secondary
    valueLabel.TextColor3 = COLORS.TextDisabled
    valueLabel.TextSize = 12
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.TextYAlignment = Enum.TextYAlignment.Center
    valueLabel.Parent = elementFrame

    local sliderBack = Instance.new("Frame")
    sliderBack.Name = "SliderBack"
    sliderBack.Size = UDim2.new(1, -PADDING, 0, SLIDER_HEIGHT) -- Add padding
    sliderBack.Position = UDim2.new(0, PADDING / 2, 0, ELEMENT_HEIGHT + 2) -- Position below labels
    sliderBack.BackgroundColor3 = COLORS.Frame
    sliderBack.BorderSizePixel = BORDER_SIZE
    sliderBack.BorderColor3 = COLORS.Border
    sliderBack.Parent = elementFrame

    local sliderProgress = Instance.new("Frame")
    sliderProgress.Name = "SliderProgress"
    sliderProgress.Size = UDim2.new(0, 0, 1, 0) -- Initial width 0
    sliderProgress.Position = UDim2.new(0, 0, 0, 0)
    sliderProgress.BackgroundColor3 = COLORS.Accent
    sliderProgress.BorderSizePixel = 0
    sliderProgress.ZIndex = sliderBack.ZIndex + 1
    sliderProgress.Parent = sliderBack

    local sliderButton = Instance.new("TextButton") -- Invisible interaction area
    sliderButton.Name = "SliderButton"
    sliderButton.Size = UDim2.new(1, 0, 1, 0)
    sliderButton.Position = UDim2.new(0, 0, 0, 0)
    sliderButton.Text = ""
    sliderButton.BackgroundTransparency = 1
    sliderButton.ZIndex = sliderBack.ZIndex + 2
    sliderButton.Parent = sliderBack

    local sliderObject = {}
    sliderObject.Value = currentValue

    local function roundToIncrement(value, inc)
        return math.floor(value / inc + 0.5) * inc
    end

    local function updateSlider(value, triggerCallback)
        local clampedValue = math.clamp(value, minVal, maxVal)
        local roundedValue = roundToIncrement(clampedValue, increment)
        sliderObject.Value = roundedValue

        local percentage = (roundedValue - minVal) / (maxVal - minVal)
        if maxVal == minVal then percentage = 0 end -- Avoid division by zero

        sliderProgress.Size = UDim2.new(percentage, 0, 1, 0)
        valueLabel.Text = tostring(roundedValue) .. suffix

        if triggerCallback then
            pcall(callback, sliderObject.Value)
        end
    end

    function sliderObject:SetValue(newValue)
        updateSlider(newValue, true) -- Trigger callback on programmatic set
    end

    function sliderObject:GetValue()
        return self.Value
    end

    -- Dragging Logic
    local dragging = false
    sliderButton.MouseButton1Down:Connect(function()
        dragging = true
        local mouseLoc = UserInputService:GetMouseLocation()
        local sliderAbsolutePos = sliderBack.AbsolutePosition
        local sliderAbsoluteSize = sliderBack.AbsoluteSize
        local relativeX = mouseLoc.X - sliderAbsolutePos.X
        local percentage = math.clamp(relativeX / sliderAbsoluteSize.X, 0, 1)
        local newValue = minVal + percentage * (maxVal - minVal)
        updateSlider(newValue, true)
    end)
    sliderButton.MouseButton1Up:Connect(function() dragging = false end)
    sliderButton.MouseLeave:Connect(function() if dragging then dragging = false end end) -- Stop dragging if mouse leaves

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local mouseLoc = input.Position -- Use input.Position for continuous updates
            local sliderAbsolutePos = sliderBack.AbsolutePosition
            local sliderAbsoluteSize = sliderBack.AbsoluteSize
            local relativeX = mouseLoc.X - sliderAbsolutePos.X
            local percentage = math.clamp(relativeX / sliderAbsoluteSize.X, 0, 1)
            local newValue = minVal + percentage * (maxVal - minVal)
            updateSlider(newValue, true)
        end
    end)

    -- Initial Update
    updateSlider(currentValue, false) -- Don't trigger callback on initial setup

    tab._tabData.Elements[name] = sliderObject
    return sliderObject
end
GamesenseUI.CreateSlider = GamesenseUI.CreateSlider

--[[
    Creates a Button element.
    Args:
        options (table): { Name (string), Order (number, optional), Callback (function, optional) }
    Returns:
        nil (or Button object if needed later)
--]]
function GamesenseUI:CreateButton(options)
    local tab = self
    options = options or {}
    local name = options.Name or "Button"
    local layoutOrder = options.Order or (#tab._tabData.Layout.Parent:GetChildren() + 1)
    local callback = options.Callback or function() end

    local button = Instance.new("TextButton")
    button.Name = name .. "_Button"
    button.Size = UDim2.new(1, -PADDING * 2, 0, ELEMENT_HEIGHT + 4) -- Slightly taller button
    button.Position = UDim2.new(0, PADDING, 0, 0)
    button.BackgroundColor3 = COLORS.Frame
    button.BorderSizePixel = BORDER_SIZE
    button.BorderColor3 = COLORS.Border
    button.Font = FONTS.Primary
    button.TextColor3 = COLORS.Text
    button.Text = name
    button.TextSize = 12
    button.AutoButtonColor = true -- Use default hover/pressed effect for now
    button.LayoutOrder = layoutOrder
    button.Parent = tab._tabData.Content

    button.MouseButton1Click:Connect(function()
        pcall(callback) -- Execute callback safely
    end)

    tab._tabData.Elements[name] = button -- Store the button itself for now
    return button -- Return the instance directly
end
GamesenseUI.CreateButton = GamesenseUI.CreateButton


--[[
    Creates a Textbox element.
    Args:
        options (table): { Name (string), PlaceholderText (string, optional), CurrentValue (string, optional),
                           RemoveTextAfterFocusLost (boolean, optional), Order (number, optional),
                           Callback (function, optional) }
    Returns:
        Textbox object (table) with methods like Set, GetValue, GetText.
--]]
function GamesenseUI:CreateTextbox(options)
    local tab = self
    options = options or {}
    local name = options.Name or "Textbox" -- Used for label, not the box itself
    local placeholder = options.PlaceholderText or ""
    local currentValue = options.CurrentValue or ""
    local clearOnFocusLost = options.RemoveTextAfterFocusLost or false
    local layoutOrder = options.Order or (#tab._tabData.Layout.Parent:GetChildren() + 1)
    local callback = options.Callback or function() end

    local elementFrame = Instance.new("Frame")
    elementFrame.Name = name .. "_Frame"
    elementFrame.Size = UDim2.new(1, 0, 0, ELEMENT_HEIGHT * 2) -- Taller for label+box+spacing
    elementFrame.BackgroundColor3 = COLORS.Background
    elementFrame.BackgroundTransparency = 1
    elementFrame.BorderSizePixel = 0
    elementFrame.LayoutOrder = layoutOrder
    elementFrame.Parent = tab._tabData.Content

    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, -PADDING, 0, ELEMENT_HEIGHT * 0.6)
    label.Position = UDim2.new(0, PADDING / 2, 0, 0)
    label.BackgroundTransparency = 1
    label.Font = FONTS.Secondary
    label.TextColor3 = COLORS.Text
    label.Text = name
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Bottom
    label.Parent = elementFrame

    local textBox = Instance.new("TextBox")
    textBox.Name = "InputBox"
    textBox.Size = UDim2.new(1, -PADDING, 0, ELEMENT_HEIGHT + 2)
    textBox.Position = UDim2.new(0, PADDING / 2, 0, ELEMENT_HEIGHT * 0.6 + 2)
    textBox.BackgroundColor3 = COLORS.Frame
    textBox.BorderSizePixel = BORDER_SIZE
    textBox.BorderColor3 = COLORS.Border
    textBox.Font = FONTS.Secondary
    textBox.TextColor3 = COLORS.Text
    textBox.Text = currentValue
    textBox.PlaceholderText = placeholder
    textBox.PlaceholderColor3 = COLORS.TextDisabled
    textBox.TextSize = 12
    textBox.ClearTextOnFocus = false -- Don't clear when clicking in
    textBox.Parent = elementFrame

    local textboxObject = {}
    textboxObject.Value = currentValue

    function textboxObject:SetValue(newText)
        self.Value = newText
        textBox.Text = newText
        pcall(callback, self.Value)
    end

    function textboxObject:GetValue()
        return self.Value
    end

    function textboxObject:GetText() -- Alias for GetValue
        return self.Value
    end

    textBox.FocusLost:Connect(function(enterPressed)
        local newText = textBox.Text
        textboxObject.Value = newText -- Update internal value
        if enterPressed then
            pcall(callback, newText)
            if clearOnFocusLost then
                textBox.Text = ""
                textboxObject.Value = ""
            end
        else -- Focus lost without Enter
            pcall(callback, newText) -- Still call callback
            if clearOnFocusLost then
                 textBox.Text = ""
                 textboxObject.Value = ""
            end
        end
    end)
    -- Update value continuously while typing (optional)
    -- textBox:GetPropertyChangedSignal("Text"):Connect(function()
    --    textboxObject.Value = textBox.Text
    -- end)

    tab._tabData.Elements[name] = textboxObject
    return textboxObject
end
GamesenseUI.CreateTextbox = GamesenseUI.CreateTextbox

--[[ Creates a Keybind element. ]]
function GamesenseUI:CreateKeybind(options)
    local tab = self
    options = options or {}
    local name = options.Name or "Keybind"
    local currentKeybind = options.CurrentKeybind or "None" -- Initial display text
    local layoutOrder = options.Order or (#tab._tabData.Content:GetChildren() + 1)
    local callback = options.Callback or function() end

    local currentKeyCode = nil -- Store the actual KeyCode enum
    pcall(function()
        if type(currentKeybind) == "string" then
           currentKeyCode = Enum.KeyCode[currentKeybind]
        elseif typeof(currentKeybind) == "EnumItem" and currentKeybind.EnumType == Enum.KeyCode then
            currentKeyCode = currentKeybind
        end
    end)

    local elementFrame = Instance.new("Frame")
    elementFrame.Name = name .. "_Frame"
    elementFrame.Size = UDim2.new(1, 0, 0, ELEMENT_HEIGHT)
    elementFrame.BackgroundColor3 = COLORS.Background
    elementFrame.BackgroundTransparency = 1
    elementFrame.BorderSizePixel = 0
    elementFrame.LayoutOrder = layoutOrder
    elementFrame.Parent = tab._tabData.Content

    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(0.6, -PADDING, 1, 0) -- Adjust width as needed
    label.Position = UDim2.new(0, PADDING / 2, 0, 0)
    label.BackgroundTransparency = 1
    label.Font = FONTS.Secondary
    label.TextColor3 = COLORS.Text
    label.Text = name
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.Parent = elementFrame

    local keybindButton = Instance.new("TextButton")
    keybindButton.Name = "KeybindButton"
    keybindButton.Size = UDim2.new(0.4, -PADDING, 1, 0) -- Adjust width
    keybindButton.Position = UDim2.new(0.6, PADDING / 2, 0, 0)
    keybindButton.BackgroundColor3 = COLORS.Frame
    keybindButton.BorderSizePixel = BORDER_SIZE
    keybindButton.BorderColor3 = COLORS.Border
    keybindButton.Font = FONTS.Secondary
    keybindButton.TextColor3 = COLORS.TextDisabled
    keybindButton.Text = "[" .. (currentKeyCode and currentKeyCode.Name or currentKeybind) .. "]"
    keybindButton.TextSize = 11
    keybindButton.Parent = elementFrame

    local keybindObject = {}
    keybindObject.KeyCode = currentKeyCode
    local isBinding = false
    local inputConn = nil

    local function updateButtonText()
        keybindButton.Text = "[" .. (keybindObject.KeyCode and keybindObject.KeyCode.Name or "None") .. "]"
        keybindButton.TextColor3 = COLORS.TextDisabled
    end

    local function stopBinding()
        if inputConn then inputConn:Disconnect() inputConn = nil end
        isBinding = false
        updateButtonText()
    end

    function keybindObject:SetKeybind(keyCodeEnum)
        if typeof(keyCodeEnum) == "EnumItem" and keyCodeEnum.EnumType == Enum.KeyCode then
            self.KeyCode = keyCodeEnum
            updateButtonText()
            pcall(callback, self.KeyCode)
        elseif keyCodeEnum == nil or tostring(keyCodeEnum):lower() == "none" then
             self.KeyCode = nil
             updateButtonText()
             pcall(callback, self.KeyCode)
        end
    end

    function keybindObject:GetKeybind()
        return self.KeyCode
    end

    keybindButton.MouseButton1Click:Connect(function()
        if isBinding then
            stopBinding()
        else
            isBinding = true
            keybindButton.Text = "[...]"
            keybindButton.TextColor3 = COLORS.Text

            -- Disconnect previous connection if somehow exists
            if inputConn then inputConn:Disconnect() end

            inputConn = UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
                if gameProcessedEvent then return end -- Ignore if game handled it (e.g., typing in chat)

                if input.UserInputType == Enum.UserInputType.Keyboard then
                    if input.KeyCode == Enum.KeyCode.Escape then -- Cancel on Escape
                        stopBinding()
                    else
                        keybindObject:SetKeybind(input.KeyCode)
                        stopBinding()
                    end
                elseif input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.MouseButton3 then
                    -- Convert MouseButton UserInputType to approximate KeyCode for display consistency if desired
                    -- Or just store the UserInputType itself
                    keybindObject.KeyCode = input.KeyCode -- KeyCode exists for mouse buttons too
                    updateButtonText() -- Update text immediately
                     pcall(callback, keybindObject.KeyCode)
                    stopBinding()
                end
            end)
        end
    end)

    tab._tabData.Elements[name] = keybindObject
    return keybindObject
end
GamesenseUI.CreateKeybind = GamesenseUI.CreateKeybind

-- TODO: Implement CreateColorPicker, CreateDropdown, Notify

-- ============================================================

-- Add the CreateTab method to the main GamesenseUI table so it's available on window objects
GamesenseUI.CreateTab = GamesenseUI.CreateTab

-- Add the CreateSection method to the main GamesenseUI table
GamesenseUI.CreateSection = GamesenseUI.CreateSection

--[[ NEW METHOD
    Activates a specific tab by its name.
    Args:
        tabName (string): The exact name of the tab to activate.
--]]
function GamesenseUI:SetActiveTab(tabName)
    local window = self
    local tabDataToActivate = window._tabs[tabName]

    if not tabDataToActivate then
        warn("SetActiveTab: Tab with name '" .. tostring(tabName) .. "' not found.")
        return
    end

    -- Call the external helper function
    _activateTabLogic(window, tabDataToActivate)
end

-- Assign methods to the main table
GamesenseUI.CreateTab = GamesenseUI.CreateTab
GamesenseUI.CreateSection = GamesenseUI.CreateSection
GamesenseUI.CreateToggle = GamesenseUI.CreateToggle
GamesenseUI.CreateSlider = GamesenseUI.CreateSlider
GamesenseUI.CreateButton = GamesenseUI.CreateButton
GamesenseUI.CreateTextbox = GamesenseUI.CreateTextbox
GamesenseUI.SetActiveTab = GamesenseUI.SetActiveTab -- Assign the new method
GamesenseUI.CreateKeybind = GamesenseUI.CreateKeybind -- Assign the new method

return GamesenseUI
