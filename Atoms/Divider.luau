local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Weave = require(ReplicatedStorage.Libraries.Weave)
local Builder = require(script.Parent.Parent.Builder)
local Theme = require(script.Parent.Parent.Theme)

local Divider = setmetatable({}, {
    __index = Builder,
    __call = function(t, scope, props)
        local inst = t.new(scope)
        if not props then return inst:Build() end
        local children = props[Weave.Children] or props.Children
        
        if props.Thickness then inst:SetThickness(props.Thickness) end
        if props.Direction then inst:SetDirection(props.Direction) end
        if props.Color then inst:SetColor(props.Color) end
        if props.Transparency then inst:SetTransparency(props.Transparency) end
        if props.FlexMode then inst:SetFlex(props.FlexMode, props.GrowRatio) end
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
Divider.__index = Divider

function Divider.new(scope: Weave.Scope)
    local self = setmetatable(Builder.new(scope), Divider)
    self._children = {}
    self._props.Thickness = 1
    self._props.Direction = "Horizontal"
    return self
end

function Divider:SetThickness(thickness: number)
    self._props.Thickness = thickness
    return self
end

function Divider:SetDirection(direction: "Horizontal" | "Vertical")
    self._props.Direction = direction
    return self
end

function Divider:SetColor(color: any)
    self._props.Color = color
    return self
end

function Divider:SetTransparency(transparency: any)
    self._props.Transparency = transparency
    return self
end

function Divider:SetFlex(mode: Enum.UIFlexMode, ratio: number?)
    self._props.FlexMode = mode
    self._props.GrowRatio = ratio
    return self
end

function Divider:SetPadding(padding: UDim)
    self._props.Padding = padding
    return self
end

function Divider:AddChild(child: any)
    table.insert(self._children, child)
    return self
end

function Divider:Build()
    local scope = self._scope
    local activeTheme = Theme.getTheme()
    
    local layoutChildren = {}
    
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
    
    for _, child in ipairs(self._children) do
        table.insert(layoutChildren, child)
    end

    local size = self._props.Direction == "Horizontal" 
        and UDim2.new(1, 0, 0, self._props.Thickness) 
        or UDim2.new(0, self._props.Thickness, 1, 0)

    local sizeProp = self._props.Size or size

    return scope:Frame {
        Name = self._props.Name or "Divider",
        Size = sizeProp,
        Position = self._props.Position or UDim2.fromScale(0, 0),
        AnchorPoint = self._props.AnchorPoint or Vector2.new(0, 0),
        BackgroundColor3 = self._props.Color or activeTheme.Colors.PrimaryDark,
        BackgroundTransparency = self._props.Transparency or 0.5,
        LayoutOrder = self._props.LayoutOrder,
        ZIndex = self._props.ZIndex,
        [Weave.Children] = layoutChildren
    }
end

return Divider
