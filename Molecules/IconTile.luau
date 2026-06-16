local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Weave = require(ReplicatedStorage.Libraries.Weave)
local Builder = require(script.Parent.Parent.Builder)
local Theme = require(script.Parent.Parent.Theme)
local TweenLib = require(ReplicatedStorage.Libraries.Tween)

local IconTile = setmetatable({}, {
    __index = Builder,
    __call = function(t, scope, props)
        local inst = t.new(scope)
        if not props then return inst:Build() end

        if props.Icon then inst:SetIcon(props.Icon) end
        if props.Label then inst:SetLabel(props.Label) end
        if props.OnActivated then inst:OnActivated(props.OnActivated) end
        if props.IconSize then inst._props.IconSize = props.IconSize end

        if props.Name then inst:SetName(props.Name) end
        if props.Size then inst:SetSize(props.Size) end
        if props.Position then inst:SetPosition(props.Position) end
        if props.AnchorPoint then inst:SetAnchor(props.AnchorPoint) end
        if props.LayoutOrder then inst:SetLayoutOrder(props.LayoutOrder) end
        if props.ZIndex then inst:SetZIndex(props.ZIndex) end

        return inst:Build()
    end
})
IconTile.__index = IconTile

function IconTile.new(scope: Weave.Scope)
    local self = setmetatable(Builder.new(scope), IconTile)
    self._props.Icon = ""
    self._props.IconSize = 0.52
    return self
end

function IconTile:SetIcon(icon: string)
    self._props.Icon = icon
    return self
end

function IconTile:SetLabel(label: string)
    self._props.Label = label
    return self
end

function IconTile:OnActivated(callback: () -> ())
    self._props.OnActivated = callback
    return self
end

function IconTile:Build()
    local scope = self._scope
    local activeTheme = Theme.getTheme()

    local getHovered, setHovered = scope.Value(false)
    local getPressed, setPressed = scope.Value(false)
    local getCardScale, setCardScale = scope.Value(1.0)
    local cardTarget = { Get = function() return getCardScale() end, Set = function(_,v) setCardScale(v) end }

    local function onEnter()
        setHovered(true)
        TweenLib.Tween(cardTarget, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Value = 1.06 })
    end

    local function onLeave()
        setHovered(false)
        setPressed(false)
        TweenLib.Tween(cardTarget, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Value = 1.0 })
    end

    local function onDown()
        setPressed(true)
        TweenLib.Tween(cardTarget, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Value = 0.93 })
    end

    local function onUp()
        setPressed(false)
        TweenLib.Tween(cardTarget, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Value = if getHovered() then 1.06 else 1.0
        })
    end

    return scope:TextButton {
        Name = self._props.Name or "IconTile",
        Text = "",
        AutoButtonColor = false,
        Size = self._props.Size or UDim2.fromScale(1, 1),
        Position = self._props.Position or UDim2.fromScale(0.5, 0.5),
        AnchorPoint = self._props.AnchorPoint or Vector2.new(0.5, 0.5),
        SizeConstraint = Enum.SizeConstraint.RelativeXX,
        BackgroundTransparency = 1,
        LayoutOrder = self._props.LayoutOrder,
        ZIndex = scope.Computed(function()
            return getHovered() and 100 or (self._props.ZIndex or 1)
        end),

        [Weave.OnEvent("MouseEnter")] = onEnter,
        [Weave.OnEvent("MouseLeave")] = onLeave,
        [Weave.OnEvent("MouseButton1Down")] = onDown,
        [Weave.OnEvent("MouseButton1Up")] = onUp,
        [Weave.OnEvent("Activated")] = function()
            if self._props.OnActivated then self._props.OnActivated() end
        end,

        [Weave.Children] = {
            scope:UIScale {
                Scale = scope.Computed(function() return getCardScale() end)
            },

            scope:CanvasGroup {
                Name = "Card",
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,

                [Weave.Children] = {
                    (type(activeTheme.Styles.UseGlobalBorders) == "function" and activeTheme.Styles.UseGlobalBorders() or activeTheme.Styles.UseGlobalBorders) and scope:Stroke {
                        Color = (type(activeTheme.Styles.GlobalBorderColor) == "function" and activeTheme.Styles.GlobalBorderColor() or activeTheme.Styles.GlobalBorderColor) or activeTheme.Colors.PrimaryDark,
                        Thickness = (type(activeTheme.Styles.GlobalBorderThickness) == "function" and activeTheme.Styles.GlobalBorderThickness() or activeTheme.Styles.GlobalBorderThickness) or 1,
                    } or scope.Fragment({}),

                    scope:Corner { CornerRadius = activeTheme.Radii.Medium or UDim.new(0, 12) },

                    -- Background with theme-driven styles
                    scope:Frame {
                        Name = "Background",
                        BackgroundColor3 = activeTheme.Colors.Primary,
                        Size = UDim2.fromScale(1, 1),
                        [Weave.Children] = (function()
                            local children = {}
                            -- Inject IconTile theme styles (gradient, etc.)
                            local themeStylesFn = type(activeTheme.Components.IconTile.Styles) == "function" and activeTheme.Components.IconTile.Styles() or activeTheme.Components.IconTile.Styles
                            if themeStylesFn then
                                for _, modifier in ipairs(themeStylesFn(scope) or {}) do
                                    table.insert(children, modifier)
                                end
                            end
                            return children
                        end)()
                    },

                    -- Icon
                    scope:ImageLabel {
                        Name = "Icon",
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        Position = UDim2.fromScale(0.5, 0.5),
                        Size = UDim2.fromScale(self._props.IconSize, self._props.IconSize),
                        BackgroundTransparency = 1,
                        Image = self._props.Icon,
                        ImageColor3 = activeTheme.Colors.TextLight,
                        ScaleType = Enum.ScaleType.Fit,
                    },
                },
            },
        },
    }
end

return IconTile
