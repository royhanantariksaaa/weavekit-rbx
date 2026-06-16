local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Weave = require(ReplicatedStorage.Libraries.Weave)
local Builder = require(script.Parent.Parent.Builder)
local Theme = require(script.Parent.Parent.Theme)
local TweenLib = require(ReplicatedStorage.Libraries.Tween)

local Toast = setmetatable({}, {
    __index = Builder,
    __call = function(t, scope, props)
        local inst = t.new(scope)
        if not props then return inst:Build() end

        if props.Message then inst:SetMessage(props.Message) end
        if props.Type then inst:SetType(props.Type) end
        if props.Duration then inst:SetDuration(props.Duration) end
        if props.Icon then inst:SetIcon(props.Icon) end
        if props.OnDismiss then inst:OnDismiss(props.OnDismiss) end
        if props.Position then inst:SetPosition(props.Position) end

        if props.Name then inst:SetName(props.Name) end
        if props.Size then inst:SetSize(props.Size) end
        if props.ZIndex then inst:SetZIndex(props.ZIndex) end

        return inst:Build()
    end
})

function Toast.new(scope: Weave.Scope)
    local self = setmetatable(Builder.new(scope), Toast)
    self._props.Message = "Toast Message"
    self._props.Type = "info" -- info, success, warning, error
    self._props.Duration = 3
    self._props.Icon = nil
    self._props.OnDismiss = nil
    self._props.Position = "top" -- top, bottom, topLeft, topRight, bottomLeft, bottomRight
    return self
end

function Toast:SetMessage(message: any)
    self._props.Message = message
    return self
end

function Toast:SetType(toastType: string)
    self._props.Type = toastType
    return self
end

function Toast:SetDuration(duration: number)
    self._props.Duration = duration
    return self
end

function Toast:SetIcon(icon: any)
    self._props.Icon = icon
    return self
end

function Toast:OnDismiss(callback: () -> ())
    self._props.OnDismiss = callback
    return self
end

function Toast:SetPosition(position: string)
    self._props.Position = position
    return self
end

function Toast:Build()
    local scope = self._scope
    local activeTheme = Theme.getTheme()

    local message = self._props.Message
    local toastType = self._props.Type
    local duration = self._props.Duration
    local icon = self._props.Icon
    local position = self._props.Position
    local onDismiss = self._props.OnDismiss

    -- Determine colors based on toast type
    local backgroundColor, iconColor, defaultIcon
    if toastType == "success" then
        backgroundColor = activeTheme.Colors.Success
        iconColor = activeTheme.Colors.TextPrimary
        defaultIcon = "rbxassetid://7733658505" -- Checkmark
    elseif toastType == "warning" then
        backgroundColor = activeTheme.Colors.Warning
        iconColor = activeTheme.Colors.TextPrimary
        defaultIcon = "rbxassetid://7733658506" -- Warning
    elseif toastType == "error" then
        backgroundColor = activeTheme.Colors.Error
        iconColor = activeTheme.Colors.TextPrimary
        defaultIcon = "rbxassetid://7733658507" -- X
    else -- info
        backgroundColor = activeTheme.Colors.Primary
        iconColor = activeTheme.Colors.TextLight
        defaultIcon = "rbxassetid://7733658508" -- Info
    end

    -- Calculate position
    local anchorPoint = Vector2.new(0.5, 0)
    local pos = UDim2.fromScale(0.5, 0.05)
    if position == "bottom" then
        anchorPoint = Vector2.new(0.5, 1)
        pos = UDim2.fromScale(0.5, 0.95)
    elseif position == "topLeft" then
        anchorPoint = Vector2.new(0, 0)
        pos = UDim2.fromScale(0.05, 0.05)
    elseif position == "topRight" then
        anchorPoint = Vector2.new(1, 0)
        pos = UDim2.fromScale(0.95, 0.05)
    elseif position == "bottomLeft" then
        anchorPoint = Vector2.new(0, 1)
        pos = UDim2.fromScale(0.05, 0.95)
    elseif position == "bottomRight" then
        anchorPoint = Vector2.new(1, 1)
        pos = UDim2.fromScale(0.95, 0.95)
    end

    local getToastScale, setToastScale = scope.Value(0)
    local getToastAlpha, setToastAlpha = scope.Value(1)
    
    local scaleTarget = { Get = function() return getToastScale() end, Set = function(_,v) setToastScale(v) end }
    local alphaTarget = { Get = function() return getToastAlpha() end, Set = function(_,v) setToastAlpha(v) end }

    -- Entrance animation
    task.delay(0.01, function()
        TweenLib.Tween(scaleTarget, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Value = 1 })
    end)

    -- Auto dismiss
    if duration > 0 then
        task.delay(duration, function()
            TweenLib.Tween(scaleTarget, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), { Value = 0 }, function()
                TweenLib.Tween(alphaTarget, TweenInfo.new(0.1), { Value = 0 }, function()
                    if onDismiss then onDismiss() end
                end)
            end)
        end)
    end

    return scope:Frame {
        Name = self._props.Name or "Toast",
        Size = self._props.Size or UDim2.fromScale(0.3, 0.06),
        Position = pos,
        AnchorPoint = anchorPoint,
        BackgroundColor3 = backgroundColor,
        ZIndex = self._props.ZIndex or 1000,
        [Weave.Children] = {
            scope:Corner { CornerRadius = activeTheme.Radii.Medium },
            scope:Stroke {
                Color = activeTheme.Colors.Border,
                Thickness = 1,
                Transparency = 0.5,
            },
            scope:UIScale {
                Scale = scope.Computed(function() return getToastScale() end)
            },
            scope:Padding {
                PaddingLeft = UDim.new(0.02, 0),
                PaddingRight = UDim.new(0.02, 0),
                PaddingTop = UDim.new(0.1, 0),
                PaddingBottom = UDim.new(0.1, 0),
            },
            scope:ListLayout {
                FillDirection = Enum.FillDirection.Horizontal,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                HorizontalAlignment = Enum.HorizontalAlignment.Left,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0.01, 0),
            },

            -- Icon
            scope:ImageLabel {
                Name = "Icon",
                Size = UDim2.fromScale(0, 1),
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundTransparency = 1,
                Image = icon or defaultIcon,
                ImageColor3 = iconColor,
                ScaleType = Enum.ScaleType.Fit,
                LayoutOrder = 1,
                [Weave.Children] = {
                    scope:AspectRatio { AspectRatio = 1 },
                }
            },

            -- Message
            scope:TextLabel {
                Name = "Message",
                Size = UDim2.fromScale(1, 1),
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundTransparency = 1,
                Text = message,
                TextColor3 = iconColor,
                Font = activeTheme.Colors.Body,
                TextScaled = true,
                TextXAlignment = Enum.TextXAlignment.Left,
                LayoutOrder = 2,
                [Weave.Children] = {
                    scope:TextSizeConstraint { MinTextSize = 10, MaxTextSize = 24 },
                }
            },
        }
    }
end

return Toast
