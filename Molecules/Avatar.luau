local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Weave = require(ReplicatedStorage.Libraries.Weave)
local Builder = require(script.Parent.Parent.Builder)
local Theme = require(script.Parent.Parent.Theme)

local Avatar = setmetatable({}, {
    __index = Builder,
    __call = function(t, scope, props)
        local inst = t.new(scope)
        if not props then return inst:Build() end

        if props.UserId then inst:SetUserId(props.UserId) end
        if props.Size then inst:SetSize(props.Size) end
        if props.Position then inst:SetPosition(props.Position) end
        if props.AnchorPoint then inst:SetAnchor(props.AnchorPoint) end
        if props.ShowPresence ~= nil then inst:SetShowPresence(props.ShowPresence) end
        if props.PresenceColor then inst:SetPresenceColor(props.PresenceColor) end
        if props.PresencePosition then inst:SetPresencePosition(props.PresencePosition) end
        if props.PresenceSize then inst:SetPresenceSize(props.PresenceSize) end
        if props.IsCircular ~= nil then inst:SetCircular(props.IsCircular) end
        if props.BackgroundColor3 ~= nil then inst:SetBackgroundColor(props.BackgroundColor3) end
        if props.OnActivated then inst:OnActivated(props.OnActivated) end

        if props.Name then inst:SetName(props.Name) end
        if props.LayoutOrder then inst:SetLayoutOrder(props.LayoutOrder) end
        if props.ZIndex then inst:SetZIndex(props.ZIndex) end

        return inst:Build()
    end
})

function Avatar.new(scope: Weave.Scope)
    local self = setmetatable(Builder.new(scope), Avatar)
    self._props.UserId = nil
    self._props.ShowPresence = true
    self._props.PresenceColor = nil -- Uses theme accent by default
    self._props.PresencePosition = "bottomRight" -- topRight, topLeft, bottomLeft, bottomRight
    self._props.PresenceSize = UDim2.fromOffset(10, 10)
    self._props.IsCircular = true
    self._props.BackgroundColor3 = nil
    self._props.OnActivated = nil
    return self
end

function Avatar:SetUserId(userId: any)
    self._props.UserId = userId
    return self
end

function Avatar:SetShowPresence(show: boolean)
    self._props.ShowPresence = show
    return self
end

function Avatar:SetPresenceColor(color: any)
    self._props.PresenceColor = color
    return self
end

function Avatar:SetPresencePosition(position: string)
    self._props.PresencePosition = position
    return self
end

function Avatar:SetPresenceSize(size: UDim2)
    self._props.PresenceSize = size
    return self
end

function Avatar:SetCircular(isCircular: boolean)
    self._props.IsCircular = isCircular
    return self
end

function Avatar:SetBackgroundColor(color: any)
    self._props.BackgroundColor3 = color
    return self
end

function Avatar:OnActivated(callback: () -> ())
    self._props.OnActivated = callback
    return self
end

function Avatar:Build()
    local scope = self._scope
    local activeTheme = Theme.getTheme()

    local userId = self._props.UserId
    local showPresence = self._props.ShowPresence
    local presenceColor = self._props.PresenceColor or activeTheme.Colors.Success
    local isCircular = self._props.IsCircular

    -- Calculate presence indicator position
    local presenceOffset = Vector2.new(-2, -2)
    if self._props.PresencePosition == "topRight" then
        presenceOffset = Vector2.new(2, 2)
    elseif self._props.PresencePosition == "topLeft" then
        presenceOffset = Vector2.new(2, -2)
    elseif self._props.PresencePosition == "bottomLeft" then
        presenceOffset = Vector2.new(-2, 2)
    end

    local presenceSize = self._props.PresenceSize or UDim2.fromOffset(10, 10)

    -- Container for avatar and presence
    return scope:Frame {
        Name = self._props.Name or "Avatar",
        Size = self._props.Size or UDim2.fromScale(1, 1),
        Position = self._props.Position,
        AnchorPoint = self._props.AnchorPoint or Vector2.new(0.5, 0.5),
        BackgroundColor3 = self._props.BackgroundColor3 or activeTheme.Colors.Surface,
        ClipsDescendants = isCircular,
        LayoutOrder = self._props.LayoutOrder,
        ZIndex = self._props.ZIndex or 1,

        [Weave.Children] = {
            -- Corner for circular masking
            isCircular and scope:Corner { CornerRadius = UDim.new(0.5, 0) } or scope.Fragment({}),

            -- Avatar Image using Roblox avatar headshot
            scope:ImageLabel {
                Name = "AvatarImage",
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                Image = "",
                ImageColor3 = activeTheme.Colors.TextPrimary,
                ScaleType = Enum.ScaleType.Fit,
                [Weave.Children] = {
                    isCircular and scope:Corner { CornerRadius = UDim.new(0.5, 0) } or scope.Fragment({}),
                }
            },

            -- Placeholder/Default avatar when no userId
            (not userId) and scope:ImageLabel {
                Name = "Placeholder",
                Size = UDim2.fromScale(0.6, 0.6),
                BackgroundTransparency = 1,
                Image = "rbxassetid://7733658504", -- Default user icon
                ImageColor3 = activeTheme.Colors.TextMuted,
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5),
                ScaleType = Enum.ScaleType.Fit,
            } or scope.Fragment({}),

            -- Presence indicator
            showPresence and scope:Frame {
                Name = "PresenceIndicator",
                Size = presenceSize,
                BackgroundColor3 = presenceColor,
                AnchorPoint = (function()
                    local x = 0
                    local y = 0
                    if self._props.PresencePosition == "topRight" or self._props.PresencePosition == "bottomRight" then
                        x = 1
                    end
                    if self._props.PresencePosition == "topRight" or self._props.PresencePosition == "topLeft" then
                        y = 1
                    end
                    return Vector2.new(x, y)
                end)(),
                Position = UDim2.fromOffset(presenceOffset.X, presenceOffset.Y),
                [Weave.Children] = {
                    scope:Corner { CornerRadius = UDim.new(1, 0) },
                }
            } or scope.Fragment({}),
        }
    }
end

return Avatar
