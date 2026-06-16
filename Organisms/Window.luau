local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Weave = require(ReplicatedStorage.Libraries.Weave)
local Builder = require(script.Parent.Parent.Builder)
local Theme = require(script.Parent.Parent.Theme)
local TweenLib = require(ReplicatedStorage.Libraries.Tween)

local WeaveTypes = require(ReplicatedStorage.Libraries.Weave.Types)

local Window = setmetatable({}, {
    __index = Builder,
    __call = function(t, scope, props)
        local inst = t.new(scope)
        if not props then return inst:Build() end
        local children = props[Weave.Children] or props.Children

        if props.Title then inst:SetTitle(props.Title) end
        if props.WindowScale then inst:SetWindowScale(props.WindowScale) end
        if props.HeaderGradientColor then inst:SetHeaderGradient(props.HeaderGradientColor, props.HeaderGradientRotation) end
        if props.Icon then inst:SetIcon(props.Icon) end
        if props.ContentBuilder then inst:SetContent(props.ContentBuilder) end
        if props.IsDraggable ~= nil then inst:SetDraggable(props.IsDraggable) end
        if props.Size then inst._props.Size = props.Size end
        if props.AnchorPoint then inst._props.AnchorPoint = props.AnchorPoint end
        if props.Position then inst._props.Position = props.Position end
        if props.HeaderColor then inst._props.HeaderColor = props.HeaderColor end
        if props.BodyColor then inst._props.BodyColor = props.BodyColor end
        if props.HasClose then inst:AddCloseButton(props.OnClose) end
        if props.HasMinimize then inst:AddMinimizeButton(props.OnMinimize) end
        if props.Draggable ~= nil then inst:SetDraggable(props.Draggable) end
        if props.IsScrollable ~= nil then inst:SetScrollable(props.IsScrollable) end
        if props.OverlayTransparency then inst:AddOverlay(props.OverlayTransparency) end
        if props.HasCorner then inst:AddCorner(props.CornerRadius) end
        if props.HasStroke then inst:AddStroke(props.StrokeThickness, props.StrokeColor) end
        if props.ZIndex then inst._props.ZIndex = props.ZIndex end
        if props.Name then inst._props.Name = props.Name end
        if props.Visible ~= nil then inst._props.Visible = props.Visible end

        if children then
            inst._props.DirectChildren = children
        end

        local built = inst:Build()
        if props.Parent then built.Parent = props.Parent end
        return built
    end
})
Window.__index = Window

function Window.new(scope: Weave.Scope)
    local self = setmetatable(Builder.new(scope), Window)
    self._props = {
        Title = "Window",
        Icon = nil,
        Size = UDim2.fromScale(0.4, 0.6),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        HeaderColor = nil,
        HeaderGradientColor = nil,
        HeaderGradientRotation = nil,
        BodyColor = nil,
        HasClose = false,
        OnClose = nil,
        HasMinimize = false,
        OnMinimize = nil,
        IsDraggable = false,
        IsScrollable = false,
        WindowScale = 1.0,
        OverlayTransparency = 1,
        ContentBuilder = nil,
        HasCorner = false,
        CornerRadius = nil, -- Optional customized corner
        HasStroke = false,
        StrokeThickness = nil, -- Optional customized stroke
        StrokeColor = nil,
        DirectChildren = nil,
    }
    return self
end

function Window:SetTitle(title: WeaveTypes.WState<string> | string)
    self._props.Title = title
    return self
end

function Window:SetIcon(iconAssetId: WeaveTypes.WState<string> | string)
    self._props.Icon = iconAssetId
    return self
end

function Window:AddCloseButton(onClose: (() -> ())?)
    self._props.HasClose = true
    self._props.OnClose = onClose
    return self
end

function Window:AddMinimizeButton(onMinimize: (() -> ())?)
    self._props.HasMinimize = true
    self._props.OnMinimize = onMinimize
    return self
end

function Window:SetDraggable(isDraggable: boolean)
    self._props.IsDraggable = isDraggable
    return self
end

function Window:SetWindowScale(scale: number)
    self._props.WindowScale = scale
    return self
end

function Window:SetHeaderGradient(color: any, rotation: number?)
    self._props.HeaderGradientColor = color
    self._props.HeaderGradientRotation = rotation
    return self
end

function Window:SetScrollable(isScrollable: boolean)
    self._props.IsScrollable = isScrollable
    return self
end

