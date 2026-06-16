local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Weave = require(ReplicatedStorage.Libraries.Weave)
local Builder = require(script.Parent.Parent.Builder)
local Theme = require(script.Parent.Parent.Theme)

--[[
    ColorPicker Organism
    
    A vertical list of color swatches. Clicking one sets the SelectedColor state.
    The currently selected swatch gets a white border highlight.

    Props:
        SelectedColor : Weave.Value<Color3>   — reactive state the picker reads/writes
        Colors        : { { Name: string, Color: Color3 } }?  — optional override list
        Size          : UDim2?
        LayoutOrder   : number?
]]

local DEFAULT_COLORS = {
    { Name = "Yellow",  Color = Color3.fromRGB(255, 246, 143) },
    { Name = "Pink",    Color = Color3.fromRGB(255, 182, 193) },
    { Name = "Green",   Color = Color3.fromRGB(152, 251, 152) },
    { Name = "Blue",    Color = Color3.fromRGB(173, 216, 230) },
    { Name = "Orange",  Color = Color3.fromRGB(255, 218, 185) },
    { Name = "White",   Color = Color3.fromRGB(255, 255, 255) },
    { Name = "Red",     Color = Color3.fromRGB(255, 120, 120) },
}

local ColorPicker = setmetatable({}, {
    __index = Builder,
    __call = function(t, scope, props)
        local inst = t.new(scope)
        if not props then return inst:Build() end

        inst._props.SelectedColor = props.SelectedColor
        inst._props.Colors = props.Colors or DEFAULT_COLORS
        if props.Size then inst:SetSize(props.Size) end
        if props.LayoutOrder then inst:SetLayoutOrder(props.LayoutOrder) end
        if props.Name then inst:SetName(props.Name) end

        return inst:Build()
    end
})
ColorPicker.__index = ColorPicker

function ColorPicker.new(scope)
    local self = setmetatable(Builder.new(scope), ColorPicker)
    self._props.SelectedColor = nil
    self._props.Colors = DEFAULT_COLORS
    return self
end

function ColorPicker:Build()
    local scope = self._scope
    local activeTheme = Theme.getTheme()
    local selectedColor = self._props.SelectedColor
    local colors = self._props.Colors

    local swatches = {}
    for i, item in ipairs(colors) do
        table.insert(swatches, scope:TextButton {
            Name = "Swatch_" .. item.Name,
            Size = UDim2.new(1, 0, 0, 36),
            BackgroundColor3 = item.Color,
            Text = "",
            AutoButtonColor = false,
            LayoutOrder = i,
            [Weave.Children] = {
                scope:Corner { CornerRadius = UDim.new(0, 6) },
                scope:Stroke {
                    Thickness = 3,
                    Color = Color3.new(1, 1, 1),
                    Transparency = selectedColor and scope.Computed(function()
                        local col = type(selectedColor) == "function" and selectedColor() or selectedColor
                        return col == item.Color and 0 or 1
                    end) or 1,
                },
            },
            [Weave.OnEvent("Activated")] = function()
                if type(selectedColor) == "table" and selectedColor.Set then
                    selectedColor:Set(item.Color)
                elseif type(self._props.SelectedColor) == "function" and self._props.OnSelected then
                    -- fallback if passed as external setter
                    self._props.OnSelected(item.Color)
                end
            end,
        })
    end

    -- Insert a header label at the top
    table.insert(swatches, 1, scope:TextLabel {
        Name = "ColorHeader",
        Text = "COLOR",
        Size = UDim2.new(1, 0, 0, 22),
        TextColor3 = activeTheme.Colors.TextLight,
        Font = activeTheme.Fonts.Heading,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        LayoutOrder = 0,
    })

    return scope:Frame {
        Name = self._props.Name or "ColorPicker",
        Size = self._props.Size or UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        LayoutOrder = self._props.LayoutOrder,
        [Weave.Children] = {
            scope:ListLayout {
                FillDirection = Enum.FillDirection.Vertical,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 6),
            },
            scope:Padding {
                PaddingLeft = UDim.new(0, 6),
                PaddingRight = UDim.new(0, 6),
                PaddingTop = UDim.new(0, 6),
                PaddingBottom = UDim.new(0, 6),
            },
            table.unpack(swatches),
        }
    }
end

return ColorPicker
