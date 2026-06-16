local Types = require(script.Parent.Types)

local Weave = require(game:GetService("ReplicatedStorage").Libraries.Weave)
local createValue = Weave.Value

-- ═══════════════════════════════════════════════════════════════════════════════
-- WEAVEKIT THEME ENGINE
--
-- Reactive theme state. All tokens are Weave.Value() objects so components
-- automatically re-render when Theme.setTheme() is called with a new preset.
--
-- Unified palette built from:
--   Primary  #1F414F  ─  Deep teal
--   Accent   #F8DC81  ─  Warm gold
--   Light    #F6F6F6  ─  Near-white
-- ═══════════════════════════════════════════════════════════════════════════════

local currentTheme = {
    Colors = {},
    Fonts = {},
    Radii = {},
    Gradients = {},
    Styles = {},
    Components = {}
}

local setters: any = {
    Colors = {},
    Fonts = {},
    Radii = {},
    Gradients = {},
    Styles = {},
    Components = {}
}

local function addToken(category, key, initialValue)
    local getter, setter = createValue(initialValue)
    currentTheme[category][key] = getter
    setters[category][key] = setter
end

local function addComponentScope(componentName, props)
    currentTheme.Components[componentName] = {}
    setters.Components[componentName] = {}
    for key, initialValue in pairs(props) do
        local getter, setter = createValue(initialValue)
        currentTheme.Components[componentName][key] = getter
        setters.Components[componentName][key] = setter
    end
end

-- Brand
addToken("Colors", "Primary", Color3.fromHex("#1F414F"))
addToken("Colors", "PrimaryDark", Color3.fromHex("#152D38"))
addToken("Colors", "PrimaryLight", Color3.fromHex("#2E5A6B"))

-- Accent / CTA
addToken("Colors", "Accent", Color3.fromHex("#F8DC81"))
addToken("Colors", "AccentDark", Color3.fromHex("#D4B44E"))
addToken("Colors", "AccentLight", Color3.fromHex("#FBE9A8"))

-- Semantic
addToken("Colors", "Success", Color3.fromHex("#4ADE80"))
addToken("Colors", "Warning", Color3.fromHex("#FBBF24"))
addToken("Colors", "Error", Color3.fromHex("#F87171"))

-- Surfaces
addToken("Colors", "Background", Color3.fromHex("#0D1E26"))
addToken("Colors", "Surface", Color3.fromHex("#152D38"))
addToken("Colors", "SurfaceAlt", Color3.fromHex("#1A3745"))
addToken("Colors", "Overlay", Color3.fromHex("#000000"))

-- Text
addToken("Colors", "TextPrimary", Color3.fromHex("#F6F6F6"))
addToken("Colors", "TextSecondary", Color3.fromHex("#A0B8C4"))
addToken("Colors", "TextMuted", Color3.fromHex("#5E7B8A"))
addToken("Colors", "TextOnPrimary", Color3.fromHex("#F6F6F6"))
addToken("Colors", "TextOnAccent", Color3.fromHex("#1A1400"))

-- Borders
addToken("Colors", "Border", Color3.fromHex("#2A4F5E"))
addToken("Colors", "BorderFocus", Color3.fromHex("#F8DC81"))

-- Legacy aliases
addToken("Colors", "TextLight", Color3.fromHex("#F6F6F6"))

-- Fonts
addToken("Fonts", "Heading", Enum.Font.GothamBold)
addToken("Fonts", "Body", Enum.Font.GothamMedium)
addToken("Fonts", "Mono", Enum.Font.RobotoMono)
addToken("Fonts", "Light", Enum.Font.Gotham)

-- Radii
addToken("Radii", "None", UDim.new(0, 0))
addToken("Radii", "Small", UDim.new(0, 4))
addToken("Radii", "Medium", UDim.new(0, 8))
addToken("Radii", "Large", UDim.new(0, 16))
addToken("Radii", "Full", UDim.new(1, 0))

