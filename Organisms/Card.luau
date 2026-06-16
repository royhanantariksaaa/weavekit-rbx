local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Weave = require(ReplicatedStorage.Libraries.Weave)
local Builder = require(script.Parent.Parent.Builder)
local Theme = require(script.Parent.Parent.Theme)

local Card = setmetatable({}, {
    __index = Builder,
    __call = function(t, scope, props)
        local inst = t.new(scope)
        if not props then return inst:Build() end
        local children = props[Weave.Children] or props.Children

        if props.Title then inst:SetTitle(props.Title) end
        if props.BackgroundColor3 then inst._props.BackgroundColor3 = props.BackgroundColor3 end
        if props.CornerRadius then inst:AddCorner(props.CornerRadius) end
        if props.StrokeThickness or props.StrokeColor then inst:AddStroke(props.StrokeThickness, props.StrokeColor) end
        if props.GradientColor then inst:SetGradient(props.GradientColor, props.GradientRotation) end
        if props.Padding then inst._props.Padding = props.Padding end
        if props.Content then inst:SetContent(props.Content) end
        if props.IsScrollable ~= nil then inst._props.IsScrollable = props.IsScrollable end

        if props.Name then inst:SetName(props.Name) end
        if props.Size then inst:SetSize(props.Size) end
        if props.Position then inst:SetPosition(props.Position) end
        if props.AnchorPoint then inst:SetAnchor(props.AnchorPoint) end
        if props.LayoutOrder then inst:SetLayoutOrder(props.LayoutOrder) end
        if props.ZIndex then inst:SetZIndex(props.ZIndex) end

        if children then
            for _, child in ipairs(children) do
                inst:AddChild(child)
            end
        end

        return inst:Build()
    end
})
Card.__index = Card

function Card.new(scope: Weave.Scope)
    local self = setmetatable(Builder.new(scope), Card)
    self._children = {}
    self._props.HasCorner = true
    return self
end

function Card:SetTitle(title: any)
    self._props.Title = title
    return self
end

function Card:AddCorner(radius: UDim?)
    self._props.HasCorner = true
    self._props.CornerRadius = radius
    return self
end

function Card:AddStroke(thickness: number?, color: any)
    self._props.HasStroke = true
    self._props.StrokeThickness = thickness
    self._props.StrokeColor = color
    return self
end

function Card:SetGradient(color: any, rotation: number?)
    self._props.GradientColor = color
    self._props.GradientRotation = rotation
    return self
end

function Card:SetContent(contentBuilder: (scope: Weave.Scope) -> any)
    self._props.ContentBuilder = contentBuilder
    return self
end

function Card:AddChild(child: any)
    table.insert(self._children, child)
    return self
end

