# AEON Acrylic Logo for LEON (Flutter / Android)

## Implementation brief for Antigravity

### Mission

Implement the **AEON** logo as a production-quality Android launcher
icon and, if appropriate for the existing app architecture, a reusable
in-app logo/material treatment. The visual target is the **Acrylic
Solid** concept from the supplied blue logo exploration: a compact,
bold, geometric `AE` over `ON` mark inside a cool blue-grey acrylic
body, with a dark charcoal/navy foundation and restrained icy
highlights.

The result must look like a physical acrylic object under light, not
merely a blue gradient, a glow, a blurred background, or a static image
with a shiny border. Inspect the existing repository and current app
before changing anything. Preserve the existing LEON visual identity and
architecture unless a change is necessary.

### Important optical requirement: be honest about "real acrylic"

A launcher icon is a static image. It cannot refract the user's live
wallpaper or react to the scene behind it. A raster icon can depict
convincing acrylic optics, but cannot provide live physical refraction.

Inside the running app, a genuinely scene-responsive acrylic effect
needs a rendering technique that samples the content behind the material
and distorts it. `BackdropFilter` alone performs blur; it does **not**
create refraction, dispersion, or chromatic aberration. A gradient,
border, shadow, blur, or glow alone does not satisfy the requested
effect.

Implement the strongest practical solution for the actual target: 1.
**Launcher icon:** render a polished, static acrylic object with
physically plausible highlights, edge reflections, internal attenuation,
and subtle optical distortion baked into the artwork. Export
adaptive-icon layers and a monochrome fallback. 2. **In-app live
material, if requested/used:** use a real scene-sampling approach where
supported, such as a custom Flutter fragment shader (`FragmentProgram` /
`.frag`) that samples a captured or supplied background texture and
applies controlled UV distortion plus very subtle wavelength-separated
RGB sampling. If the existing renderer cannot provide a scene texture to
the shader, explicitly document the limitation and use a clearly named
fallback. Do not claim that a blur-only fallback is real refraction. 3.
Prioritize a stable, attractive result on Android devices over elaborate
effects that cause jank, excessive battery use, or unreadable UI.

Do not add an expensive continuously animated shader to every card. The
effect should be used for the logo and only a few intentional surfaces.

------------------------------------------------------------------------

## 1. First inspect the project

Before editing, inspect: - `pubspec.yaml`, Flutter SDK version, Android
`minSdk` / target SDK, and existing asset-generation configuration. -
Existing theme and colors, especially `lib/core/theme/app_colors.dart`,
`app_theme.dart`, and any typography/theme files. - App entry point,
routing, and state management (known project architecture may include
`ProviderScope`, Riverpod, and `MaterialApp.router`; verify in the
repository rather than assuming). - Existing logo assets, launcher
icons, and image-generation/build scripts. - Existing reusable widgets
and tests.

Do not overwrite current theme settings wholesale. Merge changes into
the existing theme and preserve typography, navigation, workout UI, and
other established components.

Before coding, identify: - Which logo surfaces are actually needed:
Android launcher icon only, in-app splash/header, or both. - Whether the
project already uses a custom shader, Impeller-compatible rendering, or
a shader package. - The minimum Android version and devices the app
targets.

Then implement, run static analysis, build, and test. Do not stop after
merely writing code.

------------------------------------------------------------------------

## 2. Logo composition and visual direction

### Wordmark layout

-   Spell the mark exactly as `AEON`.
-   Use a 2×2 arrangement: `AE` on the top row and `ON` on the bottom
    row.
-   Keep the visual widths, alignment, spacing, and stroke/letter mass
    optically balanced.
-   Favor a compact geometric sans-serif construction with rounded joins
    and carefully cut negative spaces.
-   The A should remain unmistakably an A; E must have three readable
    horizontal bars; O must remain open internally; N must have a clear
    diagonal.
-   Use bold/medium-heavy forms. Do not return to the original
    ultra-thin line-art version.
-   Do not let the lettering touch the outer rounded-square boundary.
-   The icon must remain legible at small launcher sizes.

### Palette

Use the current LEON app theme as the source of truth where possible.
The intended direction is cool blue, not green.

