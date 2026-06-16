local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Weave = require(ReplicatedStorage.Libraries.Weave)
local Builder = require(script.Parent.Parent.Builder)
local Theme = require(script.Parent.Parent.Theme)

local Tooltip = setmetatable({}, {
    __index = Builder,
    __call = function(t, scope, props)
        local inst = t.new(scope)
        if not props then return inst:Build() end

        if props.Text then inst:SetText(props.Text) end
        if props.Target then inst:SetTarget(props.Target) end
        if props.Offset then inst._props.Offset = props.Offset end

        if props.Name then inst:SetName(props.Name) end
        if props.ZIndex then inst:SetZIndex(props.ZIndex) end

        return inst:Build()
    end
})
Tooltip.__index = Tooltip

function Tooltip.new(scope: Weave.Scope)
    local self = setmetatable(Builder.new(scope), Tooltip)
    self._props.Offset = UDim2.fromScale(0, -0.08)
    return self
end

function Tooltip:SetText(text: any)
    self._props.Text = text
    return self
end

function Tooltip:SetTarget(target: Instance)
    self._props.Target = target
    return self
end

function Tooltip:Build()
    local scope = self._scope
    local activeTheme = Theme.getTheme()

    local getVisible, setVisible = scope.Value(false)

    local tooltipScale = scope.Spring(
        scope.Computed(function()
            return getVisible() and 1 or 0
        end),
        40, 0.7
    )

    local tooltipTransparency = scope.Spring(
        scope.Computed(function()
            return getVisible() and 0 or 1
        end),
        30, 1
    )

    -- Hook into target's hover events
    if self._props.Target then
        local target = self._props.Target
        scope._trove:Add(target.MouseEnter:Connect(function()
            setVisible(true)
        end))
        scope._trove:Add(target.MouseLeave:Connect(function()
            setVisible(false)
        end))
    end

    local tooltip = scope:Frame {
        Name = self._props.Name or "Tooltip",
        AnchorPoint = Vector2.new(0.5, 1),
        Position = self._props.Offset or UDim2.fromScale(0, -0.08),
        Size = UDim2.fromScale(0.1, 0.05),
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundColor3 = activeTheme.Colors.PrimaryDark,
        BackgroundTransparency = tooltipTransparency,
        ZIndex = self._props.ZIndex or 1000,

        [Weave.Children] = {
            scope:Corner { CornerRadius = UDim.new(0, 4) },
            scope:Padding { offset = { 6, 8 } },
            scope:UIScale { Scale = tooltipScale },

            scope:TextLabel {
                Name = "TooltipText",
                Size = UDim2.fromScale(1, 1),
                AutomaticSize = Enum.AutomaticSize.XY,
                BackgroundTransparency = 1,
                Text = self._props.Text or "",
                TextColor3 = activeTheme.Colors.TextLight,
                Font = activeTheme.Fonts.Body,
                TextScaled = true,
                [Weave.Children] = {
                    scope:TextSizeConstraint { MaxTextSize = 14, MinTextSize = 8 }
                }
            }
        }
    }

    -- Control table
    local control = {}
    control.Instance = tooltip

    function control:Show()
        setVisible(true)
    end

    function control:Hide()
        setVisible(false)
    end

    return control
end

return Tooltip
