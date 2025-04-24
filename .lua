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
    Border = Color3.fromRGB(45, 45, 45)          -- Border Color
}

local FONTS = {
    Primary = Enum.Font.GothamSemibold,         -- For Titles/Labels
    Secondary = Enum.Font.Gotham               -- For Content/Values
}

local PADDING = 5
local TITLE_BAR_HEIGHT = 25
local BORDER_SIZE = 1

-- Helper function to create a styled frame
local function createStyledFrame(parent, name, size, position)
    local frame = Instance.new("Frame")
    frame.Name = name
    frame.BackgroundColor3 = COLORS.Frame
    frame.BorderSizePixel = 0
    frame.Size = size
    frame.Position = position
    frame.Parent = parent

    -- Add border effect (inner frame)
    local border = Instance.new("Frame")
    border.Name = "Border"
    border.BackgroundColor3 = COLORS.Border
    border.BorderSizePixel = 0
    border.Size = UDim2.new(1, BORDER_SIZE * 2, 1, BORDER_SIZE * 2)
    border.Position = UDim2.new(0, -BORDER_SIZE, 0, -BORDER_SIZE)
    border.ZIndex = frame.ZIndex - 1
    border.Parent = frame

    return frame, border
end

-- Window dragging logic
local function enableDragging(guiObject)
    local dragging = false
    local dragInput = nil
    local dragStart = nil
    local startPos = nil

    guiObject.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            print("Drag InputBegan on TitleBar!") -- DEBUG PRINT
            dragging = true
            dragStart = input.Position
            startPos = guiObject.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    guiObject.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            guiObject.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
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
    local windowSize = options.Size or UDim2.new(0, 500, 0, 350)
    local windowPosition = options.Position or UDim2.new(0.5, -windowSize.X.Offset / 2, 0.5, -windowSize.Y.Offset / 2) -- Center by default
    local SIDEBAR_WIDTH = 60 -- Width for the left sidebar

    -- 1. Create ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = windowName .. "_ScreenGui"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling -- Use Sibling for easier layering

    -- 2. Create Main Window Frame
    local mainFrame, mainBorder = createStyledFrame(screenGui, "MainFrame", windowSize, windowPosition)
    mainFrame.BackgroundColor3 = COLORS.Background
    mainFrame.ClipsDescendants = true -- Important for containing elements

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

    -- 4. Enable Dragging on Title Bar
    enableDragging(titleBar)

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
    sidebarLayout.Padding = UDim.new(0, PADDING) -- Padding between tabs
    sidebarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center -- Center icons/buttons horizontally
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
    screenGui.Parent = game:GetService("CoreGui") -- Add to CoreGui for executors

    -- Define methods for the window object here (like CreateTab)


    return window
end

