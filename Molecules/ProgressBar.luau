local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Weave = require(ReplicatedStorage.Libraries.Weave)
local Builder = require(script.Parent.Parent.Builder)
local Theme = require(script.Parent.Parent.Theme)
local TweenLib = require(ReplicatedStorage.Libraries.Tween)

local ProgressBar = setmetatable({}, {
    __index = Builder,
    __call = function(t, scope, props)
        local inst = t.new(scope)
        if not props then return inst:Build() end

        if props.Progress then inst:SetProgress(props.Progress) end
        if props.Shimmering then inst:SetShimmering(true) end
        if props.Transparency then inst._props.Transparency = props.Transparency end
        if props.GrowRatio then inst:SetFlex(props.GrowRatio) end
        if props.FillColor then inst:SetFillColor(props.FillColor) end
        if props.TrackColor then inst:SetTrackColor(props.TrackColor) end

        if props.Name then inst:SetName(props.Name) end
        if props.Size then inst:SetSize(props.Size) end
        if props.Position then inst:SetPosition(props.Position) end
        if props.AnchorPoint then inst:SetAnchor(props.AnchorPoint) end
        if props.LayoutOrder then inst:SetLayoutOrder(props.LayoutOrder) end
        if props.ZIndex then inst:SetZIndex(props.ZIndex) end

        return inst:Build()
    end
})
ProgressBar.__index = ProgressBar

function ProgressBar.new(scope: Weave.Scope)
    local self = setmetatable(Builder.new(scope), ProgressBar)
    self._props.Shimmering = false
    return self
end

function ProgressBar:SetProgress(progress: any)
    self._props.Progress = progress
    return self
end

function ProgressBar:SetShimmering(enabled: boolean)
    self._props.Shimmering = enabled
    return self
end

function ProgressBar:SetFillColor(color: any)
    self._props.FillColor = color
    return self
end

function ProgressBar:SetTrackColor(color: any)
    self._props.TrackColor = color
    return self
end

function ProgressBar:SetFlex(growRatio: number)
    self._props.GrowRatio = growRatio
    return self
end

function ProgressBar:Build()
    local scope = self._scope
    local activeTheme = Theme.getTheme()

    local progress: any = self._props.Progress or 0
    local transparency: any = self._props.Transparency or 0
    local getShinePos, setShinePos = scope.Value(-0.8)
    local shineTarget = { Get = function() return getShinePos() end, Set = function(_,v) setShinePos(v) end }

    if self._props.Shimmering then
        TweenLib.Tween(shineTarget, TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Value = 0.8 })
    end

    local children = {
        scope:Corner { CornerRadius = UDim.new(0.5, 0) },
        scope:Stroke {
            Color = Color3.fromRGB(100, 100, 120),
            Thickness = 1,
            Transparency = scope.Computed(function()
                return math.clamp((type(transparency) == "function" and transparency() or transparency) + 0.4, 0, 1)
            end),
        },

        -- Filled portion
        scope:Frame {
            Name = "BarFill",
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.fromScale(0, 0.5),
            Size = scope.Computed(function()
                return UDim2.fromScale(math.clamp(type(progress) == "function" and progress() or progress, 0, 1), 1)
            end),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            ClipsDescendants = true,
            ZIndex = 2,
            [Weave.Children] = {
                scope:Gradient {
                    Color = scope.Computed(function()
                        local accent = type(self._props.FillColor) == "function" and self._props.FillColor() or (self._props.FillColor or activeTheme.Colors.Accent())
                        local accentDark = activeTheme.Colors.AccentDark()
                        return ColorSequence.new({
                            ColorSequenceKeypoint.new(0, accent),
                            ColorSequenceKeypoint.new(0.5, accentDark),
                            ColorSequenceKeypoint.new(1, accent),
                        })
                    end),
                    Rotation = 90,
                },

                -- Shine Overlay
                scope:Frame {
                    Name = "ShineOverlay",
                    Size = UDim2.fromScale(1, 1),
                    BackgroundTransparency = 1,
                    [Weave.Children] = {
                        scope:Gradient {
                            Name = "Shine",
                            Color = ColorSequence.new(Color3.new(1, 1, 1)),
                            Transparency = NumberSequence.new({
                                NumberSequenceKeypoint.new(0, 1),
                                NumberSequenceKeypoint.new(0.5, 0.6),
                                NumberSequenceKeypoint.new(1, 1),
                            }),
                            Offset = scope.Computed(function()
                                return Vector2.new(getShinePos(), 0)
                            end),
                            Rotation = 25,
                        }
                    }
                }
            },
        },
    }

    if self._props.GrowRatio then
        table.insert(children, scope:FlexItem {
            FlexMode = Enum.UIFlexMode.Custom,
            GrowRatio = self._props.GrowRatio,
        })
    end

    return scope:CanvasGroup {
        Name = self._props.Name or "ProgressBar",
        Size = self._props.Size or UDim2.fromScale(1, 0.05),
        Position = self._props.Position,
        AnchorPoint = self._props.AnchorPoint,
        BackgroundColor3 = self._props.TrackColor or Color3.fromRGB(20, 20, 25),
        GroupTransparency = scope.Computed(function() return type(transparency) == "function" and transparency() or transparency end),
        LayoutOrder = self._props.LayoutOrder,
        ZIndex = self._props.ZIndex,
        [Weave.Children] = children,
    }
end

return ProgressBar
