# Sun Motions Overview — conversion notes

## Behaviour model

Sun Motions Overview shows a three-dimensional celestial sphere with a stick
figure standing at its centre on a green horizon plane. The observer's latitude
is set with a slider (−90° to +90°, starting at 41.0° N), and dragging the
sphere rotates the viewpoint around it. Four numbered checkboxes, all off at
start, progressively build up the picture: Step 1 draws the axis through the
north and south celestial poles with NCP/SCP captions; Step 2 draws the
celestial equator; Step 3 draws the sun's path on the equinoxes (declination
0°); and Step 4 draws the sun's paths on the summer and winter solstices
(declinations +23.5° and −23.5°). Each drawn circle carries a caption whose
individual letters are laid out along the circle so the text curves with the
sphere. Changing latitude re-tilts the whole celestial frame relative to the
horizon, which is the point of the simulation: at 41° N the poles sit 41° above
the horizon and the solstice paths rise to 72.5° and 25.5°. There is no
animation and no timed behaviour — every change is an immediate response to a
user action.

## Source

The `.swf` was decompiled with JPEXS/FFDec 26.2.1 into `../decompiled/`
(`-export script,shape,image,text,sprite,frame,symbolclass`). The folder as
delivered contained only `sunmotionsoverview.swf`, its `.jpg` screenshot, the
Ruffle wrapper page and `foundation/`; no decompiled sources were present, so
they were generated before starting.

Stage: 300 × 500 px, black background, 20 fps, SWF version 6.

## ActionScript → HTML5 mapping

| ActionScript | HTML5 port |
| --- | --- |
| `CelestialSphereClass` (`CelestialSphere.as`) + its 8 partial-class frames | One `state` object plus module-level functions in `simulation.js` |
| `doA` / `doM` / `doB` matrix builders (`3 CS Geometry.as`) | `doA()` / `doM()` / `doB()`, coefficients copied verbatim |
| `WtoSz`, `CtoSz`, `CtoW`, `StoMH`, `parsePointInput` | Same names, same formulas |
| `CSCirclesClass` (`8 CS Circles.as`) | `Circle` class; `doW()` and the front/back arc split are direct ports |
| the local `drawArc()` (tessellates with `curveTo`) | `strokeCircleArc()` using `quadraticCurveTo`, same `_minStep = π/4` |
| `CSLinesClass` (`9 CS Lines.as`) | `Line.segments()`, same sphere/horizon-plane split maths |
| `CSObjectsClass` (`7 CS Objects.as`) | `SphereObject`, orientation types "skewed" and "absolute" |
| `addDeclinationText()` | `makeDeclinationText()` |
| depth layers (`_bEL`, `_bC`, `_iLB`, `_hP`, `_iLA`, `_fISF`, `_fC`, `_fOSB`, `_fEL`, …) | An explicit painter's-order sequence in `render()` |
| `setMask` / mask clips `_M0`–`_M4` (`6 CS Shading.as`) | `clipMaskM2()` — see "Masks" below |
| `startSimpleDragging` / `updateSimpleDragging` (`4 CS Mouse.as`) | Pointer Events on the canvas, identical `(Δx)/r` rotation maths, plus a keyboard path |
| `SliderV3Latitude` + `FCheckBox` (Flash UI components) | Native `<input type="range">`, `<input type="number">` and `<input type="checkbox">` — the component framework itself is **not** ported, only its observable behaviour |
| `SliderV3LatitudeClass.toFixed` / `setValue` | `latToFixed()` / `latText()`, same rounding and the same `"° N"` / `"° S"` hemisphere suffix |
| `onEnterFrame`, `getTimer()`, `updateAfterEvent()` | Not needed — the simulation has no animation loop |
| `trace()` | Dropped |

### Constants carried over verbatim

- Sphere: `size = 250` → radius 125; `viewerAzimuth = 200`, `viewerAltitude = 40`,
  `setLatitude(41)`, `setSiderealTime(0)`, `sortObjects = false`.
