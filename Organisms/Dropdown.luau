local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Weave = require(ReplicatedStorage.Libraries.Weave)
local Builder = require(script.Parent.Parent.Builder)
local Theme = require(script.Parent.Parent.Theme)

local Dropdown = setmetatable({}, {
    __index = Builder,
    __call = function(t, scope, props)
        local inst = t.new(scope)
        if not props then return inst:Build() end

        if props.Options then inst:SetOptions(props.Options) end
        if props.Selected then inst:BindSelected(props.Selected) end
        if props.Placeholder then inst._props.Placeholder = props.Placeholder end
        if props.OnSelected then inst._props.OnSelected = props.OnSelected end

        if props.Name then inst:SetName(props.Name) end
        if props.Size then inst:SetSize(props.Size) end
        if props.Position then inst:SetPosition(props.Position) end
        if props.AnchorPoint then inst:SetAnchor(props.AnchorPoint) end
        if props.LayoutOrder then inst:SetLayoutOrder(props.LayoutOrder) end
        if props.ZIndex then inst:SetZIndex(props.ZIndex) end

        if props.NoCorner then inst._props.NoCorner = props.NoCorner end
        if props.NoStroke then inst._props.NoStroke = props.NoStroke end

        return inst:Build()
    end
})
Dropdown.__index = Dropdown

function Dropdown.new(scope: Weave.Scope)
    local self = setmetatable(Builder.new(scope), Dropdown)
    self._props.Options = {}
    self._props.Placeholder = "Select..."
    return self
end

function Dropdown:SetOptions(options: {string})
    self._props.Options = options
    return self
end

function Dropdown:BindSelected(selected: any)
    self._props.Selected = selected
    return self
end

