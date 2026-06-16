local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Weave = require(ReplicatedStorage.Libraries.Weave)
local Builder = require(script.Parent.Parent.Builder)
local Theme = require(script.Parent.Parent.Theme)

local Checkbox = setmetatable({}, {
    __index = Builder,
    __call = function(t, scope, props)
        local inst = t.new(scope)
        if not props then return inst:Build() end

        if props.Value then inst:BindValue(props.Value) end
        if props.OnChanged then inst._props.OnChanged = props.OnChanged end
        if props.Label then inst:SetLabel(props.Label) end
        if props.CheckColor then inst._props.CheckColor = props.CheckColor end

        if props.Name then inst:SetName(props.Name) end
        if props.Size then inst:SetSize(props.Size) end
        if props.Position then inst:SetPosition(props.Position) end
        if props.AnchorPoint then inst:SetAnchor(props.AnchorPoint) end
        if props.LayoutOrder then inst:SetLayoutOrder(props.LayoutOrder) end
        if props.ZIndex then inst:SetZIndex(props.ZIndex) end

        return inst:Build()
    end
})
Checkbox.__index = Checkbox

function Checkbox.new(scope: Weave.Scope)
    local self = setmetatable(Builder.new(scope), Checkbox)
    return self
end

function Checkbox:BindValue(value: any)
    self._props.Value = value
    return self
end

function Checkbox:SetLabel(label: string)
    self._props.Label = label
    return self
end

function Checkbox:Build()
    local scope = self._scope
    local activeTheme = Theme.getTheme()

    local getChecked, setChecked
    if type(self._props.Value) == "function" then
        getChecked = self._props.Value
        setChecked = nil
    else
        getChecked, setChecked = scope.Value(self._props.Value or false)
    end
    
    local checkColor = self._props.CheckColor or activeTheme.Colors.Accent

    -- Animated check scale
    local checkScale = scope.Spring(
        scope.Computed(function()
            return getChecked() and 1 or 0
        end),
        40, 0.7
    )

    -- Animated border color
    local borderColor = scope.Spring(
        scope.Computed(function()
            local clr = type(checkColor) == "function" and checkColor() or checkColor
            return getChecked() and clr or activeTheme.Colors.TextPrimary()
        end),
        25, 1
    )
    
    local boxColor = scope.Spring(
        scope.Computed(function()
            local clr = type(checkColor) == "function" and checkColor() or checkColor
            return getChecked() and clr or activeTheme.Colors.Primary()
        end),
        25, 1
    )
    
    local checkMarkColor = scope.Computed(function()
        return activeTheme.Colors.Surface()
    end)

    return scope:Frame {
        Name = self._props.Name or "Checkbox",
        Size = self._props.Size or UDim2.fromScale(1, 0.08),
        Position = self._props.Position,
        AnchorPoint = self._props.AnchorPoint,
        BackgroundTransparency = 1,
        LayoutOrder = self._props.LayoutOrder,
        ZIndex = self._props.ZIndex,
        
        [Weave.Children] = {
            scope:ListLayout {
                FillDirection = Enum.FillDirection.Horizontal,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                Padding = UDim.new(0, 10),
                SortOrder = Enum.SortOrder.LayoutOrder,
            },
            -- The box
            scope:TextButton {
                Name = "Box",
                Size = UDim2.fromScale(1, 1),
                BackgroundColor3 = boxColor,
                Text = "",
                AutoButtonColor = false,
                LayoutOrder = 1,
    
                [Weave.OnEvent("Activated")] = function()
                    local newVal = not getChecked()
                    if setChecked then setChecked(newVal) end
                    if self._props.OnChanged then self._props.OnChanged(newVal) end
                end,
    
                [Weave.Children] = {
                    scope:AspectRatio { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height },
                    scope:Corner { CornerRadius = UDim.new(0, 4) },
                    scope:Stroke {
                        Color = borderColor,
                        Thickness = 2,
                    },
    
                    -- Checkmark
                    scope:TextLabel {
                        Name = "Check",
                        Size = UDim2.fromScale(1, 1),
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        Position = UDim2.fromScale(0.5, 0.5),
                        BackgroundTransparency = 1,
                        Text = "✓",
                        TextColor3 = checkMarkColor,
                        Font = Enum.Font.GothamBold,
                        TextScaled = true,
                        [Weave.Children] = {
                            scope:UIScale {
                                Scale = checkScale
                            },
                        }
                    }
                }
            },
            
            -- Optional label
            self._props.Label and scope:TextButton {
                Name = "Label",
                Size = UDim2.new(1, -34, 1, 0), -- 1 scale minus the checkbox box offset + padding
                BackgroundTransparency = 1,
                Text = self._props.Label,
                TextColor3 = activeTheme.Colors.TextLight,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Center,
                Font = activeTheme.Fonts.Body,
                TextScaled = false, -- Disable TextScaled so label scales naturally alongside Checkbox height
                TextSize = 16,
                LayoutOrder = 2,
                [Weave.OnEvent("Activated")] = function()
                    local newVal = not getChecked()
                    if setChecked then setChecked(newVal) end
                    if self._props.OnChanged then self._props.OnChanged(newVal) end
                end,
                [Weave.Children] = {
                    scope:TextSizeConstraint { MaxTextSize = 16, MinTextSize = 8 },
                }
            } or scope.Fragment({})
        }
    }
end

return Checkbox