--[[
    Creates a new Tab button in the sidebar and its corresponding content frame.
    Args:
        options (table): { Name (string), Icon (string, optional), Order (number, optional) }
    Returns:
        Tab object (table) with methods like CreateSection, CreateButton, etc.
--]]
function GamesenseUI:CreateTab(options)
    local window = self -- Reference to the window object the method is called on
    options = options or {}
    local tabName = options.Name or "Tab"
    local tabIcon = options.Icon -- For future use
    local layoutOrder = options.Order or #window._tabs + 1 -- Controls vertical order

    -- Helper function to activate a tab
    local function activateTab(tabDataToActivate)
        -- Deactivate previously active tab
        if window._activeTab then
            window._activeTab.Button.TextColor3 = COLORS.TextDisabled
            window._activeTab.Button.BackgroundColor3 = COLORS.Frame
            window._activeTab.Content.Visible = false
        end
        -- Activate this tab
        tabDataToActivate.Button.TextColor3 = COLORS.Accent
        tabDataToActivate.Button.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
        tabDataToActivate.Content.Visible = true
        window._activeTab = tabDataToActivate
    end

    -- 1. Create Content Frame (initially hidden)
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = tabName .. "_Content"
    contentFrame.BackgroundColor3 = COLORS.Background
    contentFrame.BorderSizePixel = 0
    contentFrame.Size = UDim2.new(1, 0, 1, 0) -- Fill the content container
    contentFrame.Position = UDim2.new(0, 0, 0, 0)
    contentFrame.Visible = false -- Hide by default
    contentFrame.LayoutOrder = layoutOrder -- Match button order
    contentFrame.Parent = window._contentContainer

    -- Add layout for elements within this tab's content
    local contentLayout = Instance.new("UIListLayout")
    contentLayout.FillDirection = Enum.FillDirection.Vertical
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    contentLayout.Padding = UDim.new(0, PADDING * 2) -- More padding for content
    contentLayout.Parent = contentFrame

    -- 2. Create Tab Button (using TextButton for now, ImageButton later if icons needed)
    local tabButton = Instance.new("TextButton")
    tabButton.Name = tabName .. "_Button"
    tabButton.Text = tabName -- Use text for now
    tabButton.Size = UDim2.new(0, window._sidebarFrame.Size.X.Offset - PADDING * 2, 0, 40) -- Example size
    tabButton.BackgroundColor3 = COLORS.Frame
    tabButton.BorderSizePixel = 0
    tabButton.TextColor3 = COLORS.TextDisabled -- Default color (inactive)
    tabButton.Font = FONTS.Primary
    tabButton.TextSize = 14
    tabButton.AutoButtonColor = false -- Manual color changes
    tabButton.LayoutOrder = layoutOrder
    tabButton.ZIndex = window._sidebarFrame.ZIndex + 1
    tabButton.Parent = window._sidebarFrame

    -- 3. Store Tab Info
    local tabData = {
        Name = tabName,
        Button = tabButton,
        Content = contentFrame,
        Layout = contentLayout,
        Elements = {} -- Store elements created within this tab
    }
    window._tabs[tabName] = tabData

    -- 4. Add Click Logic
    tabButton.MouseButton1Click:Connect(function()
        activateTab(tabData) -- Use the helper function
    end)

    -- Activate the first tab created by default
    if #window._tabs == 1 then -- Check if this is the first tab added (count will be 1 after adding)
        activateTab(tabData) -- Activate this first tab directly
    end

    -- Return a 'tab' object for adding elements
    local tabObject = {}
    setmetatable(tabObject, { __index = GamesenseUI }) -- Inherit methods like CreateSection
    tabObject._window = window
    tabObject._tabData = tabData
    -- Add methods like CreateButton to tabObject later (or inherit them via metatable)

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

    -- Create a container Frame for the section title and its elements
    -- Note: We might not need a dedicated frame *for elements* if the tab's main layout handles order.
    -- Let's start with just the title label.

    -- Create the Title Label for the section
    local sectionTitle = Instance.new("TextLabel")
    sectionTitle.Name = sectionName .. "_Title"
    sectionTitle.Text = string.upper(sectionName) -- Uppercase like in Gamesense
    sectionTitle.Size = UDim2.new(1, 0, 0, 20) -- Height for the title
    sectionTitle.BackgroundColor3 = COLORS.Background -- Match tab background
    sectionTitle.BackgroundTransparency = 1 -- Transparent background
    sectionTitle.BorderSizePixel = 0
    sectionTitle.TextColor3 = COLORS.Text -- Standard text color
    sectionTitle.Font = FONTS.Primary -- Use primary font for titles
    sectionTitle.TextSize = 12 -- Slightly smaller for section titles
    sectionTitle.TextXAlignment = Enum.TextXAlignment.Left
    sectionTitle.TextYAlignment = Enum.TextYAlignment.Center
    sectionTitle.LayoutOrder = layoutOrder or (#tab._tabData.Layout.Parent:GetChildren() + 1) -- Position it correctly
    sectionTitle.Parent = tab._tabData.Content -- Add directly to the tab's content frame

    -- Add a top border/line above the text for separation (optional but common)
    local line = Instance.new("Frame")
    line.Name = "SeparatorLine"
    line.BackgroundColor3 = COLORS.Border
    line.BorderSizePixel = 0
    line.Size = UDim2.new(1, 0, 0, BORDER_SIZE)
    line.Position = UDim2.new(0, 0, 0, -PADDING / 2) -- Position slightly above the text using padding
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

local ELEMENT_HEIGHT = 20 -- Standard height for most elements like toggles, buttons

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

    local checkboxSize = ELEMENT_HEIGHT * 0.6
    local checkbox = Instance.new("Frame")
    checkbox.Name = "Checkbox"
    checkbox.Size = UDim2.new(0, checkboxSize, 0, checkboxSize)
    checkbox.Position = UDim2.new(0, 0, 0.5, -checkboxSize / 2) -- Align vertically center
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
    label.Size = UDim2.new(1, -(checkboxSize + PADDING * 2), 1, 0)
    label.Position = UDim2.new(0, checkboxSize + PADDING, 0, 0)
    label.BackgroundColor3 = COLORS.Background
    label.BackgroundTransparency = 1
    label.BorderSizePixel = 0
    label.Font = FONTS.Secondary
    label.TextColor3 = COLORS.Text
    label.Text = name
    label.TextSize = 14
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

    local SLIDER_HEIGHT = 10
    local elementFrame = Instance.new("Frame")
    elementFrame.Name = name .. "_Frame"
    elementFrame.Size = UDim2.new(1, 0, 0, ELEMENT_HEIGHT * 1.5) -- Slightly taller for label + slider
    elementFrame.BackgroundColor3 = COLORS.Background
    elementFrame.BackgroundTransparency = 1
    elementFrame.BorderSizePixel = 0
    elementFrame.LayoutOrder = layoutOrder
    elementFrame.Parent = tab._tabData.Content

    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(0.5, -PADDING, 0, ELEMENT_HEIGHT) -- Half width for label
    label.Position = UDim2.new(0, 0, 0, 0)
    label.BackgroundColor3 = COLORS.Background
    label.BackgroundTransparency = 1
    label.BorderSizePixel = 0
    label.Font = FONTS.Secondary
    label.TextColor3 = COLORS.Text
    label.Text = name
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.Parent = elementFrame

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Name = "ValueLabel"
    valueLabel.Size = UDim2.new(0.5, -PADDING, 0, ELEMENT_HEIGHT) -- Half width for value
    valueLabel.Position = UDim2.new(0.5, PADDING, 0, 0)
    valueLabel.BackgroundColor3 = COLORS.Background
    valueLabel.BackgroundTransparency = 1
    valueLabel.BorderSizePixel = 0
    valueLabel.Font = FONTS.Secondary
    valueLabel.TextColor3 = COLORS.TextDisabled
    valueLabel.TextSize = 14
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.TextYAlignment = Enum.TextYAlignment.Center
    valueLabel.Parent = elementFrame

    local sliderBack = Instance.new("Frame")
    sliderBack.Name = "SliderBack"
    sliderBack.Size = UDim2.new(1, 0, 0, SLIDER_HEIGHT)
    sliderBack.Position = UDim2.new(0, 0, 0, ELEMENT_HEIGHT) -- Below labels
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
    button.Size = UDim2.new(1, 0, 0, ELEMENT_HEIGHT)
    button.BackgroundColor3 = COLORS.Frame
    button.BorderSizePixel = BORDER_SIZE
    button.BorderColor3 = COLORS.Border
    button.Font = FONTS.Primary
    button.TextColor3 = COLORS.Text
    button.Text = name
    button.TextSize = 14
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
    elementFrame.Size = UDim2.new(1, 0, 0, ELEMENT_HEIGHT * 1.5) -- Label + Textbox
    elementFrame.BackgroundColor3 = COLORS.Background
    elementFrame.BackgroundTransparency = 1
    elementFrame.BorderSizePixel = 0
    elementFrame.LayoutOrder = layoutOrder
    elementFrame.Parent = tab._tabData.Content

    local label = Instance.new("TextLabel") -- Label above the textbox
    label.Name = "Label"
    label.Size = UDim2.new(1, 0, 0, ELEMENT_HEIGHT * 0.6)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.Font = FONTS.Secondary
    label.TextColor3 = COLORS.Text
    label.Text = name
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Bottom
    label.Parent = elementFrame

    local textBox = Instance.new("TextBox")
    textBox.Name = "InputBox"
    textBox.Size = UDim2.new(1, 0, 0, ELEMENT_HEIGHT)
    textBox.Position = UDim2.new(0, 0, 0, ELEMENT_HEIGHT * 0.6 + 2) -- Position below label
    textBox.BackgroundColor3 = COLORS.Frame
    textBox.BorderSizePixel = BORDER_SIZE
    textBox.BorderColor3 = COLORS.Border
    textBox.Font = FONTS.Secondary
    textBox.TextColor3 = COLORS.Text
    textBox.Text = currentValue
    textBox.PlaceholderText = placeholder
    textBox.PlaceholderColor3 = COLORS.TextDisabled
    textBox.TextSize = 14
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

-- TODO: Implement CreateColorPicker, CreateDropdown, Notify

-- ============================================================

-- Add the CreateTab method to the main GamesenseUI table so it's available on window objects
GamesenseUI.CreateTab = GamesenseUI.CreateTab

-- Add the CreateSection method to the main GamesenseUI table
GamesenseUI.CreateSection = GamesenseUI.CreateSection


return GamesenseUI
