local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Weave = require(ReplicatedStorage.Libraries.Weave)
local Builder = require(script.Parent.Parent.Builder)
local Theme = require(script.Parent.Parent.Theme)
local TweenLib = require(ReplicatedStorage.Libraries.Tween)

local Modal = setmetatable({}, {
    __index = Builder,
    __call = function(t, scope, props)
        local inst = t.new(scope)
        if not props then return inst:Build() end

        if props.Title then inst:SetTitle(props.Title) end
        if props.Message then inst:SetMessage(props.Message) end
        if props.ConfirmText then inst._props.ConfirmText = props.ConfirmText end
        if props.CancelText then inst._props.CancelText = props.CancelText end
        if props.OnConfirm then inst._props.OnConfirm = props.OnConfirm end
        if props.OnCancel then inst._props.OnCancel = props.OnCancel end
        if props.OverlayTransparency then inst._props.OverlayTransparency = props.OverlayTransparency end
        if props.Content then inst:SetContent(props.Content) end

        if props.Name then inst:SetName(props.Name) end
        if props.Size then inst:SetSize(props.Size) end
        if props.ZIndex then inst:SetZIndex(props.ZIndex) end

        return inst:Build()
    end
})
Modal.__index = Modal

function Modal.new(scope: Weave.Scope)
    local self = setmetatable(Builder.new(scope), Modal)
    self._props.OverlayTransparency = 0.5
    self._props.ConfirmText = "Confirm"
    self._props.CancelText = "Cancel"
    return self
end

function Modal:SetTitle(title: any)
    self._props.Title = title
    return self
end

function Modal:SetMessage(message: any)
    self._props.Message = message
    return self
end

function Modal:SetContent(contentBuilder: (scope: Weave.Scope) -> any)
    self._props.ContentBuilder = contentBuilder
    return self
end

function Modal:OnConfirm(callback: () -> ())
    self._props.OnConfirm = callback
    return self
end

function Modal:OnCancel(callback: () -> ())
    self._props.OnCancel = callback
    return self
end

