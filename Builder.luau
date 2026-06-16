
local Builder = {}
Builder.__index = Builder

-- Constructor for the base builder
function Builder.new(scope: any)
    local self = setmetatable({
        _scope = scope,
        _props = {},
    }, Builder)

    return self
end

-- Common chainable configuration methods
function Builder:SetName(name: string)
    self._props.Name = name
    return self
end

function Builder:SetSize(size: any)
    self._props.Size = size
    return self
end

function Builder:SetPosition(position: any)
    self._props.Position = position
    return self
end

function Builder:SetAnchor(anchor: any)
    self._props.AnchorPoint = anchor
    return self
end

function Builder:SetTransparency(transparency: any)
    self._props.Transparency = transparency
    return self
end

function Builder:SetLayoutOrder(order: any)
    self._props.LayoutOrder = order
    return self
end

function Builder:SetAutomaticSize(automaticSize: any)
    self._props.AutomaticSize = automaticSize
    return self
end

function Builder:SetZIndex(zIndex: any)
    self._props.ZIndex = zIndex
    return self
end

-- Virtual build method to be overridden by subclasses
function Builder:Build()
    error("WeaveKit Builder: Subclasses must implement :Build()")
end

function Builder.ParsePadding(padding: any)
    if typeof(padding) == "UDim" then
        return {
            Top = padding,
            Right = padding,
            Bottom = padding,
            Left = padding
        }
    end

    if type(padding) == "table" and (padding.Scale or padding.Offset) then
        local scale = padding.Scale or {}
        local offset = padding.Offset or {}
        
        local function getVal(arr, index, default)
            local len = #arr
            if len == 0 then return default end
            if len == 1 then return arr[1] end
            if len == 2 then
                -- {Vertical, Horizontal}
                if index == 1 or index == 3 then return arr[1] end
                if index == 2 or index == 4 then return arr[2] end
            end
            if len == 3 then
                -- {Top, Horizontal, Bottom}
                if index == 1 then return arr[1] end
                if index == 2 or index == 4 then return arr[2] end
                if index == 3 then return arr[3] end
            end
            return arr[index] or default
        end
        
        return {
            Top = UDim.new(getVal(scale, 1, 0), getVal(offset, 1, 0)),
            Right = UDim.new(getVal(scale, 2, 0), getVal(offset, 2, 0)),
            Bottom = UDim.new(getVal(scale, 3, 0), getVal(offset, 3, 0)),
            Left = UDim.new(getVal(scale, 4, 0), getVal(offset, 4, 0))
        }
    end

    return {
        Top = UDim.new(0, 0),
        Right = UDim.new(0, 0),
        Bottom = UDim.new(0, 0),
        Left = UDim.new(0, 0)
    }
end

return Builder
