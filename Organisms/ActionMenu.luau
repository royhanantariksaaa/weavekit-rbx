local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Weave = require(ReplicatedStorage.Libraries.Weave)
local Builder = require(script.Parent.Parent.Builder)
local Theme = require(script.Parent.Parent.Theme)

-- ═══════════════════════════════════════════════════════════════════════════════
-- ACTION MENU
--
-- A context-menu component. When the trigger area is clicked, a floating
-- options list appears via Portal at the configured Placement.
--
-- Props:
--   Options        : { { Text: string, Icon: string?, OnActivated: () -> () } }
--   Placement      : "Bottom" | "Left" | "Right" | "Top"  (default "Bottom")
--   MenuWidth      : number  (default 150)
--   TriggerContent : (scope) -> Instance?  (optional child to render in trigger)
--   HeaderTitle    : string? (optional title to display at the top)
--   HeaderIcon     : string? (optional icon/avatar to display at the top)
-- ═══════════════════════════════════════════════════════════════════════════════

local OPTION_HEIGHT = 36
local DEFAULT_MENU_WIDTH = 150
local GAP = 4 -- gap between trigger and menu

local function resolveValue(value)
	if type(value) == "function" then
		return value()
	end
	if type(value) == "table" and type(value.Get) == "function" then
		return value:Get()
	end
	return value
end

local ActionMenu = setmetatable({}, {
	__index = Builder,
	__call = function(t, scope, props)
		local inst = t.new(scope)
		if not props then return inst:Build() end

		if props.Options then inst._props.Options = props.Options end
		if props.TriggerContent then inst._props.TriggerContent = props.TriggerContent end
		if props.Placement then inst._props.Placement = props.Placement end
		if props.MenuWidth then inst._props.MenuWidth = props.MenuWidth end
		if props.HeaderTitle then inst._props.HeaderTitle = props.HeaderTitle end
		if props.HeaderIcon then inst._props.HeaderIcon = props.HeaderIcon end

		if props.Name then inst:SetName(props.Name) end
		if props.Size then inst:SetSize(props.Size) end
		if props.Position then inst:SetPosition(props.Position) end
		if props.AnchorPoint then inst:SetAnchor(props.AnchorPoint) end
		if props.LayoutOrder then inst:SetLayoutOrder(props.LayoutOrder) end
		if props.ZIndex then inst:SetZIndex(props.ZIndex) end

		return inst:Build()
	end
})
ActionMenu.__index = ActionMenu

function ActionMenu.new(scope: Weave.Scope)
	local self = setmetatable(Builder.new(scope), ActionMenu)
	self._props.Options = {}
	self._props.Placement = "Bottom"
	self._props.MenuWidth = DEFAULT_MENU_WIDTH
	return self
end

-- ── Helper: build a single option row ────────────────────────────────────────
local function BuildOptionRow(scope, option, index: number, setOpen, activeTheme)
	local getHovered, setHovered = scope.Value(false)
	local hasIcon = option.Icon ~= nil and option.Icon ~= ""

	-- Collect children WITHOUT nil holes (use table.insert)
	local rowChildren = {}

	-- Horizontal layout
	table.insert(rowChildren, scope:ListLayout {
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		Padding = UDim.new(0, 8),
	})

	-- Horizontal padding
	table.insert(rowChildren, scope:Padding {
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
	})

	-- Icon (only if present)
	if hasIcon then
		table.insert(rowChildren, scope:ImageLabel {
			Name = "Icon",
			Size = UDim2.fromScale(1, 0.5),
			BackgroundTransparency = 1,
			Image = option.Icon,
			ImageColor3 = scope.Computed(function()
				return getHovered() and activeTheme.Colors.PrimaryDark() or activeTheme.Colors.TextLight()
			end),
			LayoutOrder = 1,
			[Weave.Children] = {
				scope:AspectRatio { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height }
			}
		})
	end

	-- Text label (always present)
	table.insert(rowChildren, scope:TextLabel {
		Name = "OptionText",
		Size = UDim2.new(1, hasIcon and -28 or 0, 1, 0),
		BackgroundTransparency = 1,
		Text = option.Text or "Option",
		TextColor3 = scope.Computed(function()
			return getHovered() and activeTheme.Colors.PrimaryDark() or activeTheme.Colors.TextLight()
		end),
		Font = scope.Computed(function() return activeTheme.Fonts.Heading() end),
		TextSize = 14,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		LayoutOrder = 2,
	})

	return scope:TextButton {
		Name = "Option_" .. index,
		Size = UDim2.new(1, 0, 0, OPTION_HEIGHT),
		BackgroundColor3 = activeTheme.Colors.Accent,
		BackgroundTransparency = scope.Computed(function()
			return getHovered() and 0 or 1
		end),
		Text = "",
		AutoButtonColor = false,
		LayoutOrder = index,

		[Weave.OnEvent("Activated")] = function()
			setOpen(false)
			if option.OnActivated then option.OnActivated() end
		end,
		[Weave.OnEvent("MouseEnter")] = function() setHovered(true) end,
		[Weave.OnEvent("MouseLeave")] = function() setHovered(false) end,

		[Weave.Children] = rowChildren,
	}
