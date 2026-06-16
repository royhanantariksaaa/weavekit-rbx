local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Weave = require(ReplicatedStorage.Libraries.Weave)
local Builder = require(script.Parent.Parent.Builder)
local Theme = require(script.Parent.Parent.Theme)

local VirtualGrid = setmetatable({}, {
    __index = Builder,
    __call = function(t, scope, props)
        local inst = t.new(scope)
        if not props then return inst:Build() end
        
        if props.Data then inst._props.Data = props.Data end
        if props.RenderItem then inst._props.RenderItem = props.RenderItem end
        if props.CellSize then inst._props.CellSize = props.CellSize end
        if props.Spacing then inst._props.Spacing = props.Spacing end
        
        if props.Name then inst:SetName(props.Name) end
        if props.Size then inst:SetSize(props.Size) end
        if props.Position then inst:SetPosition(props.Position) end
        if props.AnchorPoint then inst:SetAnchor(props.AnchorPoint) end
        if props.LayoutOrder then inst:SetLayoutOrder(props.LayoutOrder) end
        if props.ZIndex then inst:SetZIndex(props.ZIndex) end

        return inst:Build()
    end
})
VirtualGrid.__index = VirtualGrid

function VirtualGrid.new(scope: Weave.Scope)
    local self = setmetatable(Builder.new(scope), VirtualGrid)
    self._props.CellSize = Vector2.new(100, 100)
    self._props.Spacing = Vector2.new(8, 8)
    return self
end

function VirtualGrid:Build()
    local scope = self._scope
    local activeTheme = Theme.getTheme()
    
    local dataState = self._props.Data
    local renderItem = self._props.RenderItem
    local cellSize = self._props.CellSize
    local spacing = self._props.Spacing
    
    local getAbsoluteSize, setAbsoluteSize = scope.Value(Vector2.new(0, 0))
    local getCanvasPosition, setCanvasPosition = scope.Value(Vector2.new(0, 0))
    local scrollRef = scope.Ref()
    
    local columns = scope.Computed(function()
        local w = getAbsoluteSize().X
        if w == 0 then return 1 end
        local cols = math.floor((w + spacing.X) / (cellSize.X + spacing.X))
        return math.max(1, cols)
    end)
    
    local totalRows = scope.Computed(function()
        local data = type(dataState) == "function" and dataState() or dataState
        local count = data and #data or 0
        local cols = columns()
        return math.ceil(count / cols)
    end)
    
    local canvasHeight = scope.Computed(function()
        local rows = totalRows()
        if rows == 0 then return 0 end
        return (rows * cellSize.Y) + ((rows - 1) * spacing.Y)
    end)
    
    local visibleItems = scope.Computed(function()
        local data = type(dataState) == "function" and dataState() or dataState
        if not data then return {} end
        
        local yPos = getCanvasPosition().Y
        local viewHeight = getAbsoluteSize().Y
        if viewHeight == 0 then return {} end
        
        local cols = columns()
        local rowHeight = cellSize.Y + spacing.Y
        
        -- Calculate visible rows (with 1 row of buffer above and below to prevent popping)
        local startRow = math.max(0, math.floor(yPos / rowHeight) - 1)
        local endRow = math.min(totalRows() - 1, math.floor((yPos + viewHeight) / rowHeight) + 1)
        
        local startIdx = startRow * cols + 1
        local endIdx = (endRow + 1) * cols
        
        local slice = {}
        for i = startIdx, math.min(endIdx, #data) do
            table.insert(slice, data[i])
        end
        return slice
    end)
    
    local topPadding = scope.Computed(function()
        local yPos = getCanvasPosition().Y
        local rowHeight = cellSize.Y + spacing.Y
        local startRow = math.max(0, math.floor(yPos / rowHeight) - 1)
        if startRow <= 0 then return UDim.new(0, 0) end
        return UDim.new(0, startRow * rowHeight)
    end)

    return scope:ScrollingFrame {
        Name = self._props.Name or "VirtualGrid",
        Size = self._props.Size or UDim2.fromScale(1, 1),
        Position = self._props.Position,
        AnchorPoint = self._props.AnchorPoint,
        BackgroundTransparency = 1,
        LayoutOrder = self._props.LayoutOrder,
        ZIndex = self._props.ZIndex,
        
        CanvasSize = scope.Computed(function()
            return UDim2.new(0, 0, 0, canvasHeight())
        end),
        AutomaticCanvasSize = Enum.AutomaticSize.None,
        ScrollBarThickness = 6,
        ScrollBarImageColor3 = activeTheme.Colors.PrimaryDark,
        
        [Weave.Ref] = scrollRef,
        [Weave.OnChange("AbsoluteSize")] = function()
            local inst = scrollRef:Get()
            if inst then setAbsoluteSize(inst.AbsoluteSize) end
        end,
        [Weave.OnChange("CanvasPosition")] = function()
            local inst = scrollRef:Get()
            if inst then setCanvasPosition(inst.CanvasPosition) end
        end,
        
        [Weave.Children] = {
            scope:UIGridLayout {
                CellSize = UDim2.fromOffset(cellSize.X, cellSize.Y),
                CellPadding = UDim2.fromOffset(spacing.X, spacing.Y),
                SortOrder = Enum.SortOrder.LayoutOrder,
            },
            scope:UIPadding {
                PaddingTop = topPadding
            },
            scope.ForValues(visibleItems, function(itemScope, item)
                return renderItem(itemScope, item)
            end)
        }
    }
end

return VirtualGrid