- Colours as AS decimal RGB ints: pole axis `7711231` (#75A9FF), celestial
  equator `16769909` (#FFE375), sun paths `16711680` (#FF0000), meridians
  `16777215` (#FFFFFF) at alpha 20.
- Declinations `23.5` / `−23.5`; caption declinations `85`, `−85`, `0.7`.
- Circle tessellation step `_minStep = 0.7853981633974483`.
- Mask geometry `r = 100`, `d = 120`, `hnp = 4`.
- Slider: min −90, max 90, initial 41, precision 1.
- All four checkbox labels and all caption strings are verbatim.

### Verification

The ported transforms were checked against independent astronomy at latitude 41° N:
NCP altitude 41.0° due north, SCP −41.0° at azimuth 180°, and maximum altitudes
of 72.5° / 49.0° / 25.5° for the summer-solstice, equinox and winter-solstice
paths — matching `90 − lat + dec` exactly. A pointer drag of one sphere radius
rotates the view by exactly 1 radian at any display scale, matching
`updateSimpleDragging`.

## Assets: reused vs. code-drawn

The export contained **no bitmaps** (`images/` is empty), so nothing needed
`drawImage` of a photo. Five exported vector shapes are reused **as-is** from
`shapes/*.svg`, copied to `assets/shapes/` and drawn with `drawImage`; none were
redrawn or re-vectorised:

| File | Symbol | Use |
| --- | --- | --- |
| `23.svg` | `CSAboveHorizonPlane` | horizon plane seen from above (green gradient) |
| `21.svg` | `CSBelowHorizonPlane` | horizon plane seen from below (#006600) |
| `67.svg` | `sphere outside` | grey radial shading on the front inner surface |
| `65.svg` | `sphere outside2` | dark radial shading below the horizon |
| `59.svg` | `Stickman` | the stick figure at the centre |

Genuinely code-drawn art — the circles, the pole axis lines, the caption
letters, the `CSGradientDisk` "celestial bowl", and the N/S/E/W markers — is
reproduced with canvas 2D drawing, because the ActionScript builds it at runtime
and no exported file exists for it.

## Deviations from the original, and why

1. **Layout is the KL-UNL shell, not the Flash pixel layout.** The original is a
   fixed 300 × 500 portrait stage with the sphere on top, the latitude slider
   below it and four checkboxes stacked underneath. That grouping and reading
   order are preserved: the diagram panel comes first, then the latitude
   controls, then the four steps. Below the foundation's 56rem breakpoint the
   layout stacks exactly like the original; above it the diagram takes the wide
   column and the controls the 25rem column, so the sphere is not stranded at
   300px on a desktop.

2. **Flash UI components are not ported.** Per the conversion rules,
   `SliderV3Latitude`, `FCheckBox` and `FUIComponent` are replaced by native
   accessible controls. The observable behaviour (range, step, value formatting,
   change handlers) is identical.

3. **Captions are static: positioned on the sphere, but never rotated with it.**
   This is a deliberate, requested departure from the original.

   The source has a bug here. `addDeclinationText()` passes `leterrsRAs[i]` — a
   typo for `letterRAs` — as the right ascension of each letter's "up" vector,
   so that vector evaluated to `NaN` and the counter-rotation that would have
   stood each glyph up straight never happened. What remained was the shell
   rotation, which tilts every glyph with the sphere's local surface normal and
   vertically squashes it by that normal's screen-depth. The visible result is
   that captions spin as the sphere is dragged, and mirror themselves whenever
   the squash factor goes negative.

   The port therefore paints caption glyphs **upright**. Each letter still sits
   at its own point along its line of constant declination, so a caption follows
   the curve of the circle it annotates and travels with the sphere as the view
   turns — only the glyph orientation is held level. The normal is still
   computed, because it is what classifies a letter as front- or back-facing for
   depth ordering. See `setAbsoluteNormal()` and `paintObject()`.

4. **Caption letter spacing uses live text metrics.** The original measured
   letter widths with Flash's `TextFormat.getTextExtent()` on Verdana 12px. The
   port uses `measureText()` with a `Verdana, "DejaVu Sans", Geneva, sans-serif`
   stack, so spacing is identical wherever Verdana is installed (Windows, macOS)
   and very close elsewhere. Hard-coding the Verdana advance-width table was
   rejected as a source of silent error.

5. **The stray `CS Point` object is omitted.** A `CS Point` instance named
   `point` is placed on the stage at (254, 123), but its art (`shapes/102.svg`)
   is filled at `fill-opacity: 0` and its handlers call methods that do not
   exist on its parent. It is invisible and non-functional dev leftover.

6. **N/S/E/W markers keep their place on the horizon plane but are also drawn
   upright.** In the original they ride the plane's transform, so they are
   rotated and squashed flat with it — and mirrored at roughly half of all
   viewing angles, which makes them unreadable. For consistency with deviation 3
   the plane transform is applied to each marker's *anchor point* only, by hand,
   so north still sits at the horizon's north point and swings round as the view
   turns, while the glyph stays level. They are also centred on the original
   placement coordinates rather than reproducing the Flash `DefineText`
   glyph-box offsets; at the size they render the difference is not perceptible.

7. **Repeated toggling no longer leaks caption letters.** In the original,
   re-checking a box called `addDeclinationText()` again, which allocated a new
   set of letter objects and overwrote the array entry, leaving the previous
   letters in the sphere's object list forever. The port rebuilds the scene from
   state each time, so the visible result is the same but nothing accumulates.

8. **The mask system is simplified to what is actually used.** The original
   builds five mask clips and duplicates them across sixteen layers; in this
   simulation only three of those layers ever receive content, and only mask
   `M2` clips anything. `clipMaskM2()` ports that one mask; the empty layers are
   omitted rather than reproduced as no-ops.

9. **A polling safety net supplements the resize handlers.** `ResizeObserver`
   and the `resize` event are the fast paths, but neither is delivered while a
   document is hidden (frame production is suspended), which could otherwise
   leave the stage drawn at a stale scale. A 500 ms poll compares one integer and
   redraws only on a real change.

## contents.json

This sim already had an entry keyed `sunmotionsoverview` in the shared
`contents.json`. Following the per-sim-copy model, the copy in
`html5/foundation/contents.json` is the only foundation file whose content was
changed, and the only change is to that entry's `masthead.help.content`, which
was expanded from a single sentence to describe the drag/keyboard interaction,
the latitude slider and the four steps — all derived from the simulation's own
control labels. `meta`, `masthead.about`, every other entry, and the code of
`kl-unl-masthead.js`, `kl-unl.css` and `kl-unl.js` are byte-for-byte unchanged
(verified by SHA-256).

If your pipeline instead treats `contents.json` as a single **shared** file,
delete `html5/foundation/contents.json` and apply this replacement to the shared
file's `sunmotionsoverview.masthead.help.content`:

```html
<p>This overview shows the paths of the sun on the celestial sphere.</p><p>Drag the celestial sphere to rotate your viewpoint. With the sphere focused, the arrow keys rotate it as well: left and right change the viewing azimuth, up and down change the viewing altitude.</p><p>Use the <strong>Latitude</strong> slider to set the observer&#39;s latitude, from 90&#176; S through 90&#176; N. The stick figure stands at the center of the sphere, on the horizon plane.</p><p>Turn on the four steps in order to build up the picture:</p><ul><li><strong>Step 1: Show Poles</strong> &#8212; draws the axis through the north and south celestial poles (NCP and SCP).</li><li><strong>Step 2: Show CE</strong> &#8212; draws the celestial equator.</li><li><strong>Step 3: Show Equinox Path</strong> &#8212; draws the sun&#39;s path on the equinoxes, at declination 0&#176;.</li><li><strong>Step 4: Show Solstice Paths</strong> &#8212; draws the sun&#39;s paths on the summer and winter solstices, at declinations +23.5&#176; and &#8722;23.5&#176;.</li></ul>
```

## Cross-browser notes

Everything used is broadly supported: Canvas 2D, Pointer Events, CSS grid,
`aspect-ratio`, `ResizeObserver`, custom elements. No vendor-prefixed CSS is
relied on and there are no Chrome-only APIs. Two things worth knowing:

- **Caption spacing depends on Verdana availability** (see deviation 4). Windows
  and macOS ship Verdana; most Linux and Android images do not, so letter
  spacing along the captions can differ by a pixel or two there.
- **Screenshot-based verification was not possible in the authoring
  environment** — the preview pane reports `document.visibilityState ==="hidden"`,
  which suspends `requestAnimationFrame` and screen capture. Rendering was
  therefore verified numerically (pixel-coverage and geometry probes against
  independently computed astronomy) rather than by eye. **A human should still
  view the simulation side by side with `../sunmotionsoverview.jpg` to confirm
  the visual match**, and check Safari on macOS and iOS specifically.
