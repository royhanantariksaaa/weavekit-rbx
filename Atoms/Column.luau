local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Weave = require(ReplicatedStorage.Libraries.Weave)
local Builder = require(script.Parent.Parent.Builder)

local Column = setmetatable({}, {
    __index = Builder,
    __call = function(t, scope, props)
        local inst = t.new(scope)
        if not props then return inst:Build() end
        
        if props.Ratios then inst:SetRatios(props.Ratios) end
        if props.Gap then inst:SetGap(props.Gap) end
        if props.Padding then inst:SetPadding(props.Padding) end
        if props.VerticalAlignment then inst:SetVerticalAlignment(props.VerticalAlignment) end
        if props.HorizontalAlignment then inst:SetHorizontalAlignment(props.HorizontalAlignment) end
        if props.IsScrollable ~= nil then inst._props.IsScrollable = props.IsScrollable end
        
        if props.Name then inst:SetName(props.Name) end
        if props.Size then inst:SetSize(props.Size) end
        if props.Position then inst:SetPosition(props.Position) end
        if props.AutomaticSize then inst:SetAutomaticSize(props.AutomaticSize) end
        if props.AnchorPoint then inst:SetAnchor(props.AnchorPoint) end
        if props.LayoutOrder then inst:SetLayoutOrder(props.LayoutOrder) end
        if props.ZIndex then inst:SetZIndex(props.ZIndex) end

        local children = props[Weave.Children] or props.Children
        if children then
            for _, child in ipairs(children) do
                inst:AddChild(child)
            end
        end

        return inst:Build()
    end
})
Column.__index = Column

function Column.new(scope: Weave.Scope)
    local self = setmetatable(Builder.new(scope), Column)
    self._props.Ratios = {}
    self._children = {}
    self._props.Gap = UDim.new(0, 0)
    self._props.VerticalAlignment = Enum.VerticalAlignment.Top
    self._props.HorizontalAlignment = Enum.HorizontalAlignment.Center
    return self
end

function Column:SetRatios(ratios: {number})
    self._props.Ratios = ratios
    return self
end

function Column:SetGap(gap: UDim)
    self._props.Gap = gap
    return self
end

function Column:SetPadding(padding: UDim)
    self._props.Padding = padding
    return self
end

function Column:SetVerticalAlignment(alignment: Enum.VerticalAlignment)
    self._props.VerticalAlignment = alignment
    return self
end

function Column:SetHorizontalAlignment(alignment: Enum.HorizontalAlignment)
    self._props.HorizontalAlignment = alignment
    return self
end

function Column:AddChild(child: any)
    table.insert(self._children, child)
    return self
end

function Column:Build()
    local scope = self._scope
    local hasRatios = #self._props.Ratios > 0
    
    local layoutChildren = {
        scope:ListLayout {
            FillDirection = Enum.FillDirection.Vertical,
            SortOrder = Enum.SortOrder.LayoutOrder,
            HorizontalAlignment = self._props.HorizontalAlignment,
            VerticalAlignment = self._props.VerticalAlignment,
            -- If ratios are set, we tell the list layout to stretch children vertically
            VerticalFlex = hasRatios and Enum.UIFlexAlignment.Fill or Enum.UIFlexAlignment.None,
            Padding = self._props.Gap
        }
    }
    
    if self._props.Padding then
        local p = Builder.ParsePadding(self._props.Padding)
        table.insert(layoutChildren, scope:Padding {
            PaddingTop = p.Top,
            PaddingRight = p.Right,
            PaddingBottom = p.Bottom,
            PaddingLeft = p.Left
        })
    end
    
    for i, child in ipairs(self._children) do
        if hasRatios then
            local ratio = self._props.Ratios[i] or 1
            local growRatio = math.max(1, math.floor(ratio * 100)) -- e.g. 0.3 -> 30
            
            table.insert(layoutChildren, scope:Frame {
                Name = "Segment_" .. i,
                Size = UDim2.fromScale(1, 0), -- Height is 0 handled by Flex, width is 100%
                BackgroundTransparency = 1,
                LayoutOrder = i,
                [Weave.Children] = {
                    scope:FlexItem {
                        FlexMode = Enum.UIFlexMode.Custom,
                        GrowRatio = growRatio,
                    },
                    child,
                }
            })
        else
            -- Inject child directly
            table.insert(layoutChildren, child)
        end
    end
    
    if self._props.IsScrollable then
        local activeTheme = require(script.Parent.Parent.Theme).getTheme()
        return scope:ScrollingFrame {
            Name = self._props.Name or "ScrollColumn",
            Size = self._props.Size or UDim2.fromScale(1, 1),
            Position = self._props.Position or UDim2.fromScale(0, 0),
            AnchorPoint = self._props.AnchorPoint or Vector2.new(0, 0),
            BackgroundTransparency = 1,
            AutomaticSize = self._props.AutomaticSize,
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            CanvasSize = UDim2.fromScale(1, 0),
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = activeTheme.Colors.PrimaryDark,
            LayoutOrder = self._props.LayoutOrder,
            ZIndex = self._props.ZIndex,
            [Weave.Children] = layoutChildren
        }
    else
        return scope:Frame {
            Name = self._props.Name or "Column",
            Size = self._props.Size or UDim2.fromScale(1, 1),
            Position = self._props.Position or UDim2.fromScale(0, 0),
            AnchorPoint = self._props.AnchorPoint or Vector2.new(0, 0),
            BackgroundTransparency = 1,
            AutomaticSize = self._props.AutomaticSize,
            LayoutOrder = self._props.LayoutOrder,
            ZIndex = self._props.ZIndex,
            [Weave.Children] = layoutChildren
        }
    end
end

return Column
