---
name: SmashDeck Kinetic Athletic
colors:
  surface: '#0a122a'
  surface-dim: '#0a122a'
  surface-bright: '#313852'
  surface-container-lowest: '#050d25'
  surface-container-low: '#131a33'
  surface-container: '#171e37'
  surface-container-high: '#212942'
  surface-container-highest: '#2c344d'
  on-surface: '#dbe1ff'
  on-surface-variant: '#c4c9ac'
  inverse-surface: '#dbe1ff'
  inverse-on-surface: '#282f49'
  outline: '#8e9379'
  outline-variant: '#444933'
  surface-tint: '#abd600'
  primary: '#ffffff'
  on-primary: '#283500'
  primary-container: '#c3f400'
  on-primary-container: '#556d00'
  inverse-primary: '#506600'
  secondary: '#4edea3'
  on-secondary: '#003824'
  secondary-container: '#00a572'
  on-secondary-container: '#00311f'
  tertiary: '#ffffff'
  on-tertiary: '#002e69'
  tertiary-container: '#d8e2ff'
  on-tertiary-container: '#0060cd'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#c3f400'
  primary-fixed-dim: '#abd600'
  on-primary-fixed: '#161e00'
  on-primary-fixed-variant: '#3c4d00'
  secondary-fixed: '#6ffbbe'
  secondary-fixed-dim: '#4edea3'
  on-secondary-fixed: '#002113'
  on-secondary-fixed-variant: '#005236'
  tertiary-fixed: '#d8e2ff'
  tertiary-fixed-dim: '#adc6ff'
  on-tertiary-fixed: '#001a41'
  on-tertiary-fixed-variant: '#004494'
  background: '#0a122a'
  on-background: '#dbe1ff'
  surface-variant: '#2c344d'
typography:
  display-ovr:
    fontFamily: Chivo
    fontSize: 56px
    fontWeight: '900'
    lineHeight: 56px
    letterSpacing: -0.04em
  headline-xl:
    fontFamily: Chivo
    fontSize: 36px
    fontWeight: '800'
    lineHeight: 40px
    letterSpacing: -0.03em
  headline-xl-mobile:
    fontFamily: Chivo
    fontSize: 28px
    fontWeight: '800'
    lineHeight: 32px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Chivo
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 28px
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Chivo
    fontSize: 20px
    fontWeight: '700'
    lineHeight: 24px
  body-lg:
    fontFamily: Space Grotesk
    fontSize: 16px
    fontWeight: '500'
    lineHeight: 24px
  body-md:
    fontFamily: Space Grotesk
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  body-sm:
    fontFamily: Space Grotesk
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
  stat-badge:
    fontFamily: JetBrains Mono
    fontSize: 14px
    fontWeight: '700'
    lineHeight: 14px
    letterSpacing: 0.02em
  label-caps:
    fontFamily: JetBrains Mono
    fontSize: 10px
    fontWeight: '600'
    lineHeight: 12px
    letterSpacing: 0.08em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  space-2xs: 0.125rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 0.75rem
  space-base: 1rem
  space-lg: 1.25rem
  space-xl: 1.5rem
  space-2xl: 2rem
  space-3xl: 3rem
  gutter-mobile: 1rem
  margin-mobile: 1rem
  gutter-tablet: 1.5rem
  margin-tablet: 2rem
---

## Brand & Style

This design system channels the lightning-quick tempo, tactical geometry, and precision of elite collegiate badminton. Driven by high-energy contrast and an authoritative dark mode reminiscent of synthetic championship courts under stadium lights, the aesthetic fuses FIFA-style player statistics with tournament ladder discipline.

The visual style is **High-Contrast Athletic Minimal with Cyber-Court Nuances**:
- **Tension & Velocity**: Monospaced mathematical stats paired with razor-sharp display headlines create instant competitive urgency.
- **Stadium Immersion**: Midnight court depths punctuated by electric shuttlecock neon accents, mirroring lines painted across acrylic floorboards.
- **Gamified Excellence**: OVR (Overall Rating) badges, match momentum graphs, and tactile tiered ladder ranks evoke high-stakes tournament tension and player pride.

## Colors

The palette establishes an aggressive sports-tech dark environment dominated by synthetic court slates and electric neon illumination.

### Core Swatches
- **Primary (`#CCFF00`)**: Electric Volt / Shuttlecock Neon. Reserved for game-critical calls to action, active leaderboard positions, 90+ OVR thresholds, and court match points.
- **Secondary (`#10B981`)**: Match Court Emerald. Signifies positive form, won sets, streak progression, and active court status.
- **Tertiary (`#3A86FF`)**: Precision Blue. Used for analytical metrics, smash speed (km/h) trackers, and singles division tags.
- **Neutral Deep (`#0B132B`)**: Deep Stadium Navy. The primary canvas ground, representing the dark perimeter of an indoor championship arena.
- **Neutral Surface (`#1C2541`)**: Court Mat Slate. The default container and card background.
- **Neutral Elevated (`#233054`)**: Active border framing and interactive card hover states.

### Ladder & Tier Tokens
- **Master / Elite Tier**: `#CCFF00` (Volt Neon)
- **Gold Tier**: `#F59E0B` (Championship Amber)
- **Silver Tier**: `#94A3B8` (Cool Platinum Chrome)
- **Bronze Tier**: `#CD7F32` (Metallic Rust Bronze)