function Modal:Build()
    local scope = self._scope
    local activeTheme = Theme.getTheme()
    local props = self._props

    local getModalScale, setModalScale = scope.Value(0.0)
    local modalTarget = { Get = function() return getModalScale() end, Set = function(_, v) setModalScale(v) end }
    local playerGui = Players.LocalPlayer and Players.LocalPlayer:WaitForChild("PlayerGui") or nil

    local gui: ScreenGui? = nil
    local canDismiss = false -- guard against the same click that opened it

    local function dismiss(callback: (() -> ())?)
        print("[Modal] dismiss() called")
        TweenLib.Tween(modalTarget, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), { Value = 0 }, function()
            print("[Modal] dismiss tween complete — destroying gui")
            if gui then
                gui:Destroy()
                gui = nil
            end
            if callback then callback() end
        end)
    end

    -- Build all children inside a flat list for the dialog
    local dialogChildren = {}

    -- Corner + Stroke + Scale
    table.insert(dialogChildren, scope:Corner { CornerRadius = activeTheme.Radii.Large })
    table.insert(dialogChildren, scope:Stroke {
        Color = activeTheme.Colors.PrimaryDark,
        Thickness = 1,
        Transparency = 0.3,
    })
    table.insert(dialogChildren, scope:UIScale {
        Scale = scope.Computed(function() return getModalScale() end)
    })
    table.insert(dialogChildren, scope:Padding {
        PaddingTop = UDim.new(0.06, 0),
        PaddingBottom = UDim.new(0.06, 0),
        PaddingLeft = UDim.new(0.08, 0),
        PaddingRight = UDim.new(0.08, 0),
    })
    table.insert(dialogChildren, scope:ListLayout {
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalFlex = Enum.UIFlexAlignment.Fill,
        Padding = UDim.new(0.04, 0),
    })

    -- Theme modifier injection for Dialog
    local dialogStylesFn = activeTheme.Components.Modal.DialogStyles()
    if dialogStylesFn then
        for _, modifier in ipairs(dialogStylesFn(scope) or {}) do
            table.insert(dialogChildren, modifier)
        end
    end

    -- Title
    if props.Title then
        table.insert(dialogChildren, scope:TextLabel {
            Name = "Title",
            Size = UDim2.fromScale(1, 0),
            BackgroundTransparency = 1,
            Text = props.Title,
            TextColor3 = activeTheme.Colors.TextPrimary,
            Font = activeTheme.Fonts.Heading,
            TextScaled = true,
            TextXAlignment = Enum.TextXAlignment.Center,
            LayoutOrder = 1,
            [Weave.Children] = {
                scope:TextSizeConstraint { MaxTextSize = 24, MinTextSize = 10 },
                scope:FlexItem { FlexMode = Enum.UIFlexMode.Custom, GrowRatio = 2 },
            }
        })
    end

    -- Message
    if props.Message then
        table.insert(dialogChildren, scope:TextLabel {
            Name = "Message",
            Size = UDim2.fromScale(1, 0),
            BackgroundTransparency = 1,
            Text = props.Message,
            TextColor3 = activeTheme.Colors.TextMuted,
            Font = activeTheme.Fonts.Body,
            TextScaled = true,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Center,
            LayoutOrder = 2,
            [Weave.Children] = {
                scope:TextSizeConstraint { MaxTextSize = 16, MinTextSize = 8 },
                scope:FlexItem { FlexMode = Enum.UIFlexMode.Custom, GrowRatio = 3 },
            }
        })
    end

    -- Custom content
    if props.ContentBuilder then
        local content = props.ContentBuilder(scope)
        if content then
            table.insert(dialogChildren, scope:Frame {
                Name = "CustomContentSlot",
                Size = UDim2.fromScale(1, 0),
                BackgroundTransparency = 1,
                LayoutOrder = 5,
                [Weave.Children] = {
                    scope:FlexItem { FlexMode = Enum.UIFlexMode.Custom, GrowRatio = 4 },
                    content
                }
            })
        end
    end

    -- Button row
    local buttonRowChildren = {
        scope:ListLayout {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0.04, 0),
            SortOrder = Enum.SortOrder.LayoutOrder,
            HorizontalFlex = Enum.UIFlexAlignment.SpaceEvenly,
        },
    }

    -- Cancel button
    if props.OnCancel or props.CancelText then
        table.insert(buttonRowChildren, scope:TextButton {
            Name = "CancelBtn",
            Size = UDim2.fromScale(0.45, 1),
            BackgroundColor3 = activeTheme.Colors.PrimaryDark,
            Text = props.CancelText or "Cancel",
            TextColor3 = activeTheme.Colors.TextLight,
            Font = activeTheme.Fonts.Body,
            TextScaled = true,
            AutoButtonColor = false,
            LayoutOrder = 1,
            [Weave.OnEvent("Activated")] = function()
                dismiss(props.OnCancel)
            end,
            [Weave.Children] = {
                scope:Corner { CornerRadius = UDim.new(0, 6) },
                scope:TextSizeConstraint { MaxTextSize = 14, MinTextSize = 8 },
            }
        })
    end

    -- Confirm button
    table.insert(buttonRowChildren, scope:TextButton {
        Name = "ConfirmBtn",
        Size = UDim2.fromScale(0.45, 1),
        BackgroundColor3 = activeTheme.Colors.Accent,
        Text = props.ConfirmText or "Confirm",
        TextColor3 = activeTheme.Colors.TextPrimary,
        Font = activeTheme.Fonts.Heading,
        TextScaled = true,
        AutoButtonColor = false,
        LayoutOrder = 2,
        [Weave.OnEvent("Activated")] = function()
            dismiss(props.OnConfirm)
        end,
        [Weave.Children] = {
            scope:Corner { CornerRadius = UDim.new(0, 6) },
            scope:TextSizeConstraint { MaxTextSize = 14, MinTextSize = 8 },
        }
    })

    table.insert(dialogChildren, scope:Frame {
        Name = "ButtonRow",
        Size = UDim2.fromScale(1, 0),
        BackgroundTransparency = 1,
        LayoutOrder = 10,
        [Weave.Children] = {
            scope:FlexItem { FlexMode = Enum.UIFlexMode.Custom, GrowRatio = 2 },
            unpack(buttonRowChildren)
        }
    })

    -- Build the ScreenGui directly (no scope.Show needed)
    -- Build overlay children (theme modifier injection)
    local overlayChildren = {}
    local overlayStylesFn = activeTheme.Components.Modal.OverlayStyles()
    if overlayStylesFn then
        for _, modifier in ipairs(overlayStylesFn(scope) or {}) do
            table.insert(overlayChildren, modifier)
        end
    end

    local overlay = scope:TextButton {
        Name = "Overlay",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = props.OverlayTransparency,
        Text = "",
        AutoButtonColor = false,
        Active = true,
        ZIndex = 1,
        [Weave.OnEvent("Activated")] = function()
            if not canDismiss then
                print("[Modal] Overlay clicked but BLOCKED — canDismiss is false (opening click guard)")
                return
            end
            print("[Modal] Overlay clicked — dismissing modal")
            dismiss(props.OnCancel)
        end,
        [Weave.Children] = overlayChildren
    }

    -- Dialog is a TextButton (not Frame) so it ABSORBS clicks and prevents
    -- them from propagating through to the overlay behind it.
    local dialog = scope:TextButton {
        Name = "Dialog",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = props.Size or UDim2.fromScale(0.3, 0.25),
        BackgroundColor3 = activeTheme.Colors.Surface,
        ClipsDescendants = true,
        ZIndex = 2,
        Text = "",
        AutoButtonColor = false,
        Active = true, -- absorbs input
        [Weave.OnEvent("Activated")] = function()
            print("[Modal] Dialog body clicked — no action (absorbed)")
        end,
        [Weave.Children] = dialogChildren
    }

    print("[Modal] Built modal: " .. (props.Name or "WeaveKit_Modal") .. " | ZIndex=" .. tostring(type(props.ZIndex) == "number" and props.ZIndex or 200))

    local finalGui = scope:ScreenGui {
        Name = props.Name or "WeaveKit_Modal",
        IgnoreGuiInset = true,
        DisplayOrder = type(props.ZIndex) == "number" and props.ZIndex or 200,
        ResetOnSpawn = false,
        Enabled = false, -- Start hidden
        [Weave.Children] = { overlay, dialog }
    }
    gui = finalGui

    if playerGui then
        finalGui.Parent = playerGui
    end

    -- Control table
    local control = {}
    control.Instance = gui

    function control:Show()
        if not gui then return end
        print("[Modal] Show() called")
        canDismiss = false
        gui.Enabled = true
        setModalScale(0)
        TweenLib.Tween(modalTarget, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Value = 1 })
        -- Allow dismissal after a short delay so the opening click doesn't also close it
        task.delay(0.3, function()
            canDismiss = true
            print("[Modal] canDismiss = true (ready to accept dismiss)")
        end)
    end

    function control:Hide(callback)
        print("[Modal] Hide() called")
        dismiss(callback)
    end

    function control:Destroy()
        if gui then
            gui:Destroy()
            gui = nil
        end
    end

    return control
end

return Modal
