local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Weave = require(ReplicatedStorage.Libraries.Weave)
local Builder = require(script.Parent.Parent.Builder)
local Theme = require(script.Parent.Parent.Theme)
local TweenLib = require(ReplicatedStorage.Libraries.Tween)

local PillButton = setmetatable({}, {
    __index = Builder,
    __call = function(t, scope, props)
        local inst = t.new(scope)
        if not props then return inst:Build() end

        if props.Text then inst:SetText(props.Text) end
        if props.Icon then inst:SetIcon(props.Icon) end
        if props.OnActivated then inst:OnActivated(props.OnActivated) end
        if props.OnHover then inst._props.OnHover = props.OnHover end
        if props.OnUnhover then inst._props.OnUnhover = props.OnUnhover end
        if props.Breathing then inst:SetBreathing(true) end
        if props.Transparency then inst:SetTransparency(props.Transparency) end
        if props.Visible ~= nil then inst:SetVisible(props.Visible) end
        if props.IdleScale then inst._props.IdleScale = props.IdleScale end

        if props.FlexMode then inst:SetFlex(props.FlexMode, props.GrowRatio) end
        if props.AspectRatio ~= nil then inst:SetAspectRatio(props.AspectRatio) end

        if props.Name then inst:SetName(props.Name) end
        if props.Size then inst:SetSize(props.Size) end
        if props.Position then inst:SetPosition(props.Position) end
        if props.AnchorPoint then inst:SetAnchor(props.AnchorPoint) end
        if props.LayoutOrder then inst:SetLayoutOrder(props.LayoutOrder) end
        if props.ZIndex then inst:SetZIndex(props.ZIndex) end

        local childrenArgs = props[Weave.Children] or props.Children
        if childrenArgs then
            inst._props.Children = childrenArgs
        end

        return inst:Build()
    end
})
function PillButton:SetVisible(visible: any)
    self._props.Visible = visible
    return self
end

PillButton.__index = PillButton

function PillButton.new(scope: Weave.Scope)
    local self = setmetatable(Builder.new(scope), PillButton)
    self._props.Breathing = false
    return self
end

function PillButton:SetText(text: any)
    self._props.Text = text
    return self
end

function PillButton:SetIcon(icon: any)
    self._props.Icon = icon
    return self
end

function PillButton:OnActivated(callback: () -> ())
    self._props.OnActivated = callback
    return self
end

function PillButton:SetBreathing(enabled: boolean)
    self._props.Breathing = enabled
    return self
end

function PillButton:SetFlex(mode: Enum.UIFlexMode, ratio: number?)
    self._props.FlexMode = mode
    self._props.GrowRatio = ratio
    return self
end

function PillButton:SetAspectRatio(ratio: any)
    self._props.AspectRatio = ratio
    return self
end

