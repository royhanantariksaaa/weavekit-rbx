local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Weave = require(ReplicatedStorage.Libraries.Weave)
local Builder = require(script.Parent.Parent.Builder)
local Theme = require(script.Parent.Parent.Theme)

local Button = setmetatable({}, {
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
        if props.FlexMode then inst:SetFlex(props.FlexMode, props.GrowRatio) end
        if props.OnActivated then inst:OnActivated(props.OnActivated) end
        if props.OnMouseEnter then inst._props.OnMouseEnter = props.OnMouseEnter end
        if props.OnMouseLeave then inst._props.OnMouseLeave = props.OnMouseLeave end
        
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
Button.__index = Button

function Button.new(scope: Weave.Scope)
    local self = setmetatable(Builder.new(scope), Button)
    self._children = {}
    return self
end

function Button:SetBackgroundColor(color: any)
    self._props.BackgroundColor3 = color
    return self
end

function Button:SetBackgroundTransparency(transparency: any)
    self._props.BackgroundTransparency = transparency
    return self
end

function Button:SetCorner(radius: UDim)
    self._props.CornerRadius = radius
    return self
end

function Button:SetPadding(padding: UDim)
    self._props.Padding = padding
    return self
end

function Button:SetStroke(thickness: number, color: any)
    self._props.StrokeThickness = thickness
    self._props.StrokeColor = color
    return self
end

function Button:SetFlex(mode: Enum.UIFlexMode, ratio: number?)
    self._props.FlexMode = mode
    self._props.GrowRatio = ratio
    return self
end

function Button:OnActivated(callback: () -> ())
    self._props.ActivatedCallback = callback
    return self
end

function Button:AddChild(child: any)
    table.insert(self._children, child)
    return self
end

function Button:Build()
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
    
    if self._props.StrokeThickness or self._props.StrokeColor then
        table.insert(layoutChildren, scope:Stroke {
            Thickness = self._props.StrokeThickness or 1,
            Color = self._props.StrokeColor or activeTheme.Colors.PrimaryDark,
            Transparency = 0
        })
    end
    
    local wrapperChildren = {}
    if self._props.FlexMode then
        table.insert(wrapperChildren, scope:FlexItem {
            FlexMode = self._props.FlexMode,
            GrowRatio = self._props.GrowRatio or 1
        })
    end

    for _, child in ipairs(self._children) do
        table.insert(layoutChildren, child)
    end
    
    local getHovered, setHovered = scope.Value(false)
    local getPressed, setPressed = scope.Value(false)
    
    local scaleSpring = scope.Spring(
        scope.Computed(function()
            if getPressed() then return 0.95 end
            if getHovered() then return 1.02 end
            return 1.0
        end),
        40, 0.8
    )
    
    table.insert(layoutChildren, scope:UIScale {
        Scale = scaleSpring
    })
    
    table.insert(wrapperChildren, scope:Frame {
        Name = "Visuals",
        Size = UDim2.fromScale(1, 1),
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = scope.Computed(function()
            local c = self._props.BackgroundColor3 or activeTheme.Colors.Primary
            return if type(c) == "function" then c() else c
        end),
        BackgroundTransparency = self._props.BackgroundTransparency or 0,
        [Weave.Children] = layoutChildren
    })

    return scope:TextButton {
        Name = self._props.Name or "ButtonZone",
        Size = self._props.Size or UDim2.fromScale(1, 1),
        Position = self._props.Position or UDim2.fromScale(0.5, 0.5),
        AnchorPoint = self._props.AnchorPoint or Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        LayoutOrder = self._props.LayoutOrder,
        ZIndex = self._props.ZIndex,
        
        Text = "",
        AutoButtonColor = false,
        
        [Weave.OnEvent("MouseEnter")] = function() 
            setHovered(true)
            if self._props.OnMouseEnter then self._props.OnMouseEnter() end
        end,
        [Weave.OnEvent("MouseLeave")] = function() 
            setHovered(false)
            setPressed(false)
            if self._props.OnMouseLeave then self._props.OnMouseLeave() end
        end,
        [Weave.OnEvent("MouseButton1Down")] = function() setPressed(true) end,
        [Weave.OnEvent("MouseButton1Up")] = function() setPressed(false) end,
        [Weave.OnEvent("Activated")] = function()
            if self._props.ActivatedCallback then self._props.ActivatedCallback() end
        end,
        
        [Weave.Children] = wrapperChildren
    }
end

return Button