Suggested starting values, to be tuned against the existing app: - Deep
charcoal background: `#101419` - Navy/charcoal body: `#172431` to
`#263746` - Cool acrylic blue: `#7CBFFF` - Bright reflected highlight:
`#D9EEFF` - Main lettering: `#E4F1FF` - Muted steel-blue edge: `#5B8FB8`

These are design starting points, not a requirement to hardcode every
color. Use semantic theme colors when rendering inside the app.

### Shape and composition

-   Square master artwork, preferably 1024×1024.
-   Rounded-square acrylic body with controlled corner radii.
-   Central AE/ON mark.
-   Consistent safe margins for Android adaptive icon masking.
-   Strong silhouette and contrast at 48--96 dp.
-   No tiny labels, text, or decorative noise.
-   No green cast, gold tint, or excessive neon.
-   Avoid a huge exterior glow. The object should feel like solid
    acrylic, not a neon sign.

------------------------------------------------------------------------

## 3. What makes the material look like acrylic

The appearance should be built from several distinct optical cues. Do
not rely on one gradient layer.

### A. Bulk transmission and absorption

Acrylic transmits light but is not visually absent. Give the body a
lightly tinted, translucent blue-grey volume. The center should have
depth and slight attenuation rather than a uniform flat blue fill.

### B. Fresnel-like edge response

Reflections become stronger toward grazing angles/edges. Use brighter,
narrow edge reflections near the outer silhouette and subtler
reflections across front-facing areas. Edge brightness must be
controlled and not look like a uniform stroke.

### C. Refraction

For a live effect, distort the background image behind the acrylic
surface using a smooth, low-amplitude UV displacement field. The
displacement should be strongest near curved edges and weaker across the
central face. Avoid large warps that make UI text behind the material
unreadable.

### D. Dispersion

For a live shader, sample red, green, and blue channels at slightly
different UV coordinates to create very subtle wavelength separation
near high-curvature edges. Keep it restrained; obvious rainbow fringes
look like a novelty filter rather than premium acrylic. For the static
icon, bake a very subtle cool fringe into selected highlights only.

### E. Specular highlights

Create broad, soft studio reflections plus a few narrow highlights along
the bevel. Highlights should have a clear lighting direction (for
example, upper-left key light and a weaker lower-right rim). Avoid
evenly glowing all four edges.

### F. Bevel and thickness

The acrylic body needs visible thickness: a rounded bevel, a narrow
darker internal rim, and a small amount of internal reflection. Use
layered geometry or vector paths rather than a single outline.

### G. Surface imperfections

Keep the surface clean and premium. Optional microtexture must be
extremely subtle and only visible at large sizes. Do not add obvious
scratches, dust, or noisy grain.

### H. Shadow and contact

Use a soft contact shadow to separate the object from the background.
Keep the shadow close to the object. Avoid large black drop shadows that
make the icon look like a floating button.

------------------------------------------------------------------------

## 4. Android launcher icon deliverables

Generate a proper adaptive icon, not only a single square PNG.

### Required assets

Create or update the project's launcher assets using the repository's
current preferred workflow: - Adaptive foreground: transparent
background containing the AEON mark and foreground acrylic details. -
Adaptive background: solid or subtly graduated dark navy/charcoal. -
Monochrome foreground: simple, single-color AEON silhouette for themed
Android icons. - High-resolution master artwork for future exports.

If the chosen icon design requires the acrylic body itself to be visible
as part of the icon, decide carefully whether the body belongs in the
foreground layer or the background layer. Test Android masking to make
sure the object is not unintentionally clipped. Do not bake a
rectangular background into the foreground PNG.

### Safe area

Keep all important logo features inside the adaptive icon safe area. Aim
to keep the core mark comfortably within the central \~66% of the
canvas, with optical adjustments as needed. Test circular, squircle, and
rounded-square masks. Do not rely on all pixels of the square being
visible.

### Flutter tooling