function Window:AddOverlay(transparency: number?)
    self._props.OverlayTransparency = transparency or 0.5
    return self
end

function Window:SetContent(contentBuilder: (scope: Weave.Scope) -> any)
    self._props.ContentBuilder = contentBuilder
    return self
end

function Window:SetHeaderColor(color: WeaveTypes.WState<Color3> | Color3)
    self._props.HeaderColor = color
    return self
end

function Window:SetBodyColor(color: WeaveTypes.WState<Color3> | Color3)
    self._props.BodyColor = color
    return self
end

function Window:AddCorner(radius: UDim?)
    self._props.HasCorner = true
    self._props.CornerRadius = radius
    return self
end

function Window:AddStroke(thickness: number?, color: (WeaveTypes.WState<Color3> | Color3)?)
    self._props.HasStroke = true
    self._props.StrokeThickness = thickness
    self._props.StrokeColor = color
    return self
end

function Window:Build()
    local internalScope = Weave.Scope() -- encapsulate logic
    local activeTheme = Theme.getTheme()
    
    local isMinimized = internalScope.Value(false)
    local minimizeAnim = internalScope.Spring(
        internalScope.Computed(function(use)
            return use(isMinimized) and 0.12 or 1
        end),
        35, 1 -- Critical damping to prevent negative bouncing
    )
    
    local isVisible = internalScope.Value(true)
    local windowScale = internalScope.Value(1.0)

    -- Sync external Visible prop (a Weave Value) with internal isVisible
    local externalVisible = self._props.Visible
    if externalVisible ~= nil and type(externalVisible) == "table" and externalVisible._isWeaveState then
        -- Set initial state
        isVisible:Set(externalVisible:Get())
        if not externalVisible:Get() then
            windowScale:Set(0)
        end
        -- Watch for external changes
        internalScope._trove:Add(externalVisible._changed:Connect(function(newVal)
            if newVal then
                isVisible:Set(true)
                TweenLib.Tween(windowScale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Value = 1 })
            else
                TweenLib.Tween(windowScale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In), { Value = 0 }, function()
                    isVisible:Set(false)
                end)
            end
        end))
    end
    
    local headerColorState = self._props.HeaderColor or activeTheme.Colors.PrimaryDark
    local bodyColorState = self._props.BodyColor or activeTheme.Colors.Background
    local titleText = self._props.Title
    local titleIcon = self._props.Icon

    -- Container holds the window itself
    local containerProps = {
        Name = "WindowContainer",
        Size = internalScope.Computed(function(use)
            local s = self._props.Size
            local rawSize = type(s) == "table" and s._isWeaveState and use(s) or s
            local yMult = use(minimizeAnim)
            return UDim2.new(
                rawSize.X.Scale, rawSize.X.Offset,
                rawSize.Y.Scale * yMult, rawSize.Y.Offset * yMult
            )
        end),
        AnchorPoint = self._props.AnchorPoint,
        Position = self._props.Position,
        BackgroundColor3 = bodyColorState,
        ClipsDescendants = true,
        [Weave.Children] = {
            -- Corner
            (self._props.HasCorner) and internalScope:Corner { 
                CornerRadius = self._props.CornerRadius or activeTheme.Radii.Medium 
            } or internalScope.Fragment({}),
            
            -- Theme Window Styles Injector
            (activeTheme.Components.Window.WindowStyles() ~= nil) and internalScope.Fragment(activeTheme.Components.Window.WindowStyles()(internalScope) or {}) or internalScope.Fragment({}),

            -- Stroke fallback
            (self._props.HasStroke or activeTheme.Styles.UseGlobalBorders()) and internalScope:Stroke {
                Color = self._props.StrokeColor or activeTheme.Styles.GlobalBorderColor() or activeTheme.Colors.PrimaryDark,
                Thickness = self._props.StrokeThickness or activeTheme.Styles.GlobalBorderThickness() or 1,
                Transparency = 0.5,
            } or internalScope.Fragment({}),
            
            internalScope:UIScale {
                Scale = internalScope.Computed(function(use) return use(windowScale) end)
            },
            internalScope:ListLayout {
                FillDirection = Enum.FillDirection.Vertical,
                SortOrder = Enum.SortOrder.LayoutOrder,
                VerticalFlex = Enum.UIFlexAlignment.Fill,
            },
            
            -- Header Frame
            internalScope:Frame {
                Name = "Header",
                Size = UDim2.fromScale(1, 0),
                BackgroundColor3 = headerColorState,
                LayoutOrder = 1,
                [Weave.Children] = {
                    internalScope:FlexItem {
                        FlexMode = Enum.UIFlexMode.Custom,
                        GrowRatio = 12, -- 12% of height
                    },
                    internalScope:Padding {
                        PaddingLeft = UDim.new(0.04, 0),
                        PaddingRight = UDim.new(0.04, 0),
                        PaddingTop = UDim.new(0.15, 0),
                        PaddingBottom = UDim.new(0.15, 0),
                    },
                    internalScope:ListLayout {
                        FillDirection = Enum.FillDirection.Horizontal,
                        VerticalAlignment = Enum.VerticalAlignment.Center,
                        HorizontalAlignment = Enum.HorizontalAlignment.Left,
                        SortOrder = Enum.SortOrder.LayoutOrder,
                        Padding = UDim.new(0.02, 0),
                    },
                    
                    -- Theme Header Styles Injector
                    (activeTheme.Components.Window.HeaderStyles() ~= nil) and internalScope.Fragment(activeTheme.Components.Window.HeaderStyles()(internalScope) or {}) or internalScope.Fragment({}),

                    (self._props.HeaderGradientColor) and internalScope:UIGradient {
                        Color = self._props.HeaderGradientColor,
                        Rotation = self._props.HeaderGradientRotation or 0
                    } or internalScope.Fragment({}),
                            
                            -- Header Icon
                            (titleIcon ~= nil) and internalScope:ImageLabel {
                                Name = "Icon",
                                Size = UDim2.fromScale(1, 1),
                                BackgroundTransparency = 1,
                                Image = titleIcon,
                                ImageColor3 = activeTheme.Colors.TextLight,
                                ScaleType = Enum.ScaleType.Fit,
                                LayoutOrder = 1,
                                [Weave.Children] = {
                                    internalScope:AspectRatio { AspectRatio = 1 }
                                }
                            } or internalScope.Fragment({}),
                            
                            -- Header Title
                            internalScope:TextLabel {
                                Name = "Title",
                                Size = UDim2.fromScale(0.8, 1),
                                BackgroundTransparency = 1,
                                Text = titleText,
                                TextColor3 = activeTheme.Colors.TextLight,
                                Font = activeTheme.Fonts.Heading,
                                TextScaled = true,
                                TextXAlignment = Enum.TextXAlignment.Left,
                                LayoutOrder = 2,
                                [Weave.Children] = {
                                    internalScope:FlexItem { FlexMode = Enum.UIFlexMode.Custom, GrowRatio = 1 },
                                    internalScope:TextSizeConstraint { MaxTextSize = 32, MinTextSize = 12 }
                                }
                            },
                            
                            -- Window Controls Spacer
                            internalScope:Frame {
                                Name = "Spacer",
                                Size = UDim2.fromScale(0, 1),
                                BackgroundTransparency = 1,
                                LayoutOrder = 3,
                                [Weave.Children] = {
                                    internalScope:FlexItem { FlexMode = Enum.UIFlexMode.Custom, GrowRatio = 0.5 },
                                }
                            },
                            
                            -- Minimize Button
                            (self._props.HasMinimize) and internalScope:TextButton {
                                Name = "MinimizeButton",
                                Size = UDim2.fromScale(1, 1),
                                BackgroundTransparency = 1,
                                Text = "_",
                                TextColor3 = activeTheme.Colors.TextLight,
                                Font = activeTheme.Fonts.Heading,
                                TextScaled = true,
                                LayoutOrder = 4,
                                [Weave.OnEvent("Activated")] = function()
                                    isMinimized:Set(not isMinimized:Get())
                                    if self._props.OnMinimize then self._props.OnMinimize() end
                                end,
                                [Weave.Children] = {
                                    internalScope:AspectRatio { AspectRatio = 1 },
                                    internalScope:TextSizeConstraint { MaxTextSize = 48, MinTextSize = 8 }
                                }
                            } or internalScope.Fragment({}),
                            
                            -- Close Button
                            (self._props.HasClose) and internalScope:TextButton {
                                Name = "CloseButton",
                                Size = UDim2.fromScale(1, 1),
                                BackgroundTransparency = 1,
                                Text = "X",
                                TextColor3 = activeTheme.Colors.TextLight,
                                Font = activeTheme.Fonts.Heading,
                                TextScaled = true,
                                LayoutOrder = 5,
                                [Weave.OnEvent("Activated")] = function()
                                    isVisible:Set(false)
                                    TweenLib.Tween(windowScale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In), { Value = 0 }, function()
                                        if self._props.OnClose then self._props.OnClose() end
                                    end)
                                end,
                                [Weave.Children] = {
                                    internalScope:AspectRatio { AspectRatio = 1 },
                                    internalScope:TextSizeConstraint { MaxTextSize = 48, MinTextSize = 8 }
                                }
                            } or internalScope.Fragment({}),
                        }
            },
            
            -- Body Content Area
            -- Scrollable mode: outer Frame claims Flex share of window height,
            -- inner ScrollingFrame at (1,1) handles overflow within that bounded area.
            (self._props.IsScrollable) and internalScope:Frame {
                Name = "Body",
                Size = UDim2.fromScale(1, 0),
                ClipsDescendants = true,
                BackgroundTransparency = 1,
                LayoutOrder = 2,
                [Weave.Children] = {
                    internalScope:FlexItem {
                        FlexMode = Enum.UIFlexMode.Custom,
                        GrowRatio = 88,
                    },
                    -- ScrollingFrame fills the outer frame's known pixel height
                    internalScope:ScrollingFrame {
                        Name = "ScrollArea",
                        Size = UDim2.fromScale(1, 1),
                        BackgroundTransparency = 1,
                        AutomaticCanvasSize = Enum.AutomaticSize.Y,
                        CanvasSize = UDim2.fromScale(1, 0),
                        ScrollBarThickness = 6,
                        ScrollBarImageColor3 = activeTheme.Colors.PrimaryDark,
                        [Weave.Children] = {
                            -- ListLayout so stacked content items flow vertically
                            internalScope:ListLayout {
                                FillDirection = Enum.FillDirection.Vertical,
                                SortOrder = Enum.SortOrder.LayoutOrder,
                                Padding = UDim.new(0, 0),
                            },
                            (self._props.ContentBuilder) and self._props.ContentBuilder(internalScope) or internalScope.Fragment({}),
                            self._props.DirectChildren and internalScope.Fragment(self._props.DirectChildren) or internalScope.Fragment({})
                        }
                    }
                }
            } or internalScope:Frame {
                Name = "Body",
                Size = UDim2.fromScale(1, 0),
                BackgroundTransparency = 1,
                LayoutOrder = 2,
                [Weave.Children] = {
                    internalScope:FlexItem {
                        FlexMode = Enum.UIFlexMode.Custom,
                        GrowRatio = 88,
                    },
                    (self._props.ContentBuilder) and self._props.ContentBuilder(internalScope) or internalScope.Fragment({}),
                    self._props.DirectChildren and internalScope.Fragment(self._props.DirectChildren) or internalScope.Fragment({})
                }
            }
        }
    }

    local container = internalScope:CanvasGroup(containerProps)
    
    -- Draggable Logic setup using standard Roblox Drag (simple approach for now)
    if self._props.IsDraggable then
        -- This logic usually requires a more robust input handling wrapper, but this gives the basic structure
        local UIDragDetector = Instance.new("UIDragDetector")
        -- container here is a raw UI Instance, so we can just attach it directly
        task.defer(function()
             UIDragDetector.Parent = container
        end)
    end

    local base = internalScope:ScreenGui {
        Name = self._props.Name or "WeaveKit_Window",
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = type(self._props.ZIndex) == "number" and self._props.ZIndex or 100,
        ResetOnSpawn = false,
        Enabled = internalScope.Computed(function(use) return use(isVisible) end),
    }
    
    if self._props.OverlayTransparency < 1 then
        local overlay = internalScope:TextButton {
            Name = "Overlay",
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Color3.new(0,0,0),
            BackgroundTransparency = self._props.OverlayTransparency,
            Text = "",
            AutoButtonColor = false,
            Active = true,
        }
        container.Parent = overlay
        overlay.Parent = base
    else
        container.Parent = base
    end
    
    -- Entrance Animation
    windowScale:Set(0.8)
    if isVisible:Get() then
        TweenLib.Tween(windowScale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Value = 1 })
    else
        windowScale:Set(0)
    end

    local rootInstance = base
    -- Optionally attach the internalScope to the instance so we can destroy it if needed
    rootInstance.Destroying:Connect(function()
        internalScope:Destroy()
    end)

    return rootInstance
end

return Window
