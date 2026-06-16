local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Weave = require(ReplicatedStorage.Libraries.Weave)
local Builder = require(script.Parent.Parent.Builder)
local Theme = require(script.Parent.Parent.Theme)

local Circle = setmetatable({}, {
    __index = Builder,
    __call = function(t, scope, props)
        local inst = t.new(scope)
        if not props then return inst:Build() end

        if props.Size then inst:SetSize(props.Size) end
        if props.Position then inst:SetPosition(props.Position) end
        if props.AnchorPoint then inst:SetAnchor(props.AnchorPoint) end
        if props.BackgroundColor3 ~= nil then inst:SetBackgroundColor(props.BackgroundColor3) end
        if props.AspectRatio then inst:SetAspectRatio(props.AspectRatio) end

        if props.Name then inst:SetName(props.Name) end
        if props.LayoutOrder then inst:SetLayoutOrder(props.LayoutOrder) end
        if props.ZIndex then inst:SetZIndex(props.ZIndex) end

        local children = props[Weave.Children] or props.Children
        if children then
            inst._props.Children = children
        end

        return inst:Build()
    end
})

function Circle.new(scope: Weave.Scope)
    local self = setmetatable(Builder.new(scope), Circle)
    self._props.AspectRatio = 1
    return self
end

function Circle:SetBackgroundColor(color: any)
    self._props.BackgroundColor3 = color
    return self
end

function Circle:SetAspectRatio(ratio: number)
    self._props.AspectRatio = ratio
    return self
end

function Circle:Build()
    local scope = self._scope
    local activeTheme = Theme.getTheme()

    local children = self._props.Children or {}

    return scope:Frame {
        Name = self._props.Name or "Circle",
        Size = self._props.Size or UDim2.fromScale(1, 1),
        Position = self._props.Position,
        AnchorPoint = self._props.AnchorPoint or Vector2.new(0.5, 0.5),
        BackgroundColor3 = self._props.BackgroundColor3 or activeTheme.Colors.Surface,
        ClipsDescendants = true,
        LayoutOrder = self._props.LayoutOrder,
        ZIndex = self._props.ZIndex or 1,

        [Weave.Children] = {
            scope:Corner { CornerRadius = UDim.new(0.5, 0) },
            scope:AspectRatio { AspectRatio = self._props.AspectRatio or 1 },
            scope:Fragment(children)
        }
    }
end

return Circle