### Text Tiers
- **Text Emphasized**: `#FFFFFF` (Crisp Court Line White)
- **Text Standard**: `#E2E8F0` (Off-white high-contrast body)
- **Text Subdued**: `#64748B` (Cool Slate Gray for secondary metrics and court metadata)

## Typography

The typographic hierarchy blends velocity with athletic telemetry:

- **Display & Headlines (`Chivo`)**: Heavyweight, italic-capable, high-velocity geometric grotesque engineered for competitive scoreboards, dynamic match headers, and massive player card OVR ratings.
- **Body (`Space Grotesk`)**: Technical, rhythmic, and readable under rapid scrolling. Handles match feeds, player biographies, and head-to-head records.
- **Telemetry & Labels (`JetBrains Mono`)**: Strict tabular figures for precise stat tables (smash velocity, win percentage, set differentials, court numbers, and ladder rank tracking).

## Layout & Spacing

The mobile layout operates on a dynamic 4-column mobile grid reflowing to 8 columns on tablet. The foundational layout unit is based on an **8px rhythm** (with 4px and 2px micro-steps for badges and court graphic insets).

### Spatial Guidelines
- **Screen Margins**: Fixed `16px` on mobile screens to maximize surface area for player cards and tournament tree brackets.
- **Card Padding**: Compact `12px` for nested leaderboard rows; generous `16px` for expandable FIFA-style player cards.
- **Ladder Grids**: Vertical stack with tight `8px` gutters between consecutive rank positions to maintain high visual continuity and rapid scanning.

## Elevation & Depth

This system avoids soft, blurred traditional drop shadows, favoring **tactical court layering** and **glow ambient edge refraction**:

1. **Court Surface (Ground)**: Pure `#0B132B` background.
2. **Floor Mats (Level 1 Surfaces)**: Flat `#1C2541` with a `1px` subtle rim stroke (`#2A365D`) mimicking taped court bounds.
3. **Active/In-Play Cards (Level 2 Surfaces)**: `#233054` overlaid with an inner border of `rgba(204, 255, 0, 0.2)`.
4. **Neon Bloom**: Interactive highlights and #1 rank cards use an electric drop glow: `0px 0px 16px rgba(204, 255, 0, 0.25)`.
5. **Court Markings**: Vector white line overlays (`rgba(255, 255, 255, 0.08)`) run diagonally across elevated hero cards, simulating badminton court geometry.

## Shapes

The design uses a balanced `roundedness: 2` (base `8px`, `lg` at `16px`, `xl` at `24px`). This structural contour mimics composite carbon fiber badminton racket frames and edge protectors.

- **Badges & OVR Flags**: Skewed or chamfered `rounded-sm` (`4px`) pill tags to project momentum and velocity.
- **Cards & Match Tiles**: `rounded-lg` (`16px`) delivering a sleek handheld tactile unit.
- **Floating Action Match Buttons**: Fully radiused pills (`9999px`) for touch ergonomics during courtside scoring.

## Components

### 1. FIFA-Style OVR Player Cards
- **Architecture**: Vertical card (`rounded-lg`, border `1px solid rgba(255,255,255,0.12)`). Background features angled court boundary vectors.
- **Header**: Top-left contains large `display-ovr` value in `Chivo 900` tinted Volt (`#CCFF00`), with badminton position code (`MS`, `WS`, `MD`, `XD`) in `JetBrains Mono`.
- **Photo**: Right-aligned masked player portrait with high-contrast stadium rim lighting.
- **Stat Matrix**: 6-grid core badminton stats (`PAC` Pace, `SMH` Smash, `DEF` Defense, `NET` Net Play, `STM` Stamina, `TAC` Tactics) formatted in `label-caps` over bold values.

### 2. Buttons
- **Primary Velocity Button**: High-vis `#CCFF00` fill with solid `#0B132B` text in `Chivo 800`, text-transform uppercase, tracking wide. Active touch scales to `0.98`.
- **Ghost Line Button**: Transparent fill, `1.5px` border in `#CCFF00` or `#3A86FF`, text in crisp white.
- **Match Live Action**: `#10B981` pill with a pulsing beacon dot indicating an on-court match.

### 3. Ladder Ranking Chips & Rows
- **Rank Tier Badge**: Shield-shaped container with rank number (`#1` to `#99`). Gold tier utilizes `#F59E0B` metallic treatment; Silver uses `#94A3B8`; Bronze uses `#CD7F32`.
- **Movement Indicators**: Compact triangular delta indicators (`▲ 2`, `▼ 1`, `—`) rendered in `stat-badge` sizing using `#10B981` for gains and `#EF4444` for drops.

### 4. Court Visualizer & Match Trackers
- **Live Scoreboard Strip**: Split card showing two opposing doubles teams, with serving side indicated by a sharp volt shuttlecock silhouette icon.
- **Set Counters**: Small segmented square pills illuminated in `#CCFF00` for secured sets and muted slate for upcoming sets.

### 5. Input Fields & Form Controls
- **Score Input Toggles**: Monospaced oversized touch pads with quick `+1` / `-1` steppers for rapid real-time court scoring by referees or players.
- **Search & Filter**: Dark slate pill input (`#1C2541`) with subtle white border, clear placeholder text, and neon focus ring (`0 0 0 2px #CCFF00`).