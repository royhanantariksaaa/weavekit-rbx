local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Weave = require(ReplicatedStorage.Libraries.Weave)
local Builder = require(script.Parent.Parent.Builder)
local Theme = require(script.Parent.Parent.Theme)

local Container = setmetatable({}, {
    __index = Builder,
    __call = function(t, scope, props)
        local inst = t.new(scope)
        if not props then return inst:Build() end
        local children = props[Weave.Children] or props.Children
        
        if props.BackgroundColor3 then inst:SetBackgroundColor(props.BackgroundColor3) end
        if props.BackgroundTransparency then inst:SetBackgroundTransparency(props.BackgroundTransparency) end
        if props.CornerRadius then inst:SetCorner(props.CornerRadius) end
        if props.Padding then inst:SetPadding(props.Padding) end
        if props.StrokeColor or props.StrokeThickness then inst:SetStroke(props.StrokeThickness or 1, props.StrokeColor) end
        if props.AspectRatio then inst:SetAspectRatio(props.AspectRatio) end
        if props.FlexMode then inst:SetFlex(props.FlexMode, props.GrowRatio) end
        if props.GradientColor then inst:SetGradient(props.GradientColor, props.GradientRotation) end
        if props.BackgroundImage then inst:SetImage(props.BackgroundImage, props.ImageTransparency, props.ImageColor3) end
        
        if props.Name then inst:SetName(props.Name) end
        if props.Size then inst:SetSize(props.Size) end
        if props.Position then inst:SetPosition(props.Position) end
        if props.AnchorPoint then inst:SetAnchor(props.AnchorPoint) end
        if props.LayoutOrder then inst:SetLayoutOrder(props.LayoutOrder) end
        if props.ZIndex then inst:SetZIndex(props.ZIndex) end
        if props.ClipsDescendants ~= nil then inst._props.ClipsDescendants = props.ClipsDescendants end
        if props.AutomaticSize ~= nil then inst._props.AutomaticSize = props.AutomaticSize end

        if children then
            for _, child in ipairs(children) do
                inst:AddChild(child)
            end
        end

        return inst:Build()
    end
})
Container.__index = Container

function Container.new(scope: Weave.Scope)
    local self = setmetatable(Builder.new(scope), Container)
    self._children = {}
    self._props.ClipsDescendants = false
    return self
end

function Container:SetBackgroundColor(color: any)
    self._props.BackgroundColor3 = color
    return self
end

function Container:SetBackgroundTransparency(transparency: any)
    self._props.BackgroundTransparency = transparency
    return self
end

function Container:SetCorner(radius: UDim)
    self._props.CornerRadius = radius
    return self
end

function Container:SetPadding(padding: UDim)
    self._props.Padding = padding
    return self
end

function Container:SetStroke(thickness: number, color: any)
    self._props.StrokeThickness = thickness
    self._props.StrokeColor = color
    return self
end

function Container:SetAspectRatio(ratio: number)
    self._props.AspectRatio = ratio
    return self
end

function Container:SetFlex(mode: Enum.UIFlexMode, ratio: number?)
    self._props.FlexMode = mode
    self._props.GrowRatio = ratio
    return self
end

function Container:SetGradient(color: any, rotation: number?)
    self._props.GradientColor = color
    self._props.GradientRotation = rotation
    return self
end

function Container:SetImage(imageId: any, transparency: any?, color: any?)
    self._props.BackgroundImage = imageId
    self._props.ImageTransparency = transparency
    self._props.ImageColor3 = color
    return self
end

function Container:AddChild(child: any)
    table.insert(self._children, child)
    return self
end

function Container:Build()
    local scope = self._scope
    local activeTheme = Theme.getTheme()
    
    local layoutChildren = {}
    
    if self._props.CornerRadius then
        table.insert(layoutChildren, scope:Corner { 
            CornerRadius = self._props.CornerRadius 
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
    
    -- Theme Modifier Injections (Idea A)
    local themeStylesFn = activeTheme.Components.Container.Styles()
    if themeStylesFn then
        for _, modifier in ipairs(themeStylesFn(scope) or {}) do
            table.insert(layoutChildren, modifier)
        end
    end

    -- Stroke Default fallback
    if self._props.StrokeThickness or self._props.StrokeColor then
        table.insert(layoutChildren, scope:Stroke {
            Thickness = self._props.StrokeThickness or 1,
            Color = self._props.StrokeColor or activeTheme.Colors.PrimaryDark,
            Transparency = 0
        })
    elseif activeTheme.Styles.UseGlobalBorders() then
        table.insert(layoutChildren, scope:Stroke {
            Thickness = activeTheme.Styles.GlobalBorderThickness() or 1,
            Color = activeTheme.Styles.GlobalBorderColor() or activeTheme.Colors.PrimaryDark,
            Transparency = 0
        })
    end

    if self._props.GradientColor then
        table.insert(layoutChildren, scope:UIGradient {
            Color = self._props.GradientColor,
            Rotation = self._props.GradientRotation or 0
        })
    end

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

    for _, child in ipairs(self._children) do
        table.insert(layoutChildren, child)
    end
    
    local props = {
        Name = self._props.Name or "Container",
        Size = self._props.Size or UDim2.fromScale(1, 1),
        Position = self._props.Position or UDim2.fromScale(0, 0),
        AnchorPoint = self._props.AnchorPoint or Vector2.new(0, 0),
        BackgroundColor3 = self._props.BackgroundColor3 or activeTheme.Colors.Surface,
        BackgroundTransparency = self._props.BackgroundTransparency or (self._props.BackgroundColor3 == nil and 1 or 0),
        LayoutOrder = self._props.LayoutOrder,
        ZIndex = self._props.ZIndex,
        ClipsDescendants = self._props.ClipsDescendants,
        AutomaticSize = self._props.AutomaticSize,
        [Weave.Children] = layoutChildren
    }

    if self._props.BackgroundImage then
        props.Image = self._props.BackgroundImage
        if self._props.ImageTransparency then
            props.ImageTransparency = self._props.ImageTransparency
        end
        if self._props.ImageColor3 then
            props.ImageColor3 = self._props.ImageColor3
        end
        props.ScaleType = Enum.ScaleType.Crop
        return scope:ImageLabel(props)
    else
        return scope:Frame(props)
    end
end

return Container