-- Gradients
addToken("Gradients", "Brand", ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromHex("#152D38")),
    ColorSequenceKeypoint.new(1, Color3.fromHex("#1F414F")),
}))
addToken("Gradients", "Surface", ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromHex("#0D1E26")),
    ColorSequenceKeypoint.new(1, Color3.fromHex("#152D38")),
}))
addToken("Gradients", "Accent", ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromHex("#D4B44E")),
    ColorSequenceKeypoint.new(1, Color3.fromHex("#F8DC81")),
}))
addToken("Gradients", "SubtleDark", ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromHex("#0D1E26")),
    ColorSequenceKeypoint.new(1, Color3.fromHex("#152D38")),
}))

-- UI Gradient keypoint data (for Weave.numberSequence / colorSequence helpers)
addToken("Gradients", "CardStrokeColor", {
    { time = 0, color = { 1, 1, 1 } },
    { time = 0.4671, color = { 0.5498, 0.5498, 0.5498 } },
    { time = 1, color = { 1, 1, 1 } },
})

addToken("Gradients", "CardStrokeTransparency", {
    { time = 0, value = 0, envelope = 0 },
    { time = 0.5, value = 0.5125, envelope = 0 },
    { time = 1, value = 0, envelope = 0 },
})

addToken("Gradients", "CardInnerStrokeColor", {
    { time = 0, color = { 0.5451, 0.5451, 0.5451 } },
    { time = 1, color = { 1, 1, 1 } },
})

addToken("Gradients", "CardInnerStrokeTransparency", {
    { time = 0, value = 0.9063, envelope = 0.0937 },
    { time = 1, value = 0, envelope = 0 },
})

addToken("Gradients", "ShadowTransparency", {
    { time = 0, value = 1, envelope = 0 },
    { time = 0.0648, value = 0.4563, envelope = 0 },
    { time = 0.5025, value = 0, envelope = 0 },
    { time = 0.8, value = 0.5, envelope = 0 },
    { time = 1, value = 1, envelope = 0 },
})

-- Styles
addToken("Styles", "UseGlobalBorders", false)
addToken("Styles", "GlobalBorderThickness", 1)
addToken("Styles", "GlobalBorderColor", Color3.fromHex("#2A4F5E"))
addToken("Styles", "OverlayTransparency", 0.45)

-- Components
addComponentScope("Card", { Styles = function(scope) return {} end })
addComponentScope("Window", { HeaderStyles = function(scope) return {} end, WindowStyles = function(scope) return {} end })
addComponentScope("Container", { Styles = function(scope) return {} end })
addComponentScope("IconTile", { Styles = function(scope) return {} end })
addComponentScope("Text", { Styles = function(scope) return {} end })
addComponentScope("Modal", { DialogStyles = function(scope) return {} end, OverlayStyles = function(scope) return {} end })
addComponentScope("PillButton", { Styles = function(scope) return {} end })
addComponentScope("Dropdown", { Styles = function(scope) return {} end })
addComponentScope("ActionMenu", { Styles = function(scope) return {} end })

-- ═══════════════════════════════════════════════════════════════════════════════
-- PUBLIC API
-- ═══════════════════════════════════════════════════════════════════════════════

local Theme = {}

function Theme.getTheme(): Types.Theme
    return currentTheme :: any
end

function Theme.setTheme(newTheme: Types.ThemeParams)
    local function mergeSection(sectionName, source)
        if not source then return end
        for key, value in pairs(source) do
            if setters[sectionName] and setters[sectionName][key] then
                setters[sectionName][key](value)
            end
        end
    end

    mergeSection("Colors",    newTheme.Colors)
    mergeSection("Fonts",     newTheme.Fonts)
    mergeSection("Radii",     newTheme.Radii)
    mergeSection("Gradients", newTheme.Gradients)
    mergeSection("Styles",    newTheme.Styles)

    if newTheme.Components then
        for compName, compProps in pairs(newTheme.Components) do
            if setters.Components[compName] then
                for propKey, propVal in pairs(compProps) do
                    if setters.Components[compName][propKey] then
                        setters.Components[compName][propKey](propVal)
                    end
                end
            end
        end
    end

    if newTheme.Colors then
        if newTheme.Colors.TextOnPrimary and setters.Colors.TextLight then
            setters.Colors.TextLight(newTheme.Colors.TextOnPrimary)
        end
    end
end

return Theme
