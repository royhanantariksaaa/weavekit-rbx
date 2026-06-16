local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Weave = require(ReplicatedStorage.Libraries.Weave)
local Builder = require(script.Parent.Parent.Builder)
local Theme = require(script.Parent.Parent.Theme)

local Toggle = setmetatable({}, {
    __index = Builder,
    __call = function(t, scope, props)
        local inst = t.new(scope)
        if not props then return inst:Build() end

        if props.Value then inst:BindValue(props.Value) end
        if props.OnChanged then inst._props.OnChanged = props.OnChanged end
        if props.ActiveColor then inst._props.ActiveColor = props.ActiveColor end

        if props.Name then inst:SetName(props.Name) end
        if props.Size then inst:SetSize(props.Size) end
        if props.Position then inst:SetPosition(props.Position) end
        if props.AnchorPoint then inst:SetAnchor(props.AnchorPoint) end
        if props.LayoutOrder then inst:SetLayoutOrder(props.LayoutOrder) end
        if props.ZIndex then inst:SetZIndex(props.ZIndex) end

        return inst:Build()
    end
})
Toggle.__index = Toggle

function Toggle.new(scope: Weave.Scope)
    local self = setmetatable(Builder.new(scope), Toggle)
    return self
end

function Toggle:BindValue(value: any)
    self._props.Value = value
    return self
end

function Toggle:Build()
    local scope = self._scope
    local activeTheme = Theme.getTheme()

    -- State: use provided or create internal
    local getOn, setOn
    if type(self._props.Value) == "function" then
        getOn = self._props.Value
        setOn = nil
    else
        getOn, setOn = scope.Value(self._props.Value or false)
    end
    
    local activeColor = self._props.ActiveColor or activeTheme.Colors.Accent

    -- Animated knob position
    local knobPosition = scope.Spring(
        scope.Computed(function()
            -- With a static AnchorPoint of 0.5:
            -- 0.25 is left-aligned center, 0.75 is right-aligned center.
            return UDim2.fromScale(getOn() and 0.75 or 0.25, 0.5)
        end),
        35, 0.8
    )

    -- Animated track color
    local trackColor = scope.Spring(
        scope.Computed(function()
            local cActive = if type(activeColor) == "function" then activeColor() else activeColor
            return getOn() and cActive or activeTheme.Colors.PrimaryDark()
        end),
        25, 1
    )

    return scope:TextButton {
        Name = self._props.Name or "Toggle",
        Size = self._props.Size or UDim2.fromScale(1, 1),
        Position = self._props.Position or UDim2.fromScale(0.5, 0.5),
        AnchorPoint = self._props.AnchorPoint or Vector2.new(0.5, 0.5),
        BackgroundColor3 = trackColor,
        Text = "",
        AutoButtonColor = false,
        LayoutOrder = self._props.LayoutOrder,
        ZIndex = self._props.ZIndex,

        [Weave.OnEvent("Activated")] = function()
            local nextState = not getOn()
            if setOn then setOn(nextState) end
            if self._props.OnChanged then self._props.OnChanged(nextState) end
        end,

        [Weave.Children] = {
            scope:AspectRatio { AspectRatio = 2 },
            scope:Corner { CornerRadius = UDim.new(1, 0) },

            -- Knob
            scope:Frame {
                Name = "Knob",
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = knobPosition,
                Size = UDim2.fromScale(0.4, 0.8),
                BackgroundColor3 = Color3.new(1, 1, 1),
                [Weave.Children] = {
                    scope:Corner { CornerRadius = UDim.new(1, 0) },
                }
            }
        }
    }
end

return Toggle