end

-- ── Helper: compute portal position ──────────────────────────────────────────
local function ComputePosition(scope, getAbsolutePos, getAbsoluteSize, listHeight, placement, menuWidth)
	return scope.Computed(function()
		local pos = getAbsolutePos()
		local size = getAbsoluteSize()
		local lh = resolveValue(listHeight) or 0

		if placement == "Left" then
			return UDim2.fromOffset(
				pos.X - menuWidth - GAP,
				pos.Y + (size.Y - lh) / 2
			)
		elseif placement == "Right" then
			return UDim2.fromOffset(
				pos.X + size.X + GAP,
				pos.Y + (size.Y - lh) / 2
			)
		elseif placement == "Top" then
			return UDim2.fromOffset(pos.X, pos.Y - lh - GAP)
		else -- "Bottom"
			return UDim2.fromOffset(pos.X, pos.Y + size.Y + GAP)
		end
	end)
end

local function ComputeSize(scope, getAbsoluteSize, listHeight, placement, menuWidth)
	return scope.Computed(function()
		local lh = resolveValue(listHeight) or 0
		if placement == "Left" or placement == "Right" then
			return UDim2.new(0, menuWidth, 0, lh)
		else
			local size = getAbsoluteSize()
			return UDim2.new(0, math.max(size.X, menuWidth), 0, lh)
		end
	end)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- BUILD
