# Sun Motions Overview — accessibility

Target: **WCAG 2.1 AA**, with AAA where it came cheaply. This documents what was
added, what was deliberately left alone, and what still needs a human.

## Structure and semantics

- One `<h1>`, rendered by the shared `<kl-unl-masthead>` component. The sim adds
  no competing `<h1>`; its panels start at `<h2>` ("Celestial sphere",
  "Controls") and do not skip levels.
- Landmarks: `<main class="app-layout">` wrapping two `<section class="panel">`
  elements, each tied to its heading with `aria-labelledby`. The masthead
  provides the header region.
- `<html lang="en">`.
- A visually-hidden skip link jumps past the diagram to the controls.
- Every input has a real `<label>`; the two control groups are wrapped in
  `<fieldset>` with a `<legend>` ("Observer", "Build up the picture").

## Keyboard map

The tab order contains **only** interactive controls, in reading order:

| Order | Control |
| --- | --- |
| 1 | Sphere viewing direction (`#sphere-view`) |
| 2 | Latitude slider |
| 3 | Latitude number field |
| 4–7 | Step 1 – Step 4 checkboxes |

(The masthead's Reset / Help / About buttons precede these, inside the component.)

### Sphere

The sphere is mouse-draggable, so per the two-behaviour rule it is also fully
keyboard-operable through a focusable proxy element overlaying the stage
(`role="slider"`, `aria-label`, live `aria-valuetext`).

| Key | Action |
| --- | --- |
| Tab | Focus the sphere (visible focus ring around the stage) |
| Click / tap | Also focuses it, so the arrow keys work immediately afterwards |
| ← / → | Rotate the viewing azimuth by 5° |
| ↑ / ↓ | Raise / lower the viewing altitude by 5° |
| Shift + arrow | Coarser 15° step |
| Page Up / Page Down | Viewing altitude by 15° |
| Home / End | Viewing altitude to +90° / −90° |

Tab always moves away normally — there is no trap. The canvas's pointer handlers
do not swallow focus or key events, and both the pointer and keyboard paths
mutate the same `state` object, so they can never disagree.

### Latitude

Both the slider and the number field adjust the same state.

| Key | Action |
| --- | --- |
| ← / ↓ and → / ↑ | ±0.1° (native `<input type="range">` behaviour) |
| ↑ / ↓ in the number field | ±0.1° (native spinner behaviour) |
| Page Up / Page Down | ±5° |
| Home / End | −90° / +90° |
| Mouse wheel | ±0.1° **while the field is focused**, with `preventDefault()` so the page does not scroll |

The wheel listeners are registered non-passive and only act when the control
actually has focus, so ordinary page scrolling is unaffected.

## Screen-reader narration

Tested mentally against both **NVDA** (Windows, Chrome/Firefox) and **VoiceOver**
(macOS, Chrome/Safari).

**Units are always spoken.** No control announces a bare number:

- Latitude slider: `aria-valuetext="Latitude 41.0 degrees north"` — the quantity,
  the number and the unit, with the hemisphere spelled out as a word rather than
  relying on the adjacent "° N" glyph, which screen readers skip or mis-read.
- Latitude number field: the same string as its `aria-label`.
- Sphere proxy: `aria-valuetext="Viewing direction: azimuth 200 degrees, viewing
  altitude 40 degrees"` — both components of the pair are named and carry units,
  so the pair is unambiguous in audio.

**Live region.** A `.sr-only` `role="status" aria-live="polite"` element
announces changes **on commit**, never per tick — on slider `change` (release),
on drag end, on each arrow-key press, on each checkbox toggle, and on Reset. It
is never `assertive`. Wording matches the on-screen text.

**The diagram is described, not just the controls.** A visually-hidden
description tied to the canvas via `aria-describedby` is regenerated from the
single `render()` on every state change, so an audio-only user gets the same
"what's happening" a sighted user sees. For example:

> Celestial sphere seen from 41.0 degrees north latitude, looking toward azimuth
> 200 degrees from a viewing altitude of 40 degrees. A stick figure stands at the
> centre, on the green horizon plane, with north, south, east and west marked
> around its edge. Also shown: the axis through the north and south celestial
> poles, labelled N C P and S C P; the celestial equator; the sun's paths on the
> summer and winter solstices, at declinations plus 23.5 degrees and minus 23.5
> degrees.

"NCP" is written "N C P" so it is spelled out rather than pronounced as a word.

## Mathematics

All mathematical notation in the interface is typeset by MathJax (LaTeX, SVG
output, vendored locally) through the foundation's `klunlShowEquation()`:

- the latitude readout, e.g. \(41.0^\circ\,\mathrm{N}\);
- the slider's end labels \(90^\circ\,\mathrm{S}\) and \(90^\circ\,\mathrm{N}\);
- the declinations in the path key: \(0^\circ\), \(+23.5^\circ\), \(-23.5^\circ\).

No math is drawn as a raster image, as plain-text ASCII, or as hand-built
`<sub>`/`<sup>`. Right-clicking any of it opens MathJax's own context menu
("Show Math As → TeX / MathML"); the menu is left enabled and the `contextmenu`
event is never trapped.

**MathJax is kept out of the tab order.** With the menu enabled MathJax marks
every `<mjx-container>` with `tabindex="0"`, which would make display-only maths
a tab stop. A `MutationObserver` forces `tabindex="-1"` on those containers
instead. They remain readable by screen readers — each typeset value is paired
with an `.sr-only` spoken description — they are simply not operable, because
there is nothing to operate. Verified: all 7 containers report `tabindex="-1"`,
and the only `tabindex="0"` in the document is the sphere proxy.

## Colour and contrast

- The palette comes from the KL-UNL CSS custom properties; no Flash colours are
  hard-coded into the chrome.
- **Colour is never the only signal.** The path key names every element in text
  and gives its declination, and the live description does the same. A user who
  cannot distinguish the red sun paths from the yellow celestial equator still
  gets "the celestial equator" and "the sun's paths … at declinations plus 23.5
  degrees and minus 23.5 degrees" from the description, and named rows in the key.
- The physically meaningful sphere colours are kept **unchanged** from the
  original (they are the subject matter, and the sphere renders on its original
  black sky where they meet contrast requirements). The swatches in the key carry
  a border so they stay perceivable against the panel background and in
  forced-colours mode.
- A `@media (forced-colors: active)` block keeps the swatches and the canvas
  frame visible in Windows High Contrast mode.

## Text size, zoom and reflow

- Body text is 1.125rem (18px at default settings) — above the 1rem floor — and
  everything is sized in rem/em, so it tracks the browser's font setting.
- No fixed pixel heights crop text; rows grow with their content.
- The layout reflows to a single column below the foundation's 56rem breakpoint
  and stays usable down to phone-portrait widths (verified at 375 × 812: no
  horizontal scrolling, nothing clipped or overlapping). 200% zoom is handled by
  the same mechanism, since it presents as a narrower viewport.
- The canvas keeps its original internal coordinate system and is scaled by CSS
  with its 1:1 aspect ratio preserved; pointer coordinates are mapped back
  through that scale, so hit-testing and the drag maths stay in Flash stage
  coordinates at any display size.

## Touch

- Pointer Events give mouse and touch a single code path.
- `touch-action: none` on the canvas, so dragging the sphere does not scroll or
  zoom the page; scrolling elsewhere is untouched.
- Targets meet the 44px minimum. The step checkboxes render at 24px, so their
  `<label>` fills the row and is 52px tall — clicking the label toggles the box,
  giving a target well above the minimum. Measured: 52px.
- Nothing is hover-only; there are no hover-revealed controls or information.

## Motion

This simulation has **no autonomous animation** — no `onEnterFrame` equivalent,
no timers driving state, no flashing. Every change is an immediate,
user-initiated response. Consequently:

- no Pause control is needed (nothing runs on its own),
- there is nothing that moves for more than 5 seconds without a stop,
- nothing flashes at any rate, let alone more than 3 times per second,
- `prefers-reduced-motion` has nothing to suppress; the rule present in
  `styles.css` only disables smooth scrolling on the skip link.

Reset is provided **only** by the masthead's `sim-reset` event — the sim adds no
second Reset button — and restores the exact initial state (azimuth 200°,
altitude 40°, latitude 41.0° N, all four steps off), with the DOM re-synced.

## Known limitations

1. **Caption text is drawn on the canvas.** The NCP/SCP and path captions are
   individual letters positioned along the circle they annotate, so they are
   intrinsically tied to the projected 3D geometry and cannot move into HTML
   without losing that association. They are not mathematical notation, so rule
   8a does not apply. All of their content is exposed to screen readers through
   the live description, and the path key repeats every label as real, zoomable
   HTML text.

   The glyphs themselves are painted **upright** rather than tilted and squashed
   with the sphere's surface (see CONVERSION_NOTES.md, deviation 3). Besides
   being what was asked for, this is the more legible result: the original's
   orientation maths mirrored the text at many viewing angles.

2. **The N/S/E/W markers are small.** They keep their position on the horizon
   plane, so north always marks the horizon's north point, but they too are drawn
   upright rather than squashed flat and mirrored. The canvas description states
   that north, south, east and west are marked around the plane's edge, so the
   information is not size- or colour-dependent.

3. **Human QA is still required.** Automated and scripted checks cannot
   substitute for listening to the simulation. Please verify with a real screen
   reader — NVDA on Windows and VoiceOver on macOS and iOS — that announcements
   are not duplicated, truncated or read out of order, and that tabbing through
   the controls reads a clear name, value and unit for each. Visual review
   against `../sunmotionsoverview.jpg` is also still outstanding, because the
   authoring environment could not produce screenshots (see CONVERSION_NOTES.md).
