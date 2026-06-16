local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Weave = require(ReplicatedStorage.Libraries.Weave)
local Builder = require(script.Parent.Parent.Builder)
local Theme = require(script.Parent.Parent.Theme)

local TextInput = setmetatable({}, {
    __index = Builder,
    __call = function(t, scope, props)
        local inst = t.new(scope)
        if not props then return inst:Build() end

        if props.Placeholder then inst:SetPlaceholder(props.Placeholder) end
        if props.Label then inst:SetLabel(props.Label) end
        if props.Value then inst:BindValue(props.Value) end
        if props.OnChanged then inst._props.OnChanged = props.OnChanged end
        if props.Validate then inst._props.Validate = props.Validate end
        if props.ClearTextOnFocus ~= nil then inst._props.ClearTextOnFocus = props.ClearTextOnFocus end

        if props.Name then inst:SetName(props.Name) end
        if props.Size then inst:SetSize(props.Size) end
        if props.Position then inst:SetPosition(props.Position) end
        if props.AnchorPoint then inst:SetAnchor(props.AnchorPoint) end
        if props.LayoutOrder then inst:SetLayoutOrder(props.LayoutOrder) end
        if props.ZIndex then inst:SetZIndex(props.ZIndex) end

        return inst:Build()
    end
})
TextInput.__index = TextInput

function TextInput.new(scope: Weave.Scope)
    local self = setmetatable(Builder.new(scope), TextInput)
    self._props.ClearTextOnFocus = false
    return self
end

function TextInput:SetPlaceholder(placeholder: string)
    self._props.Placeholder = placeholder
    return self
end

function TextInput:SetLabel(label: string)
    self._props.Label = label
    return self
end

function TextInput:BindValue(value: any)
    self._props.Value = value
    return self
end

function TextInput:Build()
    local scope = self._scope
    local activeTheme = Theme.getTheme()

    local getFocused, setFocused = scope.Value(false)

    local borderColor = scope.Spring(
        scope.Computed(function()
            return getFocused() and activeTheme.Colors.Accent() or activeTheme.Colors.PrimaryDark()
        end),
        30, 1
    )

    local children = {}

    -- Label above input
    if self._props.Label then
        table.insert(children, scope:TextLabel {
            Name = "Label",
            Size = UDim2.fromScale(1, 0),
            BackgroundTransparency = 1,
            Text = self._props.Label,
            TextColor3 = activeTheme.Colors.TextMuted,
            Font = activeTheme.Fonts.Body,
            TextScaled = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = 1,
            [Weave.Children] = {
                scope:FlexItem { FlexMode = Enum.UIFlexMode.Custom, GrowRatio = 1 },
                scope:TextSizeConstraint { MaxTextSize = 14, MinTextSize = 8 },
            }
        })
    end

    -- Input field
    local textBoxProps = {
        Name = "Input",
        Size = UDim2.fromScale(1, 0),
        BackgroundColor3 = activeTheme.Colors.Surface,
        Text = "",
        PlaceholderText = self._props.Placeholder or "",
        PlaceholderColor3 = activeTheme.Colors.TextMuted,
        TextColor3 = activeTheme.Colors.TextLight,
        Font = activeTheme.Fonts.Body,
        TextScaled = true,
        ClearTextOnFocus = self._props.ClearTextOnFocus,
        LayoutOrder = 2,

        [Weave.OnEvent("Focused")] = function() setFocused(true) end,
        [Weave.OnEvent("FocusLost")] = function(_, enterPressed)
            setFocused(false)
        end,

        [Weave.Children] = {
            scope:FlexItem { FlexMode = Enum.UIFlexMode.Custom, GrowRatio = 3 },
            scope:Corner { CornerRadius = UDim.new(0, 6) },
            -- scope:Stroke {
            --     Color = borderColor,
            --     Thickness = 2,
            -- },
            scope:Padding { scale = { 0.1, 0.15 } },
            scope:TextSizeConstraint { MaxTextSize = 18, MinTextSize = 8 },
        }
    }

    -- Two-way binding if Value state is provided
    if self._props.Value then
        textBoxProps[Weave.Bind("Text")] = self._props.Value
    end

    if self._props.OnChanged then
        textBoxProps[Weave.OnChange("Text")] = function()
            -- Validation could go here in the future
            if self._props.OnChanged then self._props.OnChanged() end
        end
    end

    table.insert(children, scope:TextBox(textBoxProps))

    return scope:Frame {
        Name = self._props.Name or "TextInput",
        Size = self._props.Size or UDim2.fromScale(1, 0.1),
        Position = self._props.Position,
        AnchorPoint = self._props.AnchorPoint,
        BackgroundTransparency = 1,
        LayoutOrder = self._props.LayoutOrder,
        ZIndex = self._props.ZIndex,
        [Weave.Children] = {
            scope:ListLayout {
                FillDirection = Enum.FillDirection.Vertical,
                VerticalFlex = Enum.UIFlexAlignment.Fill,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0.02, 0),
            },
            unpack(children)
        }
    }
end

return TextInput