function PillButton:Build()
    local scope = self._scope
    local activeTheme = Theme.getTheme()

    local getHovered, setHovered = scope.Value(false)
    local getPressed, setPressed = scope.Value(false)
    local getBreathingScale, setBreathingScale = scope.Value(1.0)
    local getInteractionScale, setInteractionScale = scope.Value(1.0)
    local getEntranceScale, setEntranceScale = scope.Value(1.0)
    
    local breathingTarget = { Get = function() return getBreathingScale() end, Set = function(_, v) setBreathingScale(v) end }
    local interactionTarget = { Get = function() return getInteractionScale() end, Set = function(_, v) setInteractionScale(v) end }

    if self._props.Breathing then
        TweenLib.Tween(breathingTarget, TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Value = 1.04 })
    end

    local transparency: any = self._props.Transparency or 0
    local idleScale: any = self._props.IdleScale or 1.0
    local getAlphaState, setAlphaState = scope.Value(0)

    local iconProp = self._props.Icon
    local textProp = self._props.Text

    local hasAspectRatio = false
    local aspectRatioValue = 2.5
    if self._props.AspectRatio ~= nil then
        if self._props.AspectRatio then
            hasAspectRatio = true
            aspectRatioValue = self._props.AspectRatio
        end
    elseif not self._props.FlexMode then
        hasAspectRatio = true
    end

    local instance = scope:TextButton {
        Name = self._props.Name or "PillButton",
        AnchorPoint = self._props.AnchorPoint or Vector2.new(0.5, 0.5),
        Position = self._props.Position or UDim2.fromScale(0.5, 0.5),
        Size = self._props.Size or UDim2.fromScale(0.18, 0.08),
        Text = "",
        BackgroundTransparency = 1,
        Visible = scope.Computed(function()
            local v = self._props.Visible
            if v == nil then return true end
            return if type(v) == "function" then v() else v
        end),
        ZIndex = self._props.ZIndex or 1,
        LayoutOrder = self._props.LayoutOrder,

        [Weave.OnEvent("MouseEnter")] = function()
            print(string.format("[PillButton:%s] MouseEnter", self._props.Name or "Unnamed"))
            setHovered(true)
            TweenLib.Tween(interactionTarget, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Value = 1.08 })
            if self._props.OnHover then self._props.OnHover() end
        end,
        [Weave.OnEvent("MouseLeave")] = function()
            print(string.format("[PillButton:%s] MouseLeave", self._props.Name or "Unnamed"))
            setHovered(false)
            setPressed(false)
            TweenLib.Tween(interactionTarget, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Value = 1.0 })
            if self._props.OnUnhover then self._props.OnUnhover() end
        end,
        [Weave.OnEvent("MouseButton1Down")] = function()
            print(string.format("[PillButton:%s] MouseButton1Down", self._props.Name or "Unnamed"))
            setPressed(true)
            TweenLib.Tween(interactionTarget, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Value = 0.94 })
        end,
        [Weave.OnEvent("MouseButton1Up")] = function()
            print(string.format("[PillButton:%s] MouseButton1Up", self._props.Name or "Unnamed"))
            setPressed(false)
            TweenLib.Tween(interactionTarget, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Value = if getHovered() then 1.08 else 1.0 })
        end,
        [Weave.OnEvent("Activated")] = function()
            print(string.format("[PillButton:%s] ACTIVATED! (Firing callback)", self._props.Name or "Unnamed"))
            if self._props.OnActivated then self._props.OnActivated() end
        end,

        [Weave.Children] = {
            hasAspectRatio and scope:AspectRatio { AspectRatio = aspectRatioValue } or scope.Fragment({}),
            
            self._props.FlexMode and scope:FlexItem {
                FlexMode = self._props.FlexMode,
                GrowRatio = self._props.GrowRatio or 1
            } or scope.Fragment({}),

            scope:UIScale {
                Scale = scope.Computed(function()
                    local b = getBreathingScale()
                    local i = getInteractionScale()
                    local e = getEntranceScale()
                    local idle = if type(idleScale) == "function" then idleScale() else idleScale
                    return b * idle * i * e
                end)
            },

            self._props.Children and scope.Fragment(self._props.Children) or scope.Fragment({}),
            scope:CanvasGroup {
                Name = "Visuals",
                Size = UDim2.fromScale(1, 1),
                GroupTransparency = scope.Computed(function()
                    local t = if type(transparency) == "function" then transparency() else transparency
                    return math.max(t, getAlphaState())
                end),
                BackgroundTransparency = 1,

                [Weave.Children] = {
                    scope:Stroke {
                        Color = scope.Computed(function()
                            local c = activeTheme.Colors.TextLight
                            return if type(c) == "function" then c() else c
                        end),
                        Thickness = 2,
                        Transparency = scope.Computed(function()
                            local transValue = if type(transparency) == "function" then transparency() else transparency
                            return math.max(transValue, getAlphaState())
                        end),
                    },
                    scope:Corner { CornerRadius = UDim.new(0.5, 0) },

                    scope:Frame {
                        Name = "Background",
                        BackgroundColor3 = scope.Computed(function()
                            local c = activeTheme.Colors.Primary
                            return if type(c) == "function" then c() else c
                        end),
                        Size = UDim2.fromScale(1, 1),
                        [Weave.Children] = (function()
                            local children = {}
                            local themeStylesFn = activeTheme.Components.PillButton.Styles()
                            if themeStylesFn then
                                for _, modifier in ipairs(themeStylesFn(scope) or {}) do
                                    table.insert(children, modifier)
                                end
                            end
                            return children
                        end)()
                    },

                    scope:Frame {
                        Name = "Content",
                        Size = UDim2.fromScale(1, 1),
                        BackgroundTransparency = 1,
                        [Weave.Children] = {
                            scope:ListLayout {
                                FillDirection = Enum.FillDirection.Horizontal,
                                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                                VerticalAlignment = Enum.VerticalAlignment.Center,
                                Padding = UDim.new(0.06, 0),
                            },
                            scope:Padding { scale = { 0.1, 0.1 } },

                            -- Icon (reactive)
                            iconProp and scope.Computed(function()
                                local icon = if type(iconProp) == "function" then iconProp() else iconProp
                                if not icon or icon == "" then return nil end
                                return scope:ImageLabel {
                                    Name = "Icon",
                                    Image = icon,
                                    Size = UDim2.fromScale(0, 1),
                                    BackgroundTransparency = 1,
                                    ScaleType = Enum.ScaleType.Fit,
                                    ImageColor3 = scope.Computed(function()
                                        local c = activeTheme.Colors.TextLight
                                        return if type(c) == "function" then c() else c
                                    end),
                                    LayoutOrder = 1,
                                    [Weave.Children] = {
                                        scope:AspectRatio { AspectRatio = 1 },
                                    }
                                }
                            end) or scope.Fragment({}),

                            -- Text (reactive)
                            textProp and scope.Computed(function()
                                local text = if type(textProp) == "function" then textProp() else textProp
                                if not text or text == "" then return nil end
                                return scope:TextLabel {
                                    Name = "Label",
                                    Size = UDim2.fromScale(0, 1),
                                    AutomaticSize = Enum.AutomaticSize.X,
                                    BackgroundTransparency = 1,
                                    Text = text,
                                    TextColor3 = scope.Computed(function()
                                        local c = activeTheme.Colors.TextLight
                                        return if type(c) == "function" then c() else c
                                    end),
                                    Font = activeTheme.Fonts.Heading,
                                    TextScaled = true,
                                    LayoutOrder = 2,
                                    [Weave.Children] = {
                                        scope:TextSizeConstraint { MinTextSize = 8, MaxTextSize = 36 },
                                    }
                                }
                            end) or scope.Fragment({}),
                        }
                    },
                }
            },
        }
    }

    return instance
end

return PillButton