function Card:Build()
    local scope = self._scope
    local activeTheme = Theme.getTheme()

    local layoutChildren = {}

    -- Corner
    if self._props.HasCorner then
        table.insert(layoutChildren, scope:Corner {
            CornerRadius = self._props.CornerRadius or activeTheme.Radii.Medium
        })
    end

    -- Theme Modifier Injections (Idea A)
    local themeStylesFn = activeTheme.Components.Card.Styles()
    if themeStylesFn then
        for _, modifier in ipairs(themeStylesFn(scope) or {}) do
            table.insert(layoutChildren, modifier)
        end
    end

    -- Stroke Default fallback
    local useStroke = if self._props.HasStroke ~= nil then self._props.HasStroke else activeTheme.Styles.UseGlobalBorders()
    if useStroke then
        table.insert(layoutChildren, scope:Stroke {
            Color = self._props.StrokeColor or activeTheme.Styles.GlobalBorderColor() or activeTheme.Colors.PrimaryDark,
            Thickness = self._props.StrokeThickness or activeTheme.Styles.GlobalBorderThickness() or 1,
            Transparency = 0.5,
        })
    end

    if self._props.GradientColor then
        table.insert(layoutChildren, scope:UIGradient {
            Color = self._props.GradientColor,
            Rotation = self._props.GradientRotation or 0
        })
    end

    -- Padding
    local padding = self._props.Padding or UDim.new(0, 16)
    local p = Builder.ParsePadding(padding)
    table.insert(layoutChildren, scope:Padding {
        PaddingTop = p.Top,
        PaddingBottom = p.Bottom,
        PaddingLeft = p.Left,
        PaddingRight = p.Right,
    })

    -- Vertical layout
    table.insert(layoutChildren, scope:ListLayout {
        FillDirection = Enum.FillDirection.Vertical,
        VerticalFlex = Enum.UIFlexAlignment.Fill,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 10),
    })

    -- Optional title (fixed pixel height so it aligns across cards of different sizes)
    if self._props.Title then
        table.insert(layoutChildren, scope:TextLabel {
            Name = "CardTitle",
            Size = UDim2.new(1, 0, 0, 24),
            BackgroundTransparency = 1,
            Text = self._props.Title,
            TextColor3 = activeTheme.Colors.TextLight,
            Font = activeTheme.Fonts.Heading,
            TextScaled = false,
            TextSize = 18,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center,
            LayoutOrder = 1,
        })
    end

    -- Content (builder function or direct children)
    local contentNodes = {}
    if self._props.ContentBuilder then
        local content = self._props.ContentBuilder(scope)
        if content then
            table.insert(contentNodes, content)
        end
    end

    for i, child in ipairs(self._children) do
        if typeof(child) == "Instance" or (type(child) == "table") then
            table.insert(contentNodes, child)
        end
    end

    if #contentNodes > 0 then
        if self._props.IsScrollable then
            -- Scrollable content: FlexItem controls slot height, ScrollingFrame handles overflow
            table.insert(layoutChildren, scope:Frame {
                Name = "CardContentSlot",
                Size = UDim2.fromScale(1, 0),
                BackgroundTransparency = 1,
                ClipsDescendants = true,
                LayoutOrder = 5,
                [Weave.Children] = {
                    scope:FlexItem { FlexMode = Enum.UIFlexMode.Custom, GrowRatio = 8 },
                    scope:ScrollingFrame {
                        Name = "ScrollArea",
                        Size = UDim2.fromScale(1, 1),
                        BackgroundTransparency = 1,
                        AutomaticCanvasSize = Enum.AutomaticSize.Y,
                        CanvasSize = UDim2.fromScale(1, 0),
                        ScrollBarThickness = 4,
                        ScrollBarImageColor3 = activeTheme.Colors.PrimaryDark,
                        [Weave.Children] = {
                            scope:ListLayout {
                                FillDirection = Enum.FillDirection.Vertical,
                                SortOrder = Enum.SortOrder.LayoutOrder,
                                Padding = UDim.new(0, 10),
                            },
                            scope.Fragment(contentNodes)
                        }
                    }
                }
            })
        else
            -- Standard non-scrollable content slot
            table.insert(layoutChildren, scope:Frame {
                Name = "CardContentSlot",
                Size = UDim2.fromScale(1, 0),
                BackgroundTransparency = 1,
                LayoutOrder = 5,
                [Weave.Children] = {
                    scope:FlexItem { FlexMode = Enum.UIFlexMode.Custom, GrowRatio = 8 },
                    scope:ListLayout {
                        FillDirection = Enum.FillDirection.Vertical,
                        SortOrder = Enum.SortOrder.LayoutOrder,
                        Padding = UDim.new(0, 10),
                    },
                    scope.Fragment(contentNodes)
                }
            })
        end
    end

    return scope:Frame {
        Name = self._props.Name or "Card",
        Size = self._props.Size or UDim2.fromScale(1, 1),
        Position = self._props.Position,
        AnchorPoint = self._props.AnchorPoint or Vector2.new(0, 0),
        BackgroundColor3 = self._props.BackgroundColor3 or activeTheme.Colors.Surface,
        ClipsDescendants = true,
        LayoutOrder = self._props.LayoutOrder,
        ZIndex = self._props.ZIndex,
        [Weave.Children] = layoutChildren
    }
end

return Card