-- ═══════════════════════════════════════════════════════════════════════════════
function ActionMenu:Build()
	local scope = self._scope
	local activeTheme = Theme.getTheme()
	local placement = self._props.Placement
	local menuWidth = self._props.MenuWidth
	local getOptions
	if type(self._props.Options) == "function" then
	    getOptions = self._props.Options
	elseif type(self._props.Options) == "table" and type(self._props.Options.Get) == "function" then
		getOptions = function()
			return self._props.Options:Get()
		end
	else
	    getOptions, _ = scope.Value(self._props.Options or {})
	end
	
	local numOptionsState = scope.Computed(function() 
	    local opts = getOptions()
	    return opts and #opts or 0
	end)

	-- ── State ────────────────────────────────────────────────────────────
	local getOpen, setOpen = scope.Value(false)
	local hasHeader = self._props.HeaderTitle or self._props.HeaderIcon
	local headerHeight = hasHeader and 48 or 0
	local totalHeight = scope.Computed(function()
		return (numOptionsState() * OPTION_HEIGHT) + 8 + headerHeight
	end)
	
	local listHeight = scope.Spring(
		scope.Computed(function()
			return getOpen() and math.min(totalHeight(), 250) or 0
		end),
		35, 1
	)

	local getAbsolutePos, setAbsolutePos = scope.Value(Vector2.new())
	local getAbsoluteSize, setAbsoluteSize = scope.Value(Vector2.new())
	local triggerRef = scope.Ref()

	-- Track trigger position while menu is open
	scope._trove:Add(RunService.RenderStepped:Connect(function()
		if getOpen() then
			local inst = triggerRef:Get()
			if inst then
				local p = inst.AbsolutePosition
				if getAbsolutePos() ~= p then
					setAbsolutePos(p)
					setAbsoluteSize(inst.AbsoluteSize)
				end
			end
		end
	end))

	-- ── Portal ScreenGui ─────────────────────────────────────────────────
	local getPortalRoot, setPortalRoot = scope.Value(nil)
	task.spawn(function()
		local player = Players.LocalPlayer
		if not player then return end
		local playerGui = player:WaitForChild("PlayerGui")
		local gui = playerGui:FindFirstChild("WeavePortalGui")
		if not gui then
			gui = Instance.new("ScreenGui")
			gui.Name = "WeavePortalGui"
			gui.ResetOnSpawn = false
			gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
			gui.DisplayOrder = 10001
			gui.Parent = playerGui
		end
		setPortalRoot(gui)
	end)

	-- ── Option buttons & Header ──────────────────────────────────────────
	local optionChildren = {}

	table.insert(optionChildren, scope:ListLayout {
		FillDirection = Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	if hasHeader then
		local hasIcon = self._props.HeaderIcon ~= nil
		local headerContents = {}
		
		table.insert(headerContents, scope:ListLayout {
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			HorizontalAlignment = Enum.HorizontalAlignment.Left,
			Padding = UDim.new(0, 8),
		})
		
		table.insert(headerContents, scope:Padding {
			PaddingLeft = UDim.new(0, 12),
			PaddingRight = UDim.new(0, 12),
		})
		
		if hasIcon then
			table.insert(headerContents, scope:ImageLabel {
				Name = "HeaderIcon",
				Size = UDim2.fromScale(1, 0.6),
				BackgroundTransparency = 1,
				Image = self._props.HeaderIcon,
				LayoutOrder = 1,
				[Weave.Children] = {
					scope:AspectRatio { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height },
					scope:Corner { CornerRadius = UDim.new(1, 0) } -- Circular avatar
				}
			})
		end
		
		table.insert(headerContents, scope:TextLabel {
			Name = "HeaderTitle",
			Size = UDim2.new(1, hasIcon and -32 or 0, 1, 0),
			BackgroundTransparency = 1,
			Text = self._props.HeaderTitle or "",
			TextColor3 = activeTheme.Colors.TextLight,
			Font = activeTheme.Fonts.Heading,
			TextSize = 14,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
			LayoutOrder = 2,
		})
		
		-- Add the Header row
		table.insert(optionChildren, scope:Frame {
			Name = "HeaderRow",
			Size = UDim2.new(1, 0, 0, headerHeight - 1), -- Leave 1px for divider
			BackgroundTransparency = 1,
			LayoutOrder = 0,
			[Weave.Children] = headerContents
		})
		
		-- Add a divider
		table.insert(optionChildren, scope:Frame {
			Name = "Divider",
			Size = UDim2.new(1, 0, 0, 1),
			BackgroundColor3 = activeTheme.Colors.TextLight,
			BackgroundTransparency = 0.8,
			LayoutOrder = 1,
		})
	end


	table.insert(optionChildren, scope.ForValues(getOptions, function(childScope, option, i)
		local rowInst = BuildOptionRow(childScope, option, i, setOpen, activeTheme)
		rowInst.LayoutOrder = 1 + i
		return rowInst
	end))

	-- ── Options list modifiers ───────────────────────────────────────────
	local listChildren = {}

	-- Theme injection
	local themeStylesFn = activeTheme.Components.ActionMenu.Styles()
	if themeStylesFn then
		for _, modifier in ipairs(themeStylesFn(scope) or {}) do
			table.insert(listChildren, modifier)
		end
	end

	table.insert(listChildren, scope:Corner { CornerRadius = activeTheme.Radii.Medium })
	table.insert(listChildren, scope:Padding {
		PaddingTop = UDim.new(0, 4),
		PaddingBottom = UDim.new(0, 4),
	})

	-- Append option buttons
	for _, child in ipairs(optionChildren) do
		table.insert(listChildren, child)
	end

	-- ── Trigger hover animation ──────────────────────────────────────────
	local getTriggerHovered, setTriggerHovered = scope.Value(false)
	local triggerScale = scope.Spring(
		scope.Computed(function() return getTriggerHovered() and 1.02 or 1 end),
		40, 0.8
	)

	-- ═════════════════════════════════════════════════════════════════════
	-- RENDER
	-- ═════════════════════════════════════════════════════════════════════
	return scope:Frame {
		Name = self._props.Name or "ActionMenu",
		Size = self._props.Size or UDim2.fromScale(1, 1),
		Position = self._props.Position,
		AnchorPoint = self._props.AnchorPoint,
		BackgroundTransparency = 1,
		LayoutOrder = self._props.LayoutOrder,
		ZIndex = self._props.ZIndex,
		ClipsDescendants = false,

		[Weave.Children] = {
			scope:UIScale { Scale = triggerScale },

			-- Trigger (invisible clickable overlay)
			scope:TextButton {
				Name = "Trigger",
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Text = "",
				AutoButtonColor = false,

				[Weave.Ref] = triggerRef,
				[Weave.OnEvent("MouseEnter")] = function() setTriggerHovered(true) end,
				[Weave.OnEvent("MouseLeave")] = function() setTriggerHovered(false) end,
				[Weave.OnChange("AbsolutePosition")] = function()
					local inst = triggerRef:Get()
					if inst then setAbsolutePos(inst.AbsolutePosition) end
				end,
				[Weave.OnChange("AbsoluteSize")] = function()
					local inst = triggerRef:Get()
					if inst then setAbsoluteSize(inst.AbsoluteSize) end
				end,
				[Weave.OnEvent("Activated")] = function()
					setOpen(not getOpen())
				end,

				[Weave.Children] = (self._props.TriggerContent)
					and { self._props.TriggerContent(scope) }
					or {}
			},

			-- Floating options list (Portal)
			scope.Portal({
				Target = getPortalRoot,
				[Weave.Children] = {
					scope:ScrollingFrame {
						Name = "OptionsList",
						Position = ComputePosition(scope, getAbsolutePos, getAbsoluteSize, listHeight, placement, menuWidth),
						Size = ComputeSize(scope, getAbsoluteSize, listHeight, placement, menuWidth),
						BackgroundColor3 = activeTheme.Colors.Primary,
						BackgroundTransparency = 0,
						ScrollBarThickness = 3,
						CanvasSize = scope.Computed(function()
							return UDim2.new(0, 0, 0, totalHeight())
						end),
						ClipsDescendants = true,
					Visible = scope.Computed(function() 
						    local lh = resolveValue(listHeight) or 0
						    return lh > 0 
						end),
						ZIndex = 110,
						[Weave.Children] = listChildren,
					}
				}
			})
		}
	}
end

return ActionMenu
