local WeaveTypes = require(game:GetService("ReplicatedStorage").Libraries.Weave.Types)

-- ═══════════════════════════════════════════════════════════════════════════════
-- THEME TYPE DEFINITIONS
-- Complete type system for Dark / Light theme support
-- ═══════════════════════════════════════════════════════════════════════════════

-- ── Color Tokens ─────────────────────────────────────────────────────────────
-- Semantic color naming: describes PURPOSE, not hue.
export type ThemeColors = {
    -- Brand
    Primary: WeaveTypes.WState<Color3>,         -- Main brand color (buttons, links, accents)
    PrimaryDark: WeaveTypes.WState<Color3>,      -- Darker shade of Primary (headers, active states)
    PrimaryLight: WeaveTypes.WState<Color3>,     -- Lighter shade of Primary (hover tints)

    -- Accent / CTA
    Accent: WeaveTypes.WState<Color3>,           -- Call-to-action, highlights, badges
    AccentDark: WeaveTypes.WState<Color3>,       -- Pressed/active accent
    AccentLight: WeaveTypes.WState<Color3>,      -- Hover accent tint

    -- Semantic  
    Success: WeaveTypes.WState<Color3>,          -- Positive actions, completion
    Warning: WeaveTypes.WState<Color3>,          -- Caution states
    Error: WeaveTypes.WState<Color3>,            -- Destructive actions, errors

    -- Surfaces
    Background: WeaveTypes.WState<Color3>,       -- Page / screen background
    Surface: WeaveTypes.WState<Color3>,          -- Card / panel background (elevated)
    SurfaceAlt: WeaveTypes.WState<Color3>,       -- Alternate surface (nested panels, inputs)
    Overlay: WeaveTypes.WState<Color3>,          -- Modal overlay color

    -- Text
    TextPrimary: WeaveTypes.WState<Color3>,      -- Main body text
    TextSecondary: WeaveTypes.WState<Color3>,    -- Subtitles, descriptions, secondary info
    TextMuted: WeaveTypes.WState<Color3>,        -- Placeholders, disabled text
    TextOnPrimary: WeaveTypes.WState<Color3>,    -- Text rendered on Primary-colored surfaces
    TextOnAccent: WeaveTypes.WState<Color3>,     -- Text rendered on Accent-colored surfaces

    -- Borders / Dividers
    Border: WeaveTypes.WState<Color3>,           -- Default border color
    BorderFocus: WeaveTypes.WState<Color3>,      -- Focused input border

    -- Legacy aliases
    TextLight: WeaveTypes.WState<Color3>?,       -- -> TextOnPrimary (kept for backwards compat)
}

-- ── Typography ───────────────────────────────────────────────────────────────
export type ThemeFonts = {
    Heading: WeaveTypes.WState<Enum.Font>,    -- Titles, headers
    Body: WeaveTypes.WState<Enum.Font>,       -- Paragraphs, general text
    Mono: WeaveTypes.WState<Enum.Font>,       -- Code, numerical values
}

-- ── Spacing & Radii ──────────────────────────────────────────────────────────
export type ThemeRadii = {
    None: WeaveTypes.WState<UDim>,
    Small: WeaveTypes.WState<UDim>,      -- 4px  — subtle rounding
    Medium: WeaveTypes.WState<UDim>,     -- 8px  — cards, inputs
    Large: WeaveTypes.WState<UDim>,      -- 16px — modals, sheets
    Full: WeaveTypes.WState<UDim>,       -- 100% — pills, circles
}

-- ── Gradients ────────────────────────────────────────────────────────────────
export type ThemeGradients = {
    Brand: WeaveTypes.WState<ColorSequence>,         -- Primary-based gradient
    Surface: WeaveTypes.WState<ColorSequence>,       -- Subtle surface gradient
    Accent: WeaveTypes.WState<ColorSequence>,        -- Accent-based gradient
}

-- ── Global Styles ────────────────────────────────────────────────────────────
export type ThemeStyles = {
    UseGlobalBorders: WeaveTypes.WState<boolean>,
    GlobalBorderThickness: WeaveTypes.WState<number>,
    GlobalBorderColor: WeaveTypes.WState<Color3>,
    OverlayTransparency: WeaveTypes.WState<number>,  -- Default modal overlay alpha
}

-- ── Component-Level Style Overrides ──────────────────────────────────────────
export type ComponentTheme = {
    [string]: WeaveTypes.WState<any>
}

export type ThemeComponents = {
    Card: ComponentTheme,
    Window: ComponentTheme,
    Container: ComponentTheme,
    IconTile: ComponentTheme,
    Text: ComponentTheme,
    Modal: ComponentTheme,
}

-- ── Flat Params (used by Theme.setTheme) ─────────────────────────────────────
-- Plain values, NOT wrapped in WState. Used as input to setTheme().
export type ThemeParams = {
    Colors: { [string]: Color3 }?,
    Fonts: { [string]: Enum.Font }?,
    Radii: { [string]: UDim }?,
    Gradients: { [string]: ColorSequence }?,
    Styles: { [string]: any }?,
    Components: { [string]: { [string]: any } }?,
}

-- ── Root Theme ───────────────────────────────────────────────────────────────
export type Theme = {
    Colors: ThemeColors,
    Fonts: ThemeFonts,
    Radii: ThemeRadii,
    Gradients: ThemeGradients,
    Styles: ThemeStyles,
    Components: ThemeComponents,
}

-- ── Builder Types (unchanged from original) ──────────────────────────────────
export type BuilderProps = {
    Name: string?,
    Size: (WeaveTypes.WState<UDim2> | UDim2)?,
    Position: (WeaveTypes.WState<UDim2> | UDim2)?,
    AnchorPoint: (WeaveTypes.WState<Vector2> | Vector2)?,
    Transparency: (WeaveTypes.WState<number> | number)?,
    LayoutOrder: (WeaveTypes.WState<number> | number)?,
    ZIndex: (WeaveTypes.WState<number> | number)?,
    [any]: any,
}

export type Builder = {
    _scope: WeaveTypes.Scope,
    _props: BuilderProps,
    SetName: (self: Builder, name: string) -> Builder,
    SetSize: (self: Builder, size: WeaveTypes.WState<UDim2> | UDim2) -> Builder,
    SetPosition: (self: Builder, position: WeaveTypes.WState<UDim2> | UDim2) -> Builder,
    SetAnchor: (self: Builder, anchor: WeaveTypes.WState<Vector2> | Vector2) -> Builder,
    SetTransparency: (self: Builder, transparency: WeaveTypes.WState<number> | number) -> Builder,
    SetLayoutOrder: (self: Builder, order: WeaveTypes.WState<number> | number) -> Builder,
    SetZIndex: (self: Builder, zIndex: WeaveTypes.WState<number> | number) -> Builder,
    Build: (self: Builder) -> any,
}

return {}