function Dropdown:Build()
    local scope = self._scope
    local activeTheme = Theme.getTheme()

    local getOpen, setOpen = scope.Value(false)
    
    local getSelected, setSelected
    if type(self._props.Selected) == "function" then
        getSelected = self._props.Selected
        setSelected = nil
    else
        getSelected, setSelected = scope.Value(self._props.Selected or "")
    end

    -- Display text
    local displayText = scope.Computed(function()
        local val = getSelected()
        if val == "" or val == nil then return self._props.Placeholder end
        return val
    end)

    -- Dropdown list height animation
    local listHeight = scope.Spring(
        scope.Computed(function()
            return getOpen() and math.min(#self._props.Options * 32, 160) or 0
        end),
        35, 1
    )
    
    local getAbsolutePos, setAbsolutePos = scope.Value(Vector2.new())
    local getAbsoluteSize, setAbsoluteSize = scope.Value(Vector2.new())
    local triggerRef = scope.Ref()
    
    -- Poll AbsolutePosition while open to ensure it perfectly tracks Window drags
    local runService = game:GetService("RunService")
    scope._trove:Add(runService.RenderStepped:Connect(function()
        if getOpen() then
            local inst = triggerRef:Get()
            if inst then
                local currentPos = inst.AbsolutePosition
                if getAbsolutePos() ~= currentPos then
                    setAbsolutePos(currentPos)
                    setAbsoluteSize(inst.AbsoluteSize)
                end
            end
        end
    end))

    -- Asynchronous Portal root discovery
    local getPortalRoot, setPortalRoot = scope.Value(nil)
    task.spawn(function()
        local player = game.Players.LocalPlayer
        if player then
            local playerGui = player:WaitForChild("PlayerGui")
            local gui = playerGui:FindFirstChild("WeavePortalGui") or Instance.new("ScreenGui")
            gui.Name = "WeavePortalGui"
            gui.ResetOnSpawn = false
            gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
            gui.DisplayOrder = 10001 -- Higher than LoadingScreen (9999)
            gui.Parent = playerGui
            setPortalRoot(gui)
        end
    end)

    -- Build option buttons
    local optionButtons = {
        scope:ListLayout {
            FillDirection = Enum.FillDirection.Vertical,
            SortOrder = Enum.SortOrder.LayoutOrder,
        },
    }

    for i, option in ipairs(self._props.Options) do
        local getHovered, setHovered = scope.Value(false)
        
        table.insert(optionButtons, scope:TextButton {
            Name = "Option_" .. i,
            Size = UDim2.new(1, 0, 0, 32),
            BackgroundColor3 = activeTheme.Colors.Accent,
            BackgroundTransparency = scope.Computed(function()
                return getHovered() and 0 or 1
            end),
            Text = "",
            AutoButtonColor = false,
            LayoutOrder = i,

            [Weave.OnEvent("Activated")] = function()
                if setSelected then setSelected(option) end
                setOpen(false)
                if self._props.OnSelected then self._props.OnSelected(option) end
            end,
            [Weave.OnEvent("MouseEnter")] = function() setHovered(true) end,
            [Weave.OnEvent("MouseLeave")] = function() setHovered(false) end,

            [Weave.Children] = {
                scope:TextLabel {
                    Name = "OptionText",
                    Position = UDim2.fromOffset(12, 0),
                    Size = UDim2.new(1, -24, 1, 0),
                    BackgroundTransparency = 1,
                    Text = option,
                    TextColor3 = scope.Computed(function()
                        return getHovered() and activeTheme.Colors.PrimaryDark() or activeTheme.Colors.TextLight()
                    end),
                    Font = scope.Computed(function() return activeTheme.Fonts.Heading() end),
                    TextSize = 15,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Center,
                }
            }
        })
    end

    local getTriggerHovered, setTriggerHovered = scope.Value(false)
    local triggerScale = scope.Spring(
        scope.Computed(function() return getTriggerHovered() and 1.02 or 1 end),
        40, 0.8
    )

    return scope:Frame {
        Name = self._props.Name or "Dropdown",
        Size = self._props.Size or UDim2.fromScale(1, 0.1),
        Position = self._props.Position,
        AnchorPoint = self._props.AnchorPoint,
        BackgroundTransparency = 1,
        LayoutOrder = self._props.LayoutOrder,
        ZIndex = self._props.ZIndex,
        ClipsDescendants = false,

        [Weave.Children] = {
            scope:UIScale { Scale = triggerScale },

            -- Trigger button
            scope:TextButton {
                Name = "Trigger",
                Size = UDim2.fromScale(1, 1),
                BackgroundColor3 = activeTheme.Colors.Background,
                Text = "", -- Moved text to a label for better layout control
                AutoButtonColor = false,

                [Weave.Ref] = triggerRef,
                [Weave.OnEvent("MouseEnter")] = function() setTriggerHovered(true) end,
                [Weave.OnEvent("MouseLeave")] = function() setTriggerHovered(false) end,
                [Weave.OnChange("AbsolutePosition")] = function()
                    local inst = triggerRef:Get()
                    if inst then setAbsolutePos(inst.AbsolutePosition) end
                end,
                [Weave.OnChange("AbsoluteSize")] = function()
                    local inst = triggerRef:Get()
                    if inst then setAbsoluteSize(inst.AbsoluteSize) end
                end,

                [Weave.OnEvent("Activated")] = function()
                    setOpen(not getOpen())
                end,

                [Weave.Children] = (function()
                    local children = {}

                    if not self._props.NoCorner then
                        table.insert(children, scope:Corner { CornerRadius = UDim.new(0, 8) })
                    end
                    if not self._props.NoStroke then
                        table.insert(children, scope:Stroke {
                            Color = activeTheme.Colors.Primary,
                            Thickness = 2,
                            Transparency = 0.2,
                        })
                    end

                    table.insert(children, scope:Padding { offset = {0, 12} })

                    table.insert(children, scope:ListLayout {
                        FillDirection = Enum.FillDirection.Horizontal,
                        VerticalAlignment = Enum.VerticalAlignment.Center,
                        Padding = UDim.new(0, 4),
                    })

                    -- Label
                    table.insert(children, scope:TextLabel {
                        Name = "Label",
                        Size = UDim2.new(0, 0, 1, 0),
                        BackgroundTransparency = 1,
                        Text = displayText,
                        TextColor3 = scope.Computed(function() return activeTheme.Colors.TextLight() end),
                        Font = scope.Computed(function() return activeTheme.Fonts.Heading() end),
                        TextSize = 15,
                        TextTruncate = Enum.TextTruncate.AtEnd,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        LayoutOrder = 1,
                        [Weave.Children] = {
                            scope:FlexItem { FlexMode = Enum.UIFlexMode.Fill },
                        }
                    })

                    -- Chevron Icon
                    table.insert(children, scope:ImageLabel {
                        Name = "Chevron",
                        Size = UDim2.fromScale(0.5, 0.5),
                        BackgroundTransparency = 1,
                        Image = "rbxassetid://10734891461", -- Chevron down
                        ImageColor3 = activeTheme.Colors.TextLight,
                        ScaleType = Enum.ScaleType.Fit,
                        LayoutOrder = 2,
                        Rotation = scope.Computed(function()
                            return getOpen() and 180 or 0
                        end),
                        [Weave.Children] = {
                            scope:AspectRatio { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height }
                        }
                    })

                    return children
                end)()
            },

            -- Options list using Portal
            scope.Portal({
                Target = getPortalRoot,
                [Weave.Children] = {
                   scope:ScrollingFrame {
                        Name = "OptionsList",
                        Position = scope.Computed(function()
                            local pos = getAbsolutePos()
                            local size = getAbsoluteSize()
                            return UDim2.fromOffset(pos.X, pos.Y + size.Y + 2)
                        end),
                        Size = scope.Computed(function()
                            local size = getAbsoluteSize()
                            local lh = type(listHeight) == "function" and listHeight() or listHeight
                            return UDim2.new(0, size.X, 0, lh)
                        end),
                        BackgroundColor3 = activeTheme.Colors.Primary,
                        BackgroundTransparency = 0,
                        ScrollBarThickness = 3,
                        CanvasSize = UDim2.new(0, 0, 0, #self._props.Options * 32),
                        ClipsDescendants = true,
                        Visible = scope.Computed(function()
                            local lh = type(listHeight) == "function" and listHeight() or listHeight
                            return lh > 0
                        end),
                        ZIndex = 110,
        
                        [Weave.Children] = (function()
                            local children = {}
                            
                            -- Theme Dropdown style injection (gradient, stroke, etc.)
                            local themeStylesFn = activeTheme.Components.Dropdown.Styles()
                            if themeStylesFn then
                                for _, modifier in ipairs(themeStylesFn(scope) or {}) do
                                    table.insert(children, modifier)
                                end
                            end

                            table.insert(children, scope:Padding { offset = {0, 4} })
                            
                            if not self._props.NoCorner then
                                table.insert(children, scope:Corner { CornerRadius = activeTheme.Radii.Medium })
                            end
                            
                            -- Add layout and buttons from optionButtons
                            for _, child in ipairs(optionButtons) do
                                table.insert(children, child)
                            end
                            
                            return children
                        end)()
                    } 
                }
            })
        }
    }
end

return Dropdown