Inspect the current setup first. If the project uses
`flutter_launcher_icons`, configure its existing version and syntax
rather than blindly replacing dependency versions. A typical
configuration can use: - `image_path` for legacy launcher support where
needed. - `adaptive_icon_background` for the dark base. -
`adaptive_icon_foreground` for the transparent foreground. -
`adaptive_icon_monochrome` where supported by the installed package
version.

Run the asset generator and confirm that the generated Android resources
are actually present. Check `android/app/src/main/res/` and relevant
manifest/configuration. Do not merely add config without generating
assets.

If there is a separate native Android splash screen, keep its branding
consistent but do not confuse the splash image with the launcher icon.

------------------------------------------------------------------------

## 5. In-app live acrylic: implementation approach

Only implement this section if the project needs the acrylic material
inside the app. The launcher icon itself remains static.

### Preferred rendering pipeline

1.  Identify the background content that should be visible through the
    acrylic surface.
2.  Capture or provide that background as a texture to the material
    renderer.
3.  Render the acrylic shape with a mask and rounded edges.
4.  Sample the background texture using a controlled displacement field.
5.  Add restrained RGB channel offsets near edges for subtle dispersion.
6.  Composite the tinted transmitted background, internal attenuation,
    Fresnel-like reflections, bevel highlights, and contact shadow.
7.  Clip everything to the exact rounded shape.
8.  Respect device pixel ratio, orientation, screen resizing, and theme
    changes.
9.  Use the least expensive rendering path that satisfies the visual
    target.

### Flutter fragment shader guidance

If a custom shader is appropriate: - Add a `.frag` shader under the
project's shader assets directory. - Register it in `pubspec.yaml` under
`flutter: shaders:`. - Load it through Flutter's `FragmentProgram`
API. - Confirm the Flutter SDK's supported shader APIs and uniforms
before coding. - Supply a valid background texture through a supported
shader-sampling path. Do not assume `BackdropFilter` automatically
exposes its backdrop as a shader texture. - If using
`ImageFilter.shader` or another shader-backed filter, verify the exact
API and background-sampling semantics supported by the project's Flutter
version. - Separate uniforms for size, tint, refraction strength,
dispersion strength, edge width, and lighting direction so the effect
can be tuned. - Use a rounded-rectangle distance field or mask to define
the material boundary and bevel. - Keep shader math bounded and avoid
per-pixel loops. - Clamp UVs to valid texture bounds and handle
transparent edges to prevent sampling artifacts. - Use subtle
displacement and chromatic separation, not dramatic rainbow edges. -
Ensure the shader compiles on the actual Android renderer and test on a
physical device.

### Critical limitation

A shader cannot refract content it cannot sample. If Flutter's available
rendering path does not expose the current scene as a texture, do not
pretend a fragment shader can magically read arbitrary pixels behind a
widget. Choose a supported approach: - Pass a known background
image/texture into the shader, or - Build a deliberate
compositing/capture pipeline for the specific screen region, or - Use a
transparent tinted surface with lighting highlights as an explicitly
documented fallback.

Avoid a whole-screen screenshot every frame as a default solution. It
can be expensive, cause feedback loops, and introduce latency. If
capture is necessary, update only when needed and profile it.

### Performance and accessibility

-   Target smooth scrolling and transitions on mid-range Android
    devices.
-   Avoid continuous shader animation when the surface is idle.
-   Reuse compiled shader programs and textures.
-   Avoid excessive `saveLayer` / offscreen compositing.
-   Clip only where needed.
-   Respect reduced-motion/accessibility settings if any animation is
    added.
-   Ensure text remains legible over and around the material.
-   Provide a non-shader fallback if shader compilation or texture
    access fails.
-   Keep the material decorative; do not place essential labels over
    highly distorted backgrounds.

------------------------------------------------------------------------

## 6. Theme integration

The material should follow the app's active theme instead of using a
fixed blue value everywhere.

-   Read semantic colors from `Theme.of(context).colorScheme`.
-   Define a small material configuration (for example: tint, refraction
    strength, dispersion strength, edge highlight, and blur) rather than
    scattering magic numbers through widgets.
-   Use cool blue as the default LEON treatment.
-   If the app supports alternate themes, the acrylic tint and
    highlights should adapt.
-   Keep the icon artwork itself consistent; launcher artwork does not
    automatically recolor with the app theme.
