local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Weave = require(ReplicatedStorage.Libraries.Weave)
local Builder = require(script.Parent.Parent.Builder)
local Theme = require(script.Parent.Parent.Theme)

local Tabs = setmetatable({}, {
    __index = Builder,
    __call = function(t, scope, props)
        local inst = t.new(scope)
        if not props then return inst:Build() end

        if props.Tabs then inst:SetTabs(props.Tabs) end
        if props.DefaultTab then inst:SetDefaultTab(props.DefaultTab) end
        if props.OnTabChanged then inst:OnTabChanged(props.OnTabChanged) end
        if props.TabPosition then inst:SetTabPosition(props.TabPosition) end
        if props.FillDirection then inst:SetFillDirection(props.FillDirection) end

        if props.Name then inst:SetName(props.Name) end
        if props.Size then inst:SetSize(props.Size) end
        if props.Position then inst:SetPosition(props.Position) end
        if props.AnchorPoint then inst:SetAnchor(props.AnchorPoint) end
        if props.ZIndex then inst:SetZIndex(props.ZIndex) end

        return inst:Build()
    end
})

function Tabs.new(scope: Weave.Scope)
    local self = setmetatable(Builder.new(scope), Tabs)
    self._props.Tabs = {} -- { { id = "tab1", label = "Tab 1", icon = "..." } }
    self._props.DefaultTab = 1
    self._props.OnTabChanged = nil
    self._props.TabPosition = "top" -- top, bottom
    self._props.FillDirection = Enum.FillDirection.Horizontal
    return self
end

function Tabs:SetTabs(tabs: { { id: string, label: any, icon: any? } })
    self._props.Tabs = tabs
    return self
end

function Tabs:SetDefaultTab(index: number)
    self._props.DefaultTab = index
    return self
end

function Tabs:OnTabChanged(callback: (tabId: string, index: number) -> ())
    self._props.OnTabChanged = callback
    return self
end

function Tabs:SetTabPosition(position: string)
    self._props.TabPosition = position
    return self
end

function Tabs:SetFillDirection(direction: Enum.FillDirection)
    self._props.FillDirection = direction
    return self
end

function Tabs:Build()
    local scope = self._scope
    local activeTheme = Theme.getTheme()

    local tabs = self._props.Tabs
    local defaultTab = self._props.DefaultTab
    local tabPosition = self._props.TabPosition
    local fillDirection = self._props.FillDirection

    local getActiveTabIndex, setActiveTabIndex = scope.Value(defaultTab or 1)
    local _getActiveTabId, setActiveTabId = scope.Value(tabs[defaultTab] and tabs[defaultTab].id or "")

    -- Build tab buttons
    local tabButtons = {}
    for i, tab in ipairs(tabs) do
        local tabIndex = i
        local isActive = scope.Computed(function()
            return getActiveTabIndex() == tabIndex
        end)

        local tabButton = scope:Frame {
            Name = "TabButton_" .. (tab.id or tostring(i)),
            Size = UDim2.fromScale(0, 1),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundColor3 = scope.Computed(function()
                return if isActive() then activeTheme.Colors.Primary() else activeTheme.Colors.Surface()
            end),
            LayoutOrder = i,
            [Weave.OnEvent("MouseEnter")] = function()
                if not isActive() then
                    -- Subtle hover effect
                end
            end,
            [Weave.OnEvent("MouseLeave")] = function()
                -- Remove hover effect
            end,
            [Weave.OnEvent("Activated")] = function()
                if getActiveTabIndex() ~= tabIndex then
                    setActiveTabIndex(tabIndex)
                    setActiveTabId(tab.id)
                    if self._props.OnTabChanged then
                        self._props.OnTabChanged(tab.id, tabIndex)
                    end
                end
            end,
            [Weave.Children] = {
                scope:Corner { 
                    CornerRadius = scope.Computed(function()
                        return if isActive() then activeTheme.Radii.Medium() else UDim.new(0, 0)
                    end)
                },
                scope:Padding {
                    PaddingLeft = UDim.new(0.03, 0),
                    PaddingRight = UDim.new(0.03, 0),
                    PaddingTop = UDim.new(0.15, 0),
                    PaddingBottom = UDim.new(0.15, 0),
                },
                scope:ListLayout {
                    FillDirection = Enum.FillDirection.Horizontal,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = UDim.new(0.01, 0),
                },

                -- Tab Icon (optional)
                tab.icon and scope:ImageLabel {
                    Name = "Icon",
                    Size = UDim2.fromScale(0, 0.6),
                    AutomaticSize = Enum.AutomaticSize.X,
                    BackgroundTransparency = 1,
                    Image = tab.icon,
                    ImageColor3 = scope.Computed(function()
                        return if isActive() then activeTheme.Colors.TextOnPrimary() else activeTheme.Colors.TextSecondary()
                    end),
                    ScaleType = Enum.ScaleType.Fit,
                    LayoutOrder = 1,
                    [Weave.Children] = {
                        scope:AspectRatio { AspectRatio = 1 },
                    }
                } or scope.Fragment({}),

                -- Tab Label
                scope:TextLabel {
                    Name = "Label",
                    Size = UDim2.fromScale(0, 1),
                    AutomaticSize = Enum.AutomaticSize.X,
                    BackgroundTransparency = 1,
                    Text = tab.label,
                    TextColor3 = scope.Computed(function()
                        return if isActive() then activeTheme.Colors.TextOnPrimary() else activeTheme.Colors.TextSecondary()
                    end),
                    Font = activeTheme.Fonts.Body,
                    TextScaled = true,
                    LayoutOrder = 2,
                    [Weave.Children] = {
                        scope:TextSizeConstraint { MinTextSize = 10, MaxTextSize = 18 },
                    }
                },
            }
        }
        table.insert(tabButtons, tabButton)
    end

    -- Determine which elements go in header vs content based on position
    local headerOrder = tabPosition == "bottom" and 2 or 1
    local contentOrder = tabPosition == "bottom" and 1 or 2

    return scope:Frame {
        Name = self._props.Name or "Tabs",
        Size = self._props.Size or UDim2.fromScale(1, 1),
        Position = self._props.Position,
        AnchorPoint = self._props.AnchorPoint or Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        ZIndex = self._props.ZIndex or 1,
        [Weave.Children] = {
            scope:ListLayout {
                FillDirection = tabPosition == "bottom" and Enum.FillDirection.Vertical or Enum.FillDirection.Vertical,
                SortOrder = Enum.SortOrder.LayoutOrder,
                VerticalFlex = Enum.UIFlexAlignment.Fill,
            },

            -- Tab Header
            scope:Frame {
                Name = "TabHeader",
                Size = UDim2.fromScale(1, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                LayoutOrder = headerOrder,
                [Weave.Children] = {
                    scope:ListLayout {
                        FillDirection = fillDirection,
                        SortOrder = Enum.SortOrder.LayoutOrder,
                        HorizontalFlex = Enum.UIFlexAlignment.Fill,
                    },
                    scope:Padding {
                        PaddingLeft = UDim.new(0.01, 0),
                        PaddingRight = UDim.new(0.01, 0),
                        PaddingTop = UDim.new(0.01, 0),
                        PaddingBottom = UDim.new(0.01, 0),
                    },
                    scope:Fragment(tabButtons)
                }
            },

            -- Active Tab Content Container
            scope:Frame {
                Name = "TabContent",
                Size = UDim2.fromScale(1, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                LayoutOrder = contentOrder,
                [Weave.Children] = {
                    -- Content would be provided via Children prop
                }
            },
        }
    }
end

return Tabs
