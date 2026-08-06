---
name: Liquid Glass Tactical
colors:
  surface: '#111318'
  surface-dim: '#111318'
  surface-bright: '#37393e'
  surface-container-lowest: '#0c0e12'
  surface-container-low: '#1a1c20'
  surface-container: '#1e2024'
  surface-container-high: '#282a2e'
  surface-container-highest: '#333539'
  on-surface: '#e2e2e8'
  on-surface-variant: '#bac9cc'
  inverse-surface: '#e2e2e8'
  inverse-on-surface: '#2f3035'
  outline: '#849396'
  outline-variant: '#3b494c'
  surface-tint: '#00daf3'
  primary: '#c3f5ff'
  on-primary: '#00363d'
  primary-container: '#00e5ff'
  on-primary-container: '#00626e'
  inverse-primary: '#006875'
  secondary: '#c6c6c7'
  on-secondary: '#2f3131'
  secondary-container: '#454747'
  on-secondary-container: '#b4b5b5'
  tertiary: '#ffeac0'
  on-tertiary: '#3e2e00'
  tertiary-container: '#fec931'
  on-tertiary-container: '#6f5500'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#9cf0ff'
  primary-fixed-dim: '#00daf3'
  on-primary-fixed: '#001f24'
  on-primary-fixed-variant: '#004f58'
  secondary-fixed: '#e2e2e2'
  secondary-fixed-dim: '#c6c6c7'
  on-secondary-fixed: '#1a1c1c'
  on-secondary-fixed-variant: '#454747'
  tertiary-fixed: '#ffdf96'
  tertiary-fixed-dim: '#f3bf26'
  on-tertiary-fixed: '#251a00'
  on-tertiary-fixed-variant: '#594400'
  background: '#111318'
  on-background: '#e2e2e8'
  surface-variant: '#333539'
typography:
  display-lg:
    fontFamily: Outfit
    fontSize: 48px
    fontWeight: '700'
    lineHeight: 56px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Outfit
    fontSize: 28px
    fontWeight: '600'
    lineHeight: 36px
  headline-sm:
    fontFamily: Outfit
    fontSize: 20px
    fontWeight: '500'
    lineHeight: 28px
  body-lg:
    fontFamily: Outfit
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-sm:
    fontFamily: Outfit
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  data-lg:
    fontFamily: JetBrains Mono
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
  data-md:
    fontFamily: JetBrains Mono
    fontSize: 18px
    fontWeight: '500'
    lineHeight: 24px
  label-caps:
    fontFamily: JetBrains Mono
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.1em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  container-margin: 24px
  stack-gap-lg: 32px
  stack-gap-md: 20px
  stack-gap-sm: 12px
  glass-padding: 24px
---

## Brand & Style

The design system is a high-performance, futuristic interface that blends the clarity of **Glassmorphism** with a **Tactile / Tactical** edge. It is designed for elite users who require precision, data density, and a sense of "operational" readiness.

The aesthetic evokes the feeling of a glass heads-up display (HUD) projected onto a deep void. It relies on extreme contrasts between OLED blacks and neon light-sources, using refraction and depth to organize complex physiological data. The emotional response is one of total control, peak focus, and advanced technological sophistication.

## Colors

The palette is strictly functional. The foundation is a deep **OLED Black** (#000000 to #0A0C10) to maximize contrast and minimize battery drain on modern displays. 

- **Neon Cyan (#00E5FF):** Used exclusively for primary actions, active states, and localized "light leaks" that indicate focus. 
- **Glass Surfaces:** Semi-transparent layers (4-6% white) provide the structural scaffolding without occluding the background depth.
- **Data Accents:** Tertiary colors are used sparingly for status indicators (e.g., orange for streaks), but must maintain a high-vibrancy, "light-emissive" quality.

## Typography

This design system uses a dual-font strategy to balance brand personality with technical utility.

1. **Outfit:** Used for all "human" elements—headings, greetings, and narrative text. It provides a clean, modern, and approachable geometry.
2. **JetBrains Mono:** Used for all "machine" elements—metrics, timestamps, counts, and status labels. The monospaced nature emphasizes the tactical, data-driven nature of the product.

**Hierarchy Rule:** Large display headings should use tighter letter spacing, while small tactical labels should use increased letter spacing to enhance legibility in low-light dark mode environments.

## Layout & Spacing

The layout philosophy follows a **Fixed-Fluid Hybrid** model. On mobile, elements respect a generous 24px side margin to create breathing room against the bezel.

The "Deep Vertical Rhythm" is achieved by using 32px or 40px gaps between major glass cards. Within cards, a strict 24px padding is maintained to ensure the content does not feel crowded by the high-refraction borders. Navigation is pinned to the bottom of the viewport as a floating pill, separate from the content stack, creating a persistent layer of control.

## Elevation & Depth

Hierarchy is established through **Backdrop Refraction** rather than traditional drop shadows.

1.  **Base Layer:** The OLED black background.
2.  **Surface Layer:** Glass cards with a `backdrop-filter: blur(24px)` and a 1px white border at 12-20% opacity. This creates a "frosted" look that separates content from the background.
3.  **Active Layer:** Elements of focus (like the active nav icon or primary buttons) feature a **Localized Radial Glow**. This is a soft, diffused `box-shadow` or `background-gradient` using Neon Cyan at low opacity (15-25%) to simulate light being emitted from the component.
4.  **Top Layer:** Modals and tooltips increase the blur radius to 40px+ to create a sense of extreme proximity to the user.

## Shapes

The shape language is defined by **Hyper-Rounded Corners**. 

- **Large Containers/Cards:** Use a minimum radius of 24px (`rounded-3xl`) to create a liquid, organic feel that contrasts with the technical typography.
- **Interactive Elements:** Buttons and input fields should utilize pill-shaping (fully rounded) or a minimum of 16px radius.
- **Visual Contrast:** While containers are soft, internal data visualizations (like bar charts) should use slightly sharper radii (4px) to maintain a sense of precision.

## Components

### Glass Cards
The primary container. Must have `backdrop-filter: blur(24px)`, a background of `#FFFFFF0A`, and a 1px solid border of `#FFFFFF20`. Do not use inner shadows; let the refraction handle the depth.

### Floating Navigation Pill
A centered, bottom-fixed tray. It uses the same Glass Card styling but is fully pill-shaped. The active icon should have a 32px radial cyan glow (`#00E5FF`) centered behind it.

### Buttons
- **Primary:** Neon Cyan background with black text. No blur. High visibility.
- **Secondary:** Ghost style with 1px glass border and JetBrains Mono text.
- **Action Circles:** Small (48px) glass circles with centered icons, used for quick actions.

### Data Metrics
Always rendered in JetBrains Mono. Large metrics (e.g., "78%") should be white, while the unit ("%") or descriptive label should be a muted grey (#808080) to maintain focus on the value.

### Progress Indicators
Bars and charts should use linear gradients starting from Cyan to a transparent or muted version of the same hue, simulating "power" or "fill" levels.