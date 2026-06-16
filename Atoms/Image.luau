local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Weave = require(ReplicatedStorage.Libraries.Weave)
local Builder = require(script.Parent.Parent.Builder)
local Theme = require(script.Parent.Parent.Theme)

local Image = setmetatable({}, {
    __index = Builder,
    __call = function(t, scope, props)
        local inst = t.new(scope)
        if not props then return inst:Build() end

        if props.Image then inst:SetImage(props.Image) end
        if props.ImageColor3 ~= nil then inst:SetImageColor(props.ImageColor3) end
        if props.ImageTransparency ~= nil then inst:SetImageTransparency(props.ImageTransparency) end
        if props.ScaleType then inst:SetScaleType(props.ScaleType) end
        if props.FitAspect then inst:SetFitAspect(props.FitAspect) end
        if props.IsCircular ~= nil then inst:SetCircular(props.IsCircular) end
        if props.BackgroundColor3 ~= nil then inst:SetBackgroundColor(props.BackgroundColor3) end

        if props.Name then inst:SetName(props.Name) end
        if props.Size then inst:SetSize(props.Size) end
        if props.Position then inst:SetPosition(props.Position) end
        if props.AnchorPoint then inst:SetAnchor(props.AnchorPoint) end
        if props.LayoutOrder then inst:SetLayoutOrder(props.LayoutOrder) end
        if props.ZIndex then inst:SetZIndex(props.ZIndex) end

        local children = props[Weave.Children] or props.Children
        if children then
            inst._props.Children = children
        end

        return inst:Build()
    end
})

function Image.new(scope: Weave.Scope)
    local self = setmetatable(Builder.new(scope), Image)
    self._props.ScaleType = Enum.ScaleType.Fit
    self._props.FitAspect = nil -- UDim2 for custom sizing
    self._props.IsCircular = false
    self._props.BackgroundColor3 = nil
    self._props.Children = {}
    return self
end

function Image:SetImage(image: any)
    self._props.Image = image
    return self
end

function Image:SetImageColor(color: any)
    self._props.ImageColor3 = color
    return self
end

function Image:SetImageTransparency(transparency: any)
    self._props.ImageTransparency = transparency
    return self
end

function Image:SetScaleType(scaleType: Enum.ScaleType)
    self._props.ScaleType = scaleType
    return self
end

function Image:SetFitAspect(aspect: UDim2)
    self._props.FitAspect = aspect
    return self
end

function Image:SetCircular(isCircular: boolean)
    self._props.IsCircular = isCircular
    return self
end

function Image:SetBackgroundColor(color: any)
    self._props.BackgroundColor3 = color
    return self
end

function Image:Build()
    local scope = self._scope
    local activeTheme = Theme.getTheme()

    local isCircular = self._props.IsCircular
    local fitAspect = self._props.FitAspect
    local children = self._props.Children or {}

    -- Build children array
    local layoutChildren = {}

    -- Add aspect ratio if provided
    if fitAspect then
        table.insert(layoutChildren, scope:AspectRatio {
            AspectRatio = fitAspect
        })
    end

    -- Add corner for circular masking
    if isCircular then
        table.insert(layoutChildren, scope:Corner { CornerRadius = UDim.new(0.5, 0) })
    end

    -- Add custom children
    for _, child in ipairs(children) do
        table.insert(layoutChildren, child)
    end

    return scope:ImageLabel {
        Name = self._props.Name or "Image",
        Size = self._props.Size or UDim2.fromScale(1, 1),
        Position = self._props.Position or UDim2.fromScale(0, 0),
        AnchorPoint = self._props.AnchorPoint or Vector2.new(0, 0),
        BackgroundColor3 = self._props.BackgroundColor3 or activeTheme.Colors.Surface,
        ClipsDescendants = isCircular,
        LayoutOrder = self._props.LayoutOrder,
        ZIndex = self._props.ZIndex,

        Image = self._props.Image or "",
        ImageColor3 = self._props.ImageColor3 or activeTheme.Colors.TextPrimary,
        ImageTransparency = self._props.ImageTransparency or 0,
        ScaleType = self._props.ScaleType,
        BackgroundTransparency = self._props.BackgroundColor3 and 0 or 1,

        [Weave.Children] = layoutChildren
    }
end

return Image
