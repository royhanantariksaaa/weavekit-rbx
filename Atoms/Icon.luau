local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Weave = require(ReplicatedStorage.Libraries.Weave)
local Builder = require(script.Parent.Parent.Builder)
local Theme = require(script.Parent.Parent.Theme)

local Icon = setmetatable({}, {
    __index = Builder,
    __call = function(t, scope, props)
        local inst = t.new(scope)
        if not props then return inst:Build() end
        local children = props[Weave.Children] or props.Children
        
        if props.Image then inst:SetImage(props.Image) end
        if props.ImageColor3 ~= nil then inst:SetImageColor(props.ImageColor3) end
        if props.ImageTransparency then inst:SetImageTransparency(props.ImageTransparency) end
        if props.ScaleType then inst:SetScaleType(props.ScaleType) end
        if props.AspectRatio then inst:SetAspectRatio(props.AspectRatio) end
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
Icon.__index = Icon

function Icon.new(scope: Weave.Scope)
    local self = setmetatable(Builder.new(scope), Icon)
    self._children = {}
    self._props.AspectRatio = 1
    self._props.ScaleType = Enum.ScaleType.Fit
    return self
end

function Icon:SetImage(image: any)
    self._props.Image = image
    return self
end

function Icon:SetImageColor(color: any)
    self._props.ImageColor3 = color
    return self
end

function Icon:SetImageTransparency(transparency: any)
    self._props.ImageTransparency = transparency
    return self
end

function Icon:SetScaleType(scaleType: Enum.ScaleType)
    self._props.ScaleType = scaleType
    return self
end

function Icon:SetAspectRatio(ratio: number)
    self._props.AspectRatio = ratio
    return self
end

function Icon:SetFlex(mode: Enum.UIFlexMode, ratio: number?)
    self._props.FlexMode = mode
    self._props.GrowRatio = ratio
    return self
end

function Icon:SetPadding(padding: UDim)
    self._props.Padding = padding
    return self
end

function Icon:AddChild(child: any)
    table.insert(self._children, child)
    return self
end

function Icon:Build()
    local scope = self._scope
    local activeTheme = Theme.getTheme()
    
    local layoutChildren = {}
    
    if self._props.AspectRatio then
        table.insert(layoutChildren, scope:AspectRatio {
            AspectRatio = self._props.AspectRatio
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

    for _, child in ipairs(self._children) do
        table.insert(layoutChildren, child)
    end
    
    return scope:ImageLabel {
        Name = self._props.Name or "Icon",
        Size = self._props.Size or UDim2.fromScale(1, 1),
        Position = self._props.Position or UDim2.fromScale(0, 0),
        AnchorPoint = self._props.AnchorPoint or Vector2.new(0, 0),
        BackgroundTransparency = 1,
        LayoutOrder = self._props.LayoutOrder,
        ZIndex = self._props.ZIndex,
        
        Image = self._props.Image or "",
        ImageColor3 = self._props.ImageColor3 or activeTheme.Colors.TextLight,
        ImageTransparency = self._props.ImageTransparency or 0,
        ScaleType = self._props.ScaleType,
        
        [Weave.Children] = layoutChildren
    }
end

return Icon
