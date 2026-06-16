    local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Weave = require(ReplicatedStorage.Libraries.Weave)
local Builder = require(script.Parent.Parent.Builder)
local Theme = require(script.Parent.Parent.Theme)

local Text = setmetatable({}, {
    __index = Builder,
    __call = function(t, scope, props)
        local inst = t.new(scope)
        if not props then return inst:Build() end
        local children = props[Weave.Children] or props.Children
        
        if props.Text then inst:SetText(props.Text) end
        if props.TextColor3 then inst:SetTextColor(props.TextColor3) end
        if props.Font then inst:SetFont(props.Font) end
        if props.TextScaled ~= nil then inst._props.TextScaled = props.TextScaled end
        if props.MaxSize then inst:SetMaxSize(props.MaxSize) end
        if props.MinSize then inst:SetMinSize(props.MinSize) end
        if props.TextXAlignment then inst:SetXAlignment(props.TextXAlignment) end
        if props.TextYAlignment then inst:SetYAlignment(props.TextYAlignment) end
        if props.FlexMode then inst:SetFlex(props.FlexMode, props.GrowRatio) end
        if props.StrokeColor or props.StrokeThickness then inst:SetStroke(props.StrokeThickness or 1, props.StrokeColor) end
        if props.Padding then inst:SetPadding(props.Padding) end
        
        if props.Name then inst:SetName(props.Name) end
        if props.Size then inst:SetSize(props.Size) end
        if props.Position then inst:SetPosition(props.Position) end
        if props.AnchorPoint then inst:SetAnchor(props.AnchorPoint) end
        if props.LayoutOrder then inst:SetLayoutOrder(props.LayoutOrder) end
        if props.ZIndex then inst:SetZIndex(props.ZIndex) end

        if children then
            for _, child in ipairs(children) do
                inst:AddChild(child)
            end
        end

        return inst:Build()
    end
})
Text.__index = Text

function Text.new(scope: Weave.Scope)
    local self = setmetatable(Builder.new(scope), Text)
    self._children = {}
    self._props.TextScaled = true
    return self
end

function Text:SetText(text: any)
    self._props.Text = text
    return self
end

function Text:SetTextColor(color: any)
    self._props.TextColor3 = color
    return self
end

function Text:SetFont(font: Enum.Font)
    self._props.Font = font
    return self
end

function Text:SetMaxSize(size: number)
    self._props.MaxSize = size
    return self
end

function Text:SetMinSize(size: number)
    self._props.MinSize = size
    return self
end

function Text:SetXAlignment(align: Enum.TextXAlignment)
    self._props.TextXAlignment = align
    return self
end

function Text:SetYAlignment(align: Enum.TextYAlignment)
    self._props.TextYAlignment = align
    return self
end

function Text:SetFlex(mode: Enum.UIFlexMode, ratio: number?)
    self._props.FlexMode = mode
    self._props.GrowRatio = ratio
    return self
end

function Text:SetStroke(thickness: number, color: any)
    self._props.StrokeThickness = thickness
    self._props.StrokeColor = color
    return self
end

function Text:SetPadding(padding: UDim)
    self._props.Padding = padding
    return self
end

function Text:AddChild(child: any)
    table.insert(self._children, child)
    return self
end

function Text:Build()
    local scope = self._scope
    local activeTheme = Theme.getTheme()
    
    local layoutChildren = {}
    
    if self._props.TextScaled and (self._props.MaxSize or self._props.MinSize) then
        table.insert(layoutChildren, scope:TextSizeConstraint {
            MaxTextSize = self._props.MaxSize or 100,
            MinTextSize = self._props.MinSize or 1,
        })
    end
    
    if self._props.FlexMode then
        table.insert(layoutChildren, scope:FlexItem {
            FlexMode = self._props.FlexMode,
            GrowRatio = self._props.GrowRatio or 1
        })
    end

    if self._props.Padding then
        local p = Builder.ParsePadding(self._props.Padding)
        table.insert(layoutChildren, scope:Padding {
            PaddingTop = p.Top,
            PaddingRight = p.Right,
            PaddingBottom = p.Bottom,
            PaddingLeft = p.Left
        })
    end

    local themeStylesFn = activeTheme.Components.Text.Styles()
    if themeStylesFn then
        for _, modifier in ipairs(themeStylesFn(scope) or {}) do
            table.insert(layoutChildren, modifier)
        end
    end

    if self._props.StrokeThickness or self._props.StrokeColor then
        table.insert(layoutChildren, scope:UIStroke {
            Thickness = self._props.StrokeThickness or 1,
            Color = self._props.StrokeColor or activeTheme.Colors.PrimaryDark,
            Transparency = 0
        })
    end

    for _, child in ipairs(self._children) do
        table.insert(layoutChildren, child)
    end
    
    return scope:TextLabel {
        Name = self._props.Name or "TextLabel",
        Size = self._props.Size or UDim2.fromScale(1, 1),
        Position = self._props.Position or UDim2.fromScale(0, 0),
        AnchorPoint = self._props.AnchorPoint or Vector2.new(0, 0),
        BackgroundTransparency = 1,
        LayoutOrder = self._props.LayoutOrder,
        ZIndex = self._props.ZIndex,
        
        Text = self._props.Text or "Text",
        TextColor3 = scope.Computed(function()
            local c = self._props.TextColor3 or activeTheme.Colors.TextLight
            return if type(c) == "function" then c() else c
        end),
        Font = self._props.Font or activeTheme.Fonts.Body,
        TextScaled = self._props.TextScaled,
        TextXAlignment = self._props.TextXAlignment or Enum.TextXAlignment.Center,
        TextYAlignment = self._props.TextYAlignment or Enum.TextYAlignment.Center,
        
        [Weave.Children] = layoutChildren
    }
end

return Text
