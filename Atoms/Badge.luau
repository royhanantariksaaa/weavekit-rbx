local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Weave = require(ReplicatedStorage.Libraries.Weave)
local Builder = require(script.Parent.Parent.Builder)
local Theme = require(script.Parent.Parent.Theme)
local TextAtom = require(script.Parent.Text)

local Badge = setmetatable({}, {
    __index = Builder,
    __call = function(t, scope, props)
        local inst = t.new(scope)
        if not props then return inst:Build() end
        local children = props[Weave.Children] or props.Children
        
        if props.Value then inst:SetValue(props.Value) end
        if props.Color then inst:SetColor(props.Color) end
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
Badge.__index = Badge

function Badge.new(scope: Weave.Scope)
    local self = setmetatable(Builder.new(scope), Badge)
    self._children = {}
    self._props.Value = ""
    return self
end

function Badge:SetValue(value: any)
    self._props.Value = value
    return self
end

function Badge:SetColor(color: any)
    self._props.Color = color
    return self
end

function Badge:SetPadding(padding: UDim)
    self._props.Padding = padding
    return self
end

function Badge:AddChild(child: any)
    table.insert(self._children, child)
    return self
end

function Badge:Build()
    local scope = self._scope
    local activeTheme = Theme.getTheme()
    
    local valueState = self._props.Value
    
    local layoutChildren = {
        scope:AspectRatio { AspectRatio = 1 },
        scope:Corner { CornerRadius = UDim.new(1, 0) },
        TextAtom(scope, {
            Text = valueState,
            Font = activeTheme.Fonts.Heading,
            MaxSize = 14,
            TextColor3 = Color3.new(1, 1, 1),
        })
    }
    
    if self._props.Padding then
        local p = Builder.ParsePadding(self._props.Padding)
        table.insert(layoutChildren, scope:Padding {
            PaddingTop = p.Top,
            PaddingRight = p.Right,
            PaddingBottom = p.Bottom,
            PaddingLeft = p.Left
        })
    end

    for _, child in ipairs(self._children) do
        table.insert(layoutChildren, child)
    end
    
    return scope:Frame {
        Name = self._props.Name or "Badge",
        Size = self._props.Size or UDim2.fromScale(1, 1),
        Position = self._props.Position or UDim2.fromScale(0.5, 0.5),
        AnchorPoint = self._props.AnchorPoint or Vector2.new(0.5, 0.5),
        BackgroundColor3 = self._props.Color or activeTheme.Colors.Danger,
        LayoutOrder = self._props.LayoutOrder,
        ZIndex = self._props.ZIndex,
        [Weave.Children] = layoutChildren
    }
end

return Badge