-   Do not change every existing card into glass. Preserve the current
    solid charcoal cards for workout data, metrics, and dense content.
-   Use acrylic selectively for the logo, splash/brand presentation, and
    at most a few floating surfaces.
-   Ensure dialogs and plate-calculator content remain high-contrast and
    readable.

------------------------------------------------------------------------

## 7. In-app logo widget (if needed)

Create a reusable widget such as `AeonLogo` only if the logo is
displayed inside the app. It should: - Accept a size and optional
semantic theme/material configuration. - Use vector artwork or
high-resolution raster artwork for the wordmark. - Avoid re-rendering a
large shader when the widget is off-screen. - Scale without
distortion. - Expose a stable, accessible semantic label such as
`AEON logo` where appropriate. - Offer a static rendering mode for
low-performance devices and tests.

Do not put the entire logo in a live shader if only the surrounding
acrylic body needs optical effects. Keep the letters crisp and legible,
with the material effect clipped to the body.

------------------------------------------------------------------------

## 8. Suggested project structure

Adapt this to the existing repository rather than forcing the exact
paths:

``` text
assets/
  icons/
    aeon_master.png
    aeon_foreground.png
    aeon_monochrome.png
  images/
    aeon_logo_static.png

lib/
  core/
    theme/
      app_colors.dart
      app_theme.dart
    widgets/
      aeon_logo.dart
      acrylic_surface.dart

shaders/
  acrylic_material.frag
```

Only add `acrylic_material.frag` if a live, texture-sampling shader is
actually implemented. Do not add unused or non-compiling shader files.

------------------------------------------------------------------------

## 9. Validation checklist

### Artwork

-   [ ] Correct spelling and 2×2 `AE` / `ON` arrangement.
-   [ ] Bold, balanced letterforms that read at small sizes.
-   [ ] Cool blue palette, no green cast.
-   [ ] Material has visible volume, bevel, directional reflections, and
    restrained internal tint.
-   [ ] No huge neon glow, excessive rainbow dispersion, or noisy
    texture.
-   [ ] Strong contrast on dark backgrounds.

### Android icon

-   [ ] Adaptive foreground/background are configured correctly.
-   [ ] Monochrome icon exists if supported.
-   [ ] Icon survives circular, squircle, and rounded-square masks.
-   [ ] No clipping of the letters or important acrylic edges.
-   [ ] Icon is legible at real launcher sizes.
-   [ ] Generated assets are committed in the expected resource
    locations.

### Live material (if implemented)

-   [ ] The background is genuinely sampled as a texture.
-   [ ] Refraction visibly distorts background content in a controlled
    way.
-   [ ] Dispersion is subtle and localized to suitable edges.
-   [ ] Blur-only effects are not described as refraction.
-   [ ] Fallback is available if the shader or texture pipeline is
    unavailable.
-   [ ] No visible artifacts at rounded corners or screen edges.
-   [ ] Tested on a physical Android device.

### Engineering

-   [ ] Existing app theme and layout are preserved.
-   [ ] `flutter analyze` passes, or any pre-existing warnings are
    documented.
-   [ ] Relevant tests pass.
-   [ ] `flutter build apk --debug` succeeds.
-   [ ] The app is installed/launched or the remaining device test steps
    are clearly reported.
-   [ ] No unrelated dependency upgrades or broad refactors.

------------------------------------------------------------------------

## 10. Required final response from Antigravity

When finished, report: 1. Which files were changed or created. 2. How
the final logo artwork was produced and where the master assets are
stored. 3. How the Android adaptive icon and monochrome icon are
configured. 4. Whether the in-app material uses actual background
texture sampling and UV refraction, or a documented fallback. 5. What
visual tests were performed and on which emulator/device. 6. Whether
analysis, tests, and Android build passed. 7. Any remaining limitations,
especially if live refraction/dispersion cannot be implemented with the
current Flutter rendering path.

Do not claim "real acrylic", "real refraction", or "dispersion" unless
the implementation actually samples and distorts a background texture.
The static launcher artwork may be described as a physically inspired
acrylic rendering, not a live optical material.
