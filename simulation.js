/* ===========================================================================
   Sun Motions Overview -- HTML5 port of sunmotionsoverview.swf (Flash / AS1)
   ---------------------------------------------------------------------------
   Behavior is a direct port of the decompiled ActionScript:
     scripts/CelestialSphere.as        sphere construction + update pipeline
     scripts/2 CS Getter Setter.as     theta/phi/latitude/siderealTime accessors
     scripts/3 CS Geometry.as          coordinate transforms, doA/doM/doB
     scripts/4 CS Mouse.as             "simple drag" view rotation
     scripts/5 CS Horizon Plane.as     horizon plane scaling/rotation
     scripts/6 CS Shading.as           mask geometry + shading layers
     scripts/7 CS Objects.as           positioned objects + orientation
     scripts/8 CS Circles.as           great/small circles, front/back split
     scripts/9 CS Lines.as             line segmentation by sphere + horizon
     scripts/DefineSprite_105/frame_1/DoAction.as   the main controller
     scripts/SliderV3Latitude.as       latitude slider value formatting

   All constants, colors, angles and formulas below are verbatim from that
   source. Presentation (controls, palette, focus handling) follows KL-UNL +
   WCAG 2.1 AA; see ACCESSIBILITY.md and CONVERSION_NOTES.md.
   =========================================================================== */

'use strict';

/* ---------------------------------------------------------------------------
   Constants carried over verbatim from the ActionScript
   --------------------------------------------------------------------------- */

const DEG2RAD  = 0.017453292519943295;   // pi/180
const RAD2DEG  = 57.29577951308232;      // 180/pi
const HR2RAD   = 0.2617993877991494;     // pi/12   (hours of RA -> radians)
const RAD2HR   = 3.819718634205488;      // 12/pi
const TWO_PI   = 6.283185307179586;
const HALF_PI  = 1.5707963267948966;

// sphere.size = 250  ->  CelestialSphereClass._c.r = size / 2
const SPHERE_R  = 125;
const SPHERE_R2 = SPHERE_R * SPHERE_R;

// CSCirclesClass.prototype._minStep
const MIN_STEP = 0.7853981633974483;     // pi/4

// Mask geometry from "6 CS Shading.as" (base units; scaled by _c.r / 100)
const MASK_R = 100;
const MASK_D = 120;
const MASK_HALF_N = 4;                   // hnp

// Initial view, from DefineSprite_105/frame_1/DoAction.as
const INIT_VIEWER_AZIMUTH  = 200;        // sphere.viewerAzimuth = 200
const INIT_VIEWER_ALTITUDE = 40;         // sphere.viewerAltitude = 40
const INIT_LATITUDE        = 41;         // sphere.setLatitude(41)

// Colors, verbatim as AS decimal RGB integers
const COLOR_POLE_AXIS        = 7711231;  // 0x75A9FF  ncpAxis / scpAxis
const COLOR_CELESTIAL_EQUATOR= 16769909; // 0xFFE375  celestialEquator
const COLOR_SUN_PATH         = 16711680; // 0xFF0000  equinox + solstice paths
const COLOR_MERIDIAN         = 16777215; // 0xFFFFFF  meridianCircle1 / 2

// Declinations of the sun's paths (verbatim from stepFourChanged)
const DEC_SUMMER_SOLSTICE =  23.5;
const DEC_WINTER_SOLSTICE = -23.5;

// Canvas stage. The sphere's own coordinate system is unchanged from Flash
// (origin at the sphere centre, radius 125); only the origin's placement
// inside the canvas differs, so that the sphere sits centred in its panel.
const STAGE_W = 320;
const STAGE_H = 320;
const STAGE_CX = 160;
const STAGE_CY = 160;

// Verdana at 12 px, matching the "Verdana Letter" symbol (fontHeight 240 twips)
const LETTER_FONT = '12px Verdana, "DejaVu Sans", Geneva, sans-serif';
const LETTER_COLOR = '#ffffff';

/* ---------------------------------------------------------------------------
   Small helpers
   --------------------------------------------------------------------------- */

// CelestialSphereClass.prototype.mod -- always returns a non-negative result
function mod(n, m) {
  return ((n % m) + m) % m;
}

// AS colors are decimal RGB ints; AS alpha is 0-100.
function rgba(color, alpha100) {
  const r = (color >> 16) & 0xff;
  const g = (color >> 8) & 0xff;
  const b = color & 0xff;
  return 'rgba(' + r + ',' + g + ',' + b + ',' + (alpha100 / 100) + ')';
}

/* ---------------------------------------------------------------------------
   Single source of truth for simulation state
   --------------------------------------------------------------------------- */

const state = {
  // View orientation. theta is derived from viewerAzimuth via
  // setViewerAzimuth: setTheta(360 - azimuth). phi is the viewer altitude.
  theta: mod(360 - INIT_VIEWER_AZIMUTH, 360) * DEG2RAD,
  phi:   INIT_VIEWER_ALTITUDE * DEG2RAD,
  lat:   INIT_LATITUDE * DEG2RAD,
  sTime: 0,                       // sphere.setSiderealTime(0)

  // The four "Step" checkboxes; all start unchecked (initialValue = false)
  showPoles:     false,
  showCE:        false,
  showEquinox:   false,
  showSolstice:  false
};

// _maxPhi / _minPhi from the CelestialSphereClass constructor
const MAX_PHI = 90;
const MIN_PHI = -90;

/* ---------------------------------------------------------------------------
   Transformation matrices -- doA / doM / doB from "3 CS Geometry.as"
   --------------------------------------------------------------------------- */

const c = {};   // mirrors CelestialSphereClass._c

function doA() {
  const ct = Math.cos(state.theta), st = Math.sin(state.theta);
  const cp = Math.cos(state.phi),   sp = Math.sin(state.phi);
  const r = SPHERE_R;
  c.a0 = -r * st;
  c.a1 =  r * ct;
  c.a3 =  r * ct * sp;
  c.a4 =  r * st * sp;
  c.a5 = -r * cp;
  c.a6 =  r * ct * cp;
  c.a7 =  r * st * cp;
  c.a8 =  r * sp;
}

function doM() {
  c.m2 =  Math.cos(state.lat);
  c.m3 =  Math.sin(state.sTime);
  c.m4 = -Math.cos(state.sTime);
  c.m8 =  Math.sin(state.lat);
  c.m0 =  c.m4 * c.m8;
  c.m1 = -c.m3 * c.m8;
  c.m6 = -c.m2 * c.m4;
  c.m7 =  c.m2 * c.m3;
}

function doB() {
  c.b0 = c.a0 * c.m0 + c.a1 * c.m3;
  c.b1 = c.a0 * c.m1 + c.a1 * c.m4;
  c.b2 = c.a0 * c.m2;
  c.b3 = c.a3 * c.m0 + c.a4 * c.m3 + c.a5 * c.m6;
  c.b4 = c.a3 * c.m1 + c.a4 * c.m4 + c.a5 * c.m7;
  c.b5 = c.a3 * c.m2 + c.a5 * c.m8;
  c.b6 = c.a6 * c.m0 + c.a7 * c.m3 + c.a8 * c.m6;
  c.b7 = c.a6 * c.m1 + c.a7 * c.m4 + c.a8 * c.m7;
  c.b8 = c.a6 * c.m2 + c.a8 * c.m8;
}

function updateMatrices() {
  doA();
  doM();
  doB();
}

/* --- point transforms ----------------------------------------------------- */

// World (horizon) -> screen, with depth
function WtoSz(p, sp) {
  sp.x = p.x * c.a0 + p.y * c.a1;
  sp.y = p.x * c.a3 + p.y * c.a4 + p.z * c.a5;
  sp.z = p.x * c.a6 + p.y * c.a7 + p.z * c.a8;
  return sp;
}

// Celestial -> screen, with depth
function CtoSz(p, sp) {
  sp.x = p.x * c.b0 + p.y * c.b1 + p.z * c.b2;
  sp.y = p.x * c.b3 + p.y * c.b4 + p.z * c.b5;
  sp.z = p.x * c.b6 + p.y * c.b7 + p.z * c.b8;
  return sp;
}

// Celestial -> world (horizon)
function CtoW(p, wp) {
  wp.x = p.x * c.m0 + p.y * c.m1 + p.z * c.m2;
  wp.y = p.x * c.m3 + p.y * c.m4;
  wp.z = p.x * c.m6 + p.y * c.m7 + p.z * c.m8;
  return wp;
}

// Screen -> "math horizon" (az/alt in radians). Port of p.StoMH.
function StoMH(sp, hp) {
  const M = Math;
  let d = M.sqrt(sp.x * sp.x + sp.y * sp.y) / SPHERE_R;
  if (d > 1) { d = 1; }
  const b = M.asin(d);
  const A = M.atan2(sp.x, -sp.y);
  if (state.phi === HALF_PI) {
    hp.alt = HALF_PI - b;
    hp.az  = state.theta + Math.PI - A;
  } else if (state.phi === -HALF_PI) {
    hp.alt = -HALF_PI + b;
    hp.az  = state.theta + A;
  } else {
    const cc = M.cos(HALF_PI - state.phi);
    const sc = M.sin(HALF_PI - state.phi);
    const cb = M.cos(b);
    const sb = M.sin(b);
    const ca = cb * cc + sb * sc * M.cos(A);
    hp.alt = HALF_PI - M.acos(ca);
    hp.az  = state.theta + M.atan2(sb * M.sin(A), (cb - ca * cc) / sc);
  }
  hp.az = mod(hp.az, TWO_PI);
  return hp;
}

// p.parsePointInput -- accepts {az,alt}, {ra,dec} or {x,y,z,system}
function parsePointInput(p1, p2) {
  if (p1.az !== undefined && p1.alt !== undefined) {
    p2.sys = 0;
    const r = (p1.r !== undefined) ? p1.r : 1;
    const d = r * Math.cos(p1.alt * DEG2RAD);
    p2.x = d * Math.cos(p1.az * DEG2RAD);
    p2.y = d * Math.sin(-p1.az * DEG2RAD);
    p2.z = r * Math.sin(p1.alt * DEG2RAD);
    p2.r = Math.abs(r);
  } else if (p1.ra !== undefined && p1.dec !== undefined) {
    p2.sys = 1;
    const r = (p1.r !== undefined) ? p1.r : 1;
    const d = r * Math.cos(p1.dec * DEG2RAD);
    p2.x = d * Math.cos(p1.ra * HR2RAD);
    p2.y = d * Math.sin(p1.ra * HR2RAD);
    p2.z = r * Math.sin(p1.dec * DEG2RAD);
    p2.r = Math.abs(r);
  } else if (p1.x !== undefined && p1.y !== undefined && p1.z !== undefined) {
    if (p1.system === 'horizon')       { p2.sys = 0; }
    else if (p1.system === 'celestial'){ p2.sys = 1; }
    else                               { p2.sys = -1; }
    p2.x = p1.x; p2.y = p1.y; p2.z = p1.z;
    p2.r = Math.sqrt(p2.x * p2.x + p2.y * p2.y + p2.z * p2.z);
    if (p2.r < 1.000001 && p2.r > 0.999999) { p2.r = 1; }
  } else {
    p2.sys = null; p2.x = null; p2.y = null; p2.z = null; p2.r = null;
  }
  return p2;
}

/* ---------------------------------------------------------------------------
   Circles -- port of CSCirclesClass ("8 CS Circles.as")

   A circle is defined by tilt / lambda / beta in one of the two coordinate
   systems. doW() builds the circle's own basis; update() projects it and
   splits it into the arc in front of the sphere and the arc behind it.
   --------------------------------------------------------------------------- */

function Circle(opts) {
  this.sys   = opts.sys;                 // 0 horizon, 1 celestial
  this.tilt  = (opts.tilt   || 0) * DEG2RAD;
  this.color = opts.color;
  this.thick = opts.thickness;
  this.alpha = opts.alpha;
  this.gS = 0;                           // gammaStart / gammaEnd both default
  this.gE = 0;                           // to 0 -> the full circle is drawn
  this.w = {};

  // setParameters: lambda from dec/alt, beta from ra/az
  if (this.sys === 1) {
    this.lambda = (opts.dec || 0) * DEG2RAD;
    this.beta   = HR2RAD * mod(opts.ra || 0, 24);
  } else {
    this.lambda = (opts.alt || 0) * DEG2RAD;
    this.beta   = DEG2RAD * mod(-(opts.az || 0), 360);
  }
  this.doW();
}

Circle.prototype.doW = function () {
  const st = Math.sin(this.tilt),   ct = Math.cos(this.tilt);
  const sb = Math.sin(this.beta),   cb = Math.cos(this.beta);
  const cl = Math.cos(this.lambda), sl = Math.sin(this.lambda);
  const w = this.w;
  w.w0 =  cl * cb;
  w.w1 = -cl * sb * ct;
  w.w2 =  sl * sb * st;
  w.w3 =  cl * sb;
  w.w4 =  cl * cb * ct;
  w.w5 = -sl * cb * st;
  w.w7 =  cl * st;
  w.w8 =  sl * ct;
};

// Returns { front: [[g1,g2], ...], back: [[g1,g2], ...] } plus the projection
// coefficients v0..v5 needed to draw those arcs.
Circle.prototype.project = function () {
  const w = this.w;
  let v0, v1, v2, v3, v4, v5, v6, v7, v8;

  if (this.sys === 0) {
    v0 = c.a0 * w.w0 + c.a1 * w.w3;
    v1 = c.a0 * w.w1 + c.a1 * w.w4;
    v2 = c.a0 * w.w2 + c.a1 * w.w5;
    v3 = c.a3 * w.w0 + c.a4 * w.w3;
    v4 = c.a3 * w.w1 + c.a4 * w.w4 + c.a5 * w.w7;
    v5 = c.a3 * w.w2 + c.a4 * w.w5 + c.a5 * w.w8;
    v6 = c.a6 * w.w0 + c.a7 * w.w3;
    v7 = c.a6 * w.w1 + c.a7 * w.w4 + c.a8 * w.w7;
    v8 = c.a6 * w.w2 + c.a7 * w.w5 + c.a8 * w.w8;
  } else {
    v0 = c.b0 * w.w0 + c.b1 * w.w3;
    v1 = c.b0 * w.w1 + c.b1 * w.w4 + c.b2 * w.w7;
    v2 = c.b0 * w.w2 + c.b1 * w.w5 + c.b2 * w.w8;
    v3 = c.b3 * w.w0 + c.b4 * w.w3;
    v4 = c.b3 * w.w1 + c.b4 * w.w4 + c.b5 * w.w7;
    v5 = c.b3 * w.w2 + c.b4 * w.w5 + c.b5 * w.w8;
    v6 = c.b6 * w.w0 + c.b7 * w.w3;
    v7 = c.b6 * w.w1 + c.b7 * w.w4 + c.b8 * w.w7;
    v8 = c.b6 * w.w2 + c.b7 * w.w5 + c.b8 * w.w8;
  }

  const front = [], back = [];
  const A = Math.sqrt(v6 * v6 + v7 * v7);

  if (A === 0) {
    // Circle lies in a plane parallel to the screen: entirely front or back.
    (v8 < 0 ? back : front).push([this.gS, this.gE]);
  } else {
    const sj = -v8 / A;
    if (sj <= -1) {
      front.push([this.gS, this.gE]);
    } else if (sj >= 1) {
      back.push([this.gS, this.gE]);
    } else {
      const j = Math.asin(sj);
      const t = Math.atan2(v6, v7);
      let gDesc, gAsc;
      if (Math.cos(j) < 0) {
        gDesc = mod(j - t, TWO_PI);
        gAsc  = mod(Math.PI - j - t, TWO_PI);
      } else {
        gDesc = mod(Math.PI - j - t, TWO_PI);
        gAsc  = mod(j - t, TWO_PI);
      }
      if (this.gS === this.gE) {
        // Full circle: ascending->descending is in front, the rest behind.
        front.push([gAsc, gDesc]);
        back.push([gDesc, gAsc]);
      } else {
        // Partial arc: walk the four boundary angles in order. (Retained for
        // parity with the source; this sim only ever uses full circles.)
        const gArray = [[gAsc, 0], [gDesc, 1], [this.gS, 2], [this.gE, 3]];
        gArray.sort(function (a, b) { return a[0] - b[0]; });
        let draw = false, isFront = true;
        for (let s = 0; s < 4; s++) {
          if (gArray[s][1] === 0)      { isFront = true; }
          else if (gArray[s][1] === 1) { isFront = false; }
          else if (gArray[s][1] === 2) { draw = true; }
          else                         { draw = false; }
        }
        let g2 = gArray[3];
        for (let i = 0; i < 4; i++) {
          const g1 = g2;
          g2 = gArray[i];
          if (draw && g1[0] !== g2[0]) {
            (isFront ? front : back).push([g1[0], g2[0]]);
          }
          if (g2[1] === 0)      { isFront = true; }
          else if (g2[1] === 1) { isFront = false; }
          else if (g2[1] === 2) { draw = true; }
          else                  { draw = false; }
        }
      }
    }
  }

  return { front: front, back: back, v: [v0, v1, v2, v3, v4, v5] };
};

// Port of the local drawArc() inside CSCirclesClass.update -- tessellates the
// ellipse with quadratic curves, exactly as the AS did with curveTo.
function strokeCircleArc(ctx, v, g1, g2) {
  if (g2 < g1) { g2 += TWO_PI; }
  let arc = g2 - g1;
  if (arc === 0) { arc = TWO_PI; }
  const n = Math.ceil(arc / MIN_STEP);
  const step = arc / n;
  const halfStep = step / 2;
  const cRad = 1 / Math.cos(halfStep);
  const v0 = v[0], v1 = v[1], v2 = v[2], v3 = v[3], v4 = v[4], v5 = v[5];

  let ax = Math.cos(g1), ay = Math.sin(g1);
  ctx.moveTo(v0 * ax + v1 * ay + v2, v3 * ax + v4 * ay + v5);

  let aAngle = g1 + step;
  let cAngle = aAngle - halfStep;
  for (let i = 0; i < n; i++) {
    ax = Math.cos(aAngle); ay = Math.sin(aAngle);
    const cx = cRad * Math.cos(cAngle), cy = cRad * Math.sin(cAngle);
    ctx.quadraticCurveTo(
      v0 * cx + v1 * cy + v2, v3 * cx + v4 * cy + v5,
      v0 * ax + v1 * ay + v2, v3 * ax + v4 * ay + v5
    );
    aAngle += step;
    cAngle += step;
  }
}

/* ---------------------------------------------------------------------------
   Lines -- port of CSLinesClass ("9 CS Lines.as")

   A line is split at every crossing of the sphere's surface and of the
   horizon plane, so each piece can be drawn in the correct depth layer:
     bE / fE  outside the sphere, behind / in front
     bI / aI  inside the sphere, below / above the horizon plane
   --------------------------------------------------------------------------- */

function Line(opts) {
  this.color = opts.color;
  this.thick = opts.thickness;
  this.alpha = opts.alpha;
  this.head = parsePointInput(opts.head, {});
  this.tail = parsePointInput(opts.tail, {});
  if (this.head.sys === -1) { this.head.sys = 0; }
  if (this.tail.sys === -1) { this.tail.sys = 0; }
}

// Returns [{ layer:'bE'|'fE'|'bI'|'aI', x1,y1,x2,y2 }, ...]
Line.prototype.segments = function () {
  const head = {}, tail = {};
  (this.head.sys === 0 ? WtoSz : CtoSz)(this.head, head);
  (this.tail.sys === 0 ? WtoSz : CtoSz)(this.tail, tail);

  const mx = head.x - tail.x;
  const my = head.y - tail.y;
  const mz = head.z - tail.z;
  const A = mx * mx + my * my + mz * mz;
  const B = 2 * (mx * tail.x + my * tail.y + mz * tail.z);
  const C = tail.x * tail.x + tail.y * tail.y + tail.z * tail.z;
  const rad2 = SPHERE_R2;
  const phi = state.phi;

  const stmp = [];
  const D = B * B - 4 * A * (C - rad2);
  if (D > 0) {
    const sD = Math.sqrt(D);
    stmp.push((-B + sD) / (2 * A));
    stmp.push((-B - sD) / (2 * A));
  }

  let tp;                              // tan(phi); only defined when |phi| < 90
  if (phi > -HALF_PI && phi < HALF_PI) {
    tp = Math.tan(phi);
    if (my !== tp * mz) {
      stmp.push((tp * tail.z - tail.y) / (my - tp * mz));
    }
    if (mz !== 0) {
      const tmp = -tail.z / mz;
      if (tmp * (tmp * A + B) + C >= rad2) { stmp.push(tmp); }
    }
  } else if (mz !== 0) {
    stmp.push(-tail.z / mz);
  }

  // Insert the split parameters into [0, 1], keeping them sorted and unique.
  const s = [0, 1];
  for (let i = 0; i < stmp.length; i++) {
    if (stmp[i] > 0 && stmp[i] < 1) {
      let k = 1;
      while (stmp[i] > s[k]) { k++; }
      if (stmp[i] !== s[k]) { s.splice(k, 0, stmp[i]); }
    }
  }

  // _showUnder is true throughout this sim, so only that branch is needed.
  const out = [];
  for (let i = 0; i < s.length - 1; i++) {
    const s1 = s[i], s2 = s[i + 1];
    const u = s1 + (s2 - s1) / 2;              // midpoint classifies the piece
    const r2 = u * (u * A + B) + C;
    let layer;
    if (r2 < rad2) {                            // inside the sphere
      if (phi === -HALF_PI) {
        layer = (u * mz + tail.z > 0) ? 'bI' : 'aI';
      } else if (phi === HALF_PI) {
        layer = (u * mz + tail.z > 0) ? 'aI' : 'bI';
      } else if (u * my + tail.y - (u * mz + tail.z) * tp > 1e-9) {
        layer = 'bI';
      } else {
        layer = 'aI';
      }
    } else {                                    // outside the sphere
      layer = (u * mz + tail.z < 0) ? 'bE' : 'fE';
    }
    out.push({
      layer: layer,
      x1: s1 * mx + tail.x, y1: s1 * my + tail.y,
      x2: s2 * mx + tail.x, y2: s2 * my + tail.y
    });
  }
  return out;
};

/* ---------------------------------------------------------------------------
   Positioned objects -- port of CSObjectsClass ("7 CS Objects.as")

   Only two kinds appear in this sim: the stick figure at the centre of the
   sphere ("skewed" orientation) and the individual letters of the declination
   labels ("absolute" orientation).
   --------------------------------------------------------------------------- */

function SphereObject(kind, position, data) {
  this.kind = kind;                    // 'stickman' | 'letter'
  this.data = data || {};
  this.visible = true;
  this.oType = 0;
  this.o = { x: 0, y: 0, z: 0 };
  this.setPosition(position);
}

SphereObject.prototype.setPosition = function (arg) {
  const pt = parsePointInput(arg, {});
  this.sys = pt.sys;
  this.p = pt;
  this.r = pt.r;
};

// setOrientationType("skewed", vector)
SphereObject.prototype.setSkewed = function (vec) {
  this.oType = 1;
  const v = parsePointInput(vec, {});
  const m = Math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z);
  this.o = { x: v.x / m, y: v.y / m, z: v.z / m };
  this.p_o = { x: this.p.x + this.o.x, y: this.p.y + this.o.y, z: this.p.z + this.o.z };
};

// setOrientationType("absolute", n, u)
//
// NOTE ON A SOURCE BUG: the AS passed `leterrsRAs[i]` (a typo for `letterRAs`)
// as the RA of the "up" vector, so that vector evaluated to NaN and the letter
// was never counter-rotated to stand up straight -- leaving only the shell's
// rotation, which tilts each glyph with the sphere's surface normal and spins
// the captions around as the view is dragged.
//
// This port keeps the geometry below (the normal is still what classifies a
// letter as front- or back-facing) but does NOT apply the resulting rotation
// to the glyphs: captions are painted upright. See paintObject().
SphereObject.prototype.setAbsoluteNormal = function (normalVec) {
  this.oType = 2;
  const v1 = parsePointInput(normalVec, {});
  const nm = Math.sqrt(v1.x * v1.x + v1.y * v1.y + v1.z * v1.z);
  this.n = { x: v1.x / nm, y: v1.y / nm, z: v1.z / nm };
  this.p_n = { x: this.p.x + this.n.x, y: this.p.y + this.n.y, z: this.p.z + this.n.z };
};

// Computes screen position, rotation and vertical squash for this object.
// Mirrors CSObjectsClass.update() cases 1 and 2.
SphereObject.prototype.resolve = function () {
  const sp = {}, wp = {};

  if (this.r < 1) {
    // Interior object (the stick figure sits at r = 0).
    if (this.sys === 0) { wp.x = this.p.x; wp.y = this.p.y; wp.z = this.p.z; }
    else                { CtoW(this.p, wp); }
    WtoSz(wp, sp);
    this.region = (wp.z < 0) ? 'bI' : 'aI';
  } else {
    (this.sys === 0 ? WtoSz : CtoSz)(this.p, sp);
    this.region = (sp.z < 0) ? 'bS' : 'fS';
  }
  this.sp = sp;

  if (this.oType === 1) {
    const sp_o = {};
    let opz;
    if (this.sys === 0) {
      opz = this.o.x * c.a6 + this.o.y * c.a7 + this.o.z * c.a8;
      WtoSz(this.p_o, sp_o);
    } else {
      opz = this.o.x * c.b6 + this.o.y * c.b7 + this.o.z * c.b8;
      CtoSz(this.p_o, sp_o);
    }
    this.yScale  = Math.sqrt(1 - (opz * opz) / SPHERE_R2);
    this.rotation = Math.atan2(sp_o.y - sp.y, sp_o.x - sp.x) + Math.PI / 2;
  } else if (this.oType === 2) {
    const sp_n = {};
    let npz;
    if (this.sys === 0) {
      npz = (this.n.x * c.a6 + this.n.y * c.a7 + this.n.z * c.a8) / SPHERE_R;
      WtoSz(this.p_n, sp_n);
    } else {
      npz = (this.n.x * c.b6 + this.n.y * c.b7 + this.n.z * c.b8) / SPHERE_R;
      CtoSz(this.p_n, sp_n);
    }
    this.yScale   = npz;
    this.rotation = Math.atan2(sp_n.y - sp.y, sp_n.x - sp.x) + Math.PI / 2;
  } else {
    this.yScale = 1;
    this.rotation = 0;
  }
};

/* ---------------------------------------------------------------------------
   Declination text -- port of addDeclinationText from the main frame script

   Each label is broken into single letters, spread along a line of constant
   declination, so the text follows the curve of the circle it annotates.
   --------------------------------------------------------------------------- */

let measureCtx = null;
function letterWidth(ch) {
  if (!measureCtx) {
    measureCtx = document.createElement('canvas').getContext('2d');
    measureCtx.font = LETTER_FONT;
  }
  return measureCtx.measureText(ch).width;
}

function makeDeclinationText(str, ra, dec, gap) {
  // r = cos(dec) * (sphere.size / 2)
  const r = Math.cos(dec * DEG2RAD) * SPHERE_R;
  const spacingAngle = gap * letterWidth(' ') / r;
  const letters = str.split('');
  const letterRAs = [];
  let cursorAngle = 0;

  for (let i = 0; i < letters.length; i++) {
    const letterAngle = letterWidth(letters[i]) / r;
    letterRAs[i] = RAD2HR * (cursorAngle + letterAngle / 2);
    cursorAngle = cursorAngle + letterAngle + spacingAngle;
  }
  cursorAngle -= spacingAngle;
  const offset = RAD2HR * (cursorAngle / 2);

  const out = [];
  const northern = state.lat > 0;
  for (let i = 0; i < letters.length; i++) {
    const raI = northern ? (ra + letterRAs[i] - offset)
                         : (ra - letterRAs[i] + offset);
    const obj = new SphereObject('letter', { dec: dec, ra: raI },
                                 { letter: letters[i] });
    // Orientation "absolute": the normal is the letter's own radial direction.
    obj.setAbsoluteNormal({ dec: dec, ra: raI });
    out.push(obj);
  }
  return out;
}

/* ---------------------------------------------------------------------------
   Scene assembly -- mirrors the main frame script's construction order
   --------------------------------------------------------------------------- */

const scene = {
  circles: [],       // { circle, key }
  lines:   [],       // { line, key }
  objects: []        // SphereObject
};

// Labels currently shown, for the screen-reader description
let activeLabels = [];

function buildScene() {
  scene.circles.length = 0;
  scene.lines.length = 0;
  scene.objects.length = 0;
  activeLabels = [];

  // --- always present -----------------------------------------------------
  // sphere.addObject("Stickman","stickman",{x:0,y:0,z:0,system:"horizon"})
  // sphere.stickman.setOrientationType("skewed",{alt:90,az:0})
  const stickman = new SphereObject('stickman',
    { x: 0, y: 0, z: 0, system: 'horizon' });
  stickman.setSkewed({ alt: 90, az: 0 });
  scene.objects.push(stickman);

  // Two faint meridian circles (thickness 1, white, alpha 20)
  scene.circles.push({ key: 'meridian1', circle: new Circle({
    sys: 1, ra: 0, dec: 0, tilt: 90,
    thickness: 1, color: COLOR_MERIDIAN, alpha: 20 }) });
  scene.circles.push({ key: 'meridian2', circle: new Circle({
    sys: 1, ra: 6, dec: 0, tilt: 90,
    thickness: 1, color: COLOR_MERIDIAN, alpha: 20 }) });

  // --- Step 1: Show Poles -------------------------------------------------
  if (state.showPoles) {
    scene.lines.push({ key: 'ncpAxis', line: new Line({
      thickness: 3, color: COLOR_POLE_AXIS, alpha: 100,
      head: { x: 0, y: 0, z: 0,   system: 'celestial' },
      tail: { x: 0, y: 0, z: 1.2, system: 'celestial' } }) });
    scene.lines.push({ key: 'scpAxis', line: new Line({
      thickness: 3, color: COLOR_POLE_AXIS, alpha: 100,
      head: { x: 0, y: 0, z: 0,    system: 'celestial' },
      tail: { x: 0, y: 0, z: -1.2, system: 'celestial' } }) });

    // addDeclinationText(4..7, "NCP"/"SCP", ra 0 and 12, dec +/-85, gap 0.5)
    pushLabel('NCP', 0,  85, 0.5);
    pushLabel('NCP', 12, 85, 0.5);
    pushLabel('SCP', 0,  -85, 0.5);
    pushLabel('SCP', 12, -85, 0.5);
  }

  // --- Step 2: Show CE ----------------------------------------------------
  if (state.showCE) {
    scene.circles.push({ key: 'celestialEquator', circle: new Circle({
      sys: 1, ra: 0, dec: 0, tilt: 0,
      thickness: 3, color: COLOR_CELESTIAL_EQUATOR, alpha: 100 }) });
  }

  // --- Step 3: Show Equinox Path ------------------------------------------
  if (state.showEquinox) {
    scene.circles.push({ key: 'equinoxPath', circle: new Circle({
      sys: 1, ra: 0, dec: 0, tilt: 0,
      thickness: 3, color: COLOR_SUN_PATH, alpha: 100 }) });
  }

  // The "Celestial Equator" and "Equinox Path" captions occupy the same spot
  // on the sphere (ra 0, dec 0.7), so the original showed only one at a time:
  // Step 3's caption wins while it is on, otherwise Step 2's is restored.
  if (state.showEquinox) {
    pushLabel('Equinox Path', 0, 0.7, 0.5);
  } else if (state.showCE) {
    pushLabel('Celestial Equator', 0, 0.7, 0.5);
  }

  // --- Step 4: Show Solstice Paths ----------------------------------------
  if (state.showSolstice) {
    scene.circles.push({ key: 'sSolsticePath', circle: new Circle({
      sys: 1, ra: 0, dec: DEC_SUMMER_SOLSTICE, tilt: 0,
      thickness: 3, color: COLOR_SUN_PATH, alpha: 100 }) });
    scene.circles.push({ key: 'wSolsticePath', circle: new Circle({
      sys: 1, ra: 0, dec: DEC_WINTER_SOLSTICE, tilt: 0,
      thickness: 3, color: COLOR_SUN_PATH, alpha: 100 }) });
    pushLabel('Summer Solstice Path', 0, DEC_SUMMER_SOLSTICE, 0.5);
    pushLabel('Winter Solstice Path', 0, DEC_WINTER_SOLSTICE, 0.5);
  }
}

function pushLabel(text, ra, dec, gap) {
  const letters = makeDeclinationText(text, ra, dec, gap);
  for (let i = 0; i < letters.length; i++) { scene.objects.push(letters[i]); }
  if (activeLabels.indexOf(text) === -1) { activeLabels.push(text); }
}

/* ---------------------------------------------------------------------------
   Reused exported artwork (shapes/*.svg from the JPEXS export)

   These are drawn with drawImage at their original position and size; they
   are never redrawn by hand.
   --------------------------------------------------------------------------- */

const ART = {
  // chid 24 "CSAboveHorizonPlane" -- green gradient, 199.95 x 200, origin (99.95, 100)
  aboveHorizon: { src: 'assets/shapes/23.svg', w: 199.95, h: 200, ox: 99.95, oy: 100 },
  // chid 22 "CSBelowHorizonPlane" -- flat #006600
  belowHorizon: { src: 'assets/shapes/21.svg', w: 199.95, h: 200, ox: 99.95, oy: 100 },
  // chid 68 "sphere outside"  -- grey radial gradient on the front inner surface
  sphereOutside:  { src: 'assets/shapes/67.svg', w: 200, h: 200, ox: 100, oy: 100 },
  // chid 66 "sphere outside2" -- dark radial gradient below the horizon
  sphereOutside2: { src: 'assets/shapes/65.svg', w: 200, h: 200, ox: 100, oy: 100 },
  // chid 60 "Stickman" -> shape 59, 9.2 x 21.65, origin (4.6, 20.65)
  stickman: { src: 'assets/shapes/59.svg', w: 9.2, h: 21.65, ox: 4.6, oy: 20.65 }
};

let artReady = false;

function loadArt() {
  const keys = Object.keys(ART);
  let pending = keys.length;
  return new Promise(function (resolve) {
    keys.forEach(function (k) {
      const img = new Image();
      img.decoding = 'sync';
      img.onload = img.onerror = function () {
        ART[k].img = img;
        if (--pending === 0) { artReady = true; resolve(); }
      };
      img.src = ART[k].src;
    });
  });
}

function drawArt(ctx, spec) {
  if (!spec.img || !spec.img.complete || !spec.img.naturalWidth) { return; }
  ctx.drawImage(spec.img, -spec.ox, -spec.oy, spec.w, spec.h);
}

/* ---------------------------------------------------------------------------
   Masks -- port of updateMasks from "6 CS Shading.as"

   Only mask M2 is actually consumed by this sim (it clips the "sphere
   outside2" shading to the region below the front half of the horizon
   ellipse). The base geometry is in 100-unit space and is scaled by _c.r/100.
   --------------------------------------------------------------------------- */

function clipMaskM2(ctx) {
  const scale = SPHERE_R / 100;          // _M2._xscale = _M2._yscale = _c.r
  const r = MASK_R, d = MASK_D;
  const step = Math.PI / MASK_HALF_N;
  const halfStep = step / 2;
  const cRad = r / Math.cos(halfStep);
  const s = Math.sin(state.phi);

  ctx.save();
  ctx.scale(scale, scale);
  ctx.beginPath();
  ctx.moveTo(d, d);
  ctx.lineTo(d, 0);
  ctx.lineTo(r, 0);
  let aAngle = step, cAngle = aAngle - halfStep;
  for (let i = 0; i < MASK_HALF_N; i++) {
    ctx.quadraticCurveTo(
      cRad * Math.cos(cAngle), s * cRad * Math.sin(cAngle),
      r * Math.cos(aAngle),    s * r * Math.sin(aAngle)
    );
    aAngle += step;
    cAngle += step;
  }
  ctx.lineTo(-d, 0);
  ctx.lineTo(-d, d);
  ctx.lineTo(d, d);
  ctx.closePath();
  ctx.restore();
  ctx.clip();
}

/* ---------------------------------------------------------------------------
   The canvas
   --------------------------------------------------------------------------- */

const canvas = document.getElementById('sim-canvas');
const ctx = canvas.getContext('2d');

// Sets the backing-store resolution from the element's CSS size and the device
// pixel ratio, then installs a transform so that ALL drawing code below works
// in the original Flash sphere coordinates (origin at the sphere centre).
let stageScale = 1;

// The element's height is left to CSS (height:auto), which derives it from the
// backing store's intrinsic ratio. Setting it here too would fight the CSS and
// skew the stage whenever the two disagreed.
function sizeCanvas() {
  const cssW = canvas.clientWidth || STAGE_W;
  const dpr = window.devicePixelRatio || 1;
  stageScale = cssW / STAGE_W;

  const bw = Math.max(1, Math.round(cssW * dpr));
  const bh = Math.max(1, Math.round(cssW * (STAGE_H / STAGE_W) * dpr));
  if (canvas.width !== bw || canvas.height !== bh) {
    canvas.width  = bw;
    canvas.height = bh;
  }
}

function applyStageTransform() {
  const dpr = window.devicePixelRatio || 1;
  const k = stageScale * dpr;
  ctx.setTransform(k, 0, 0, k, STAGE_CX * k, STAGE_CY * k);
}

/* --- painting ------------------------------------------------------------- */

function strokeSegments(ctx, segs, want, line) {
  let started = false;
  for (let i = 0; i < segs.length; i++) {
    if (segs[i].layer !== want) { continue; }
    if (!started) {
      ctx.beginPath();
      ctx.lineWidth = line.thick;
      ctx.strokeStyle = rgba(line.color, line.alpha);
      started = true;
    }
    ctx.moveTo(segs[i].x1, segs[i].y1);
    ctx.lineTo(segs[i].x2, segs[i].y2);
  }
  if (started) { ctx.stroke(); }
}

function paintLineLayer(ctx, cache, want) {
  for (let i = 0; i < cache.length; i++) {
    strokeSegments(ctx, cache[i].segs, want, cache[i].line);
  }
}

function paintCircleLayer(ctx, cache, side) {
  for (let i = 0; i < cache.length; i++) {
    const entry = cache[i];
    const arcs = entry.proj[side];
    if (!arcs.length) { continue; }
    ctx.beginPath();
    ctx.lineWidth = entry.circle.thick;
    ctx.strokeStyle = rgba(entry.circle.color, entry.circle.alpha);
    for (let a = 0; a < arcs.length; a++) {
      strokeCircleArc(ctx, entry.proj.v, arcs[a][0], arcs[a][1]);
    }
    ctx.stroke();
  }
}

function paintObject(ctx, obj) {
  ctx.save();
  ctx.translate(obj.sp.x, obj.sp.y);

  if (obj.kind === 'stickman') {
    ctx.rotate(obj.rotation);
    // A negative y-scale is a genuine vertical flip in the original, and canvas
    // reproduces it; guard only against an exact zero, which is not invertible.
    const ys = (obj.yScale === 0) ? 1e-6 : obj.yScale;
    ctx.scale(1, ys);
    drawArt(ctx, ART.stickman);
  } else {
    // Caption letters are drawn UPRIGHT: positioned on the sphere, but never
    // rotated or squashed with it. Each letter still sits at its own point
    // along the line of constant declination, so the caption follows the
    // circle it annotates and travels with the sphere as the view turns --
    // but the glyphs stay level and readable instead of spinning, tilting or
    // mirroring. See the "static captions" note in CONVERSION_NOTES.md.
    ctx.font = LETTER_FONT;
    ctx.fillStyle = LETTER_COLOR;
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText(obj.data.letter, 0, 0);
  }
  ctx.restore();
}

function paintObjectsIn(ctx, region) {
  for (let i = 0; i < scene.objects.length; i++) {
    const obj = scene.objects[i];
    if (obj.visible && obj.region === region) { paintObject(ctx, obj); }
  }
}

// The horizon plane clip: _hP is scaled by (_c.r, _c.r * sin(phi)) as a
// percentage of the 100-unit base art, and the visible half is rotated by
// 180 + theta degrees. Only one half is visible at a time.
const DIRECTION_LABELS = [
  { ch: 'N', x: -5.15, y: -92.3 },
  { ch: 'S', x: -4.35, y:  76.7 },
  { ch: 'E', x: 79.15, y:  -7.25 },
  { ch: 'W', x: -89.8, y:  -7.25 }
];

function paintHorizonPlane(ctx) {
  const sx = SPHERE_R / 100;
  const sy = (SPHERE_R * Math.sin(state.phi)) / 100;
  if (sy === 0) { return; }              // edge-on: nothing to show

  const above = state.phi > 0;
  const A = Math.PI + state.theta;       // 180 + theta, in radians

  ctx.save();
  ctx.scale(sx, sy);
  ctx.rotate(A);
  drawArt(ctx, above ? ART.aboveHorizon : ART.belowHorizon);
  ctx.restore();

  // The N/S/E/W markers keep their PLACE on the plane -- north stays at the
  // horizon's north point and swings round as the view turns -- but the glyphs
  // themselves are painted upright rather than being rotated and squashed flat
  // with the plane. Riding the plane transform would mirror them at half the
  // viewing angles, which made them unreadable. The plane transform is applied
  // to the anchor point by hand so only the position, not the glyph, inherits
  // it.
  const cosA = Math.cos(A), sinA = Math.sin(A);
  ctx.save();
  ctx.font = LETTER_FONT;
  ctx.fillStyle = above ? '#ffffff' : '#999999';
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  for (let i = 0; i < DIRECTION_LABELS.length; i++) {
    const L = DIRECTION_LABELS[i];
    const rx = L.x * cosA - L.y * sinA;
    const ry = L.x * sinA + L.y * cosA;
    ctx.fillText(L.ch, sx * rx, sy * ry);
  }
  ctx.restore();
}

// CSGradientDisk "celestialBowl": innerColor white at alpha 0 -> outerColor
// black at alpha 20, filling the disk on the front inner surface.
function paintCelestialBowl(ctx) {
  const scale = SPHERE_R / 100;
  ctx.save();
  ctx.scale(scale, scale);
  const g = ctx.createRadialGradient(0, 0, 0, 0, 0, 100);
  g.addColorStop(0, 'rgba(255,255,255,0)');
  g.addColorStop(1, 'rgba(0,0,0,0.2)');
  ctx.fillStyle = g;
  ctx.beginPath();
  ctx.arc(0, 0, 100, 0, TWO_PI);
  ctx.fill();
  ctx.restore();
}

function paintShadingScaled(ctx, spec) {
  const scale = SPHERE_R / 100;          // _fISF._xscale = _fISF._yscale = _c.r
  ctx.save();
  ctx.scale(scale, scale);
  drawArt(ctx, spec);
  ctx.restore();
}

/* ---------------------------------------------------------------------------
   render() -- the single place that redraws everything from state
   --------------------------------------------------------------------------- */

function render() {
  // Re-derive the backing size every frame. sizeCanvas only touches the canvas
  // when the size actually changed, so this is cheap, and it means the stage
  // can never be left drawing at a stale scale if a resize notification is
  // missed or coalesced by the browser.
  sizeCanvas();
  updateMatrices();

  // Resolve every scene item once, then paint in Flash depth order.
  const lineCache = scene.lines.map(function (e) {
    return { line: e.line, segs: e.line.segments() };
  });
  const circleCache = scene.circles.map(function (e) {
    return { circle: e.circle, proj: e.circle.project() };
  });
  for (let i = 0; i < scene.objects.length; i++) { scene.objects[i].resolve(); }

  ctx.setTransform(1, 0, 0, 1, 0, 0);
  ctx.clearRect(0, 0, canvas.width, canvas.height);
  applyStageTransform();
  ctx.lineCap = 'round';

  // When the viewer is below the horizon plane the inner-line layers swap
  // depths (_iLA.swapDepths(3N-2) in setPhi), so the plane covers the other
  // set of segments.
  const innerFirst  = (state.phi < 0) ? 'aI' : 'bI';
  const innerSecond = (state.phi < 0) ? 'bI' : 'aI';

  //  1. _bEL   external lines behind the sphere
  paintLineLayer(ctx, lineCache, 'bE');
  //  2. _bC    back halves of the circles
  paintCircleLayer(ctx, circleCache, 'back');
  //  3. objects on the back surface
  paintObjectsIn(ctx, 'bS');
  //  4. _iLB   interior lines on the far side of the horizon plane
  paintLineLayer(ctx, lineCache, innerFirst);
  //  5. _hP    the horizon plane itself
  paintHorizonPlane(ctx);
  //  6. interior objects on the near side of the plane (the stick figure)
  paintObjectsIn(ctx, (state.phi < 0) ? 'bI' : 'aI');
  //  7. _iLA   interior lines on the near side of the plane
  paintLineLayer(ctx, lineCache, innerSecond);
  //  8. _fISF  front inner shading: celestial bowl, then "sphere outside"
  paintCelestialBowl(ctx);
  paintShadingScaled(ctx, ART.sphereOutside);
  //  9. _fC    front halves of the circles
  paintCircleLayer(ctx, circleCache, 'front');
  // 10. objects on the front surface
  paintObjectsIn(ctx, 'fS');
  // 11. _fOSB  "sphere outside2", clipped to mask M2
  ctx.save();
  clipMaskM2(ctx);
  paintShadingScaled(ctx, ART.sphereOutside2);
  ctx.restore();
  // 12. _fEL   external lines in front of the sphere
  paintLineLayer(ctx, lineCache, 'fE');

  syncDom();
}

/* ---------------------------------------------------------------------------
   DOM: controls, readouts, screen-reader narration
   --------------------------------------------------------------------------- */

const el = {
  latSlider:   document.getElementById('latitude-slider'),
  latNumber:   document.getElementById('latitude-number'),
  latReadout:  document.getElementById('latitude-readout'),
  latReadoutSr:document.getElementById('latitude-readout-sr'),
  latMin:      document.getElementById('latitude-min'),
  latMax:      document.getElementById('latitude-max'),
  viewProxy:   document.getElementById('sphere-view'),
  status:      document.getElementById('sim-status'),
  canvasDesc:  document.getElementById('canvas-description'),
  step1: document.getElementById('step-1'),
  step2: document.getElementById('step-2'),
  step3: document.getElementById('step-3'),
  step4: document.getElementById('step-4')
};

/* --- number formatting, ported from SliderV3LatitudeClass ----------------- */

// SliderV3Latitude was created with initPrecision = 1, so the value is
// rounded to one decimal place and rendered with exactly one decimal.
const LAT_PRECISION = 1;

function latToFixed(x) {
  const f = LAT_PRECISION;
  let s = '';
  if (x < 0) { s = '-'; x = -x; }
  let m;
  const n = Math.round(x * Math.pow(10, f));
  m = (n === 0) ? '0' : n.toString();
  let k = m.length;
  if (k <= f) {
    let z = '';
    for (let i = 0; i < f + 1 - k; i++) { z += '0'; }
    m = z + m;
    k = f + 1;
  }
  m = m.substr(0, k - f) + '.' + m.substr(k - f);
  return s + m;
}

// The slider label reads e.g. "41.0° N" / "5.0° S" -- the hemisphere letter
// carries the sign, exactly as SliderV3LatitudeClass.setValue did.
function latHemisphere(v) { return v < 0 ? '° S' : '° N'; }
function latText(v)       { return latToFixed(Math.abs(v)) + latHemisphere(v); }

// Spoken form: quantity name + number + unit, never a bare number.
function latSpoken(v) {
  const hemi = v < 0 ? 'south' : 'north';
  return 'Latitude ' + latToFixed(Math.abs(v)) + ' degrees ' + hemi;
}

/* --- MathJax readouts ----------------------------------------------------- */

// Every piece of mathematical notation shown in the page (the degree symbol,
// the signed declinations, the latitude value) is typeset by MathJax so that
// it is exposed through MathJax's own accessibility layer and context menu.
function typesetLatitude() {
  const v = latValue();
  klunlShowEquation(
    ['latitude-readout', '\\(' + latToFixed(Math.abs(v)) + '^\\circ\\,\\mathrm{' +
      (v < 0 ? 'S' : 'N') + '}\\)'],
    ['latitude-readout-sr', latSpoken(v)]
  );
}

/* Keeping MathJax out of the tab order.

   With the contextual menu enabled MathJax marks every <mjx-container> with
   tabindex="0", which would put display-only math into the keyboard tab
   order. Typeset math is output the user reads, not a control, so we force
   tabindex="-1" instead. Right-clicking still opens the MathJax menu, because
   the contextmenu handler is left untouched. */
function suppressMathTabstops() {
  document.querySelectorAll('mjx-container[tabindex]').forEach(function (c) {
    if (c.getAttribute('tabindex') !== '-1') { c.setAttribute('tabindex', '-1'); }
  });
}

const mathObserver = new MutationObserver(suppressMathTabstops);
mathObserver.observe(document.body, {
  childList: true, subtree: true,
  attributes: true, attributeFilter: ['tabindex']
});

/* --- state <-> DOM -------------------------------------------------------- */

function latValue() { return state.lat * RAD2DEG; }

// setLatitude clamps to [-90, 90] and the slider rounds to the precision.
function setLatitude(deg) {
  const k = Math.pow(10, LAT_PRECISION);
  let v = Math.round(k * deg) / k;
  if (v < -90) { v = -90; } else if (v > 90) { v = 90; }
  state.lat = v * DEG2RAD;
  // The declination labels are laid out differently in the two hemispheres,
  // so they must be rebuilt whenever latitude crosses the equator.
  buildScene();
  render();
}

// setThetaAndPhi from "2 CS Getter Setter.as", including the phi clamp.
function setThetaAndPhi(thetaDeg, phiDeg) {
  state.theta = DEG2RAD * mod(thetaDeg, 360);
  if (phiDeg > MAX_PHI)      { phiDeg = MAX_PHI; }
  else if (phiDeg < MIN_PHI) { phiDeg = MIN_PHI; }
  state.phi = phiDeg * DEG2RAD;
  render();
}

function viewerAzimuth()  { return mod(360 - state.theta * RAD2DEG, 360); }
function viewerAltitude() { return state.phi * RAD2DEG; }

function syncDom() {
  const v = latValue();
  if (document.activeElement !== el.latSlider) { el.latSlider.value = v; }
  if (document.activeElement !== el.latNumber) { el.latNumber.value = latToFixed(v); }
  el.latSlider.setAttribute('aria-valuetext', latSpoken(v));
  el.latNumber.setAttribute('aria-label', latSpoken(v));

  el.step1.checked = state.showPoles;
  el.step2.checked = state.showCE;
  el.step3.checked = state.showEquinox;
  el.step4.checked = state.showSolstice;

  const az = viewerAzimuth(), alt = viewerAltitude();
  el.viewProxy.setAttribute('aria-valuenow', Math.round(az));
  el.viewProxy.setAttribute('aria-valuetext',
    'Viewing direction: azimuth ' + Math.round(az) + ' degrees, ' +
    'viewing altitude ' + Math.round(alt) + ' degrees');

  el.canvasDesc.textContent = describeScene();
}

// A concise, continuously-updated description of what the canvas shows, so an
// audio-only user gets the same "what's happening" a sighted user does.
function describeScene() {
  const v = latValue();
  const parts = [];
  parts.push('Celestial sphere seen from ' + latToFixed(Math.abs(v)) +
             ' degrees ' + (v < 0 ? 'south' : 'north') + ' latitude, ' +
             'looking toward azimuth ' + Math.round(viewerAzimuth()) +
             ' degrees from a viewing altitude of ' +
             Math.round(viewerAltitude()) + ' degrees.');
  parts.push('A stick figure stands at the centre, on the green horizon plane, ' +
             'with north, south, east and west marked around its edge.');

  const shown = [];
  if (state.showPoles) {
    shown.push('the axis through the north and south celestial poles, ' +
               'labelled N C P and S C P');
  }
  if (state.showCE)      { shown.push('the celestial equator'); }
  if (state.showEquinox) { shown.push('the sun’s path on the equinoxes, ' +
                                      'at declination 0 degrees'); }
  if (state.showSolstice) {
    shown.push('the sun’s paths on the summer and winter solstices, ' +
               'at declinations plus 23.5 degrees and minus 23.5 degrees');
  }
  parts.push(shown.length
    ? 'Also shown: ' + shown.join('; ') + '.'
    : 'No sun paths are shown yet. Turn on the four steps to build up the picture.');
  return parts.join(' ');
}

// aria-live announcements are made on commit (release / change), never per
// tick, so the region is not flooded during a drag.
let lastAnnouncement = '';
function announce(msg) {
  if (msg === lastAnnouncement) { msg += ' '; }   // force re-announcement
  lastAnnouncement = msg;
  el.status.textContent = msg;
}

/* ---------------------------------------------------------------------------
   Pointer drag on the sphere -- port of startSimpleDragging / updateSimpleDragging
   --------------------------------------------------------------------------- */

let drag = null;

// Maps a pointer event to the sphere's own coordinate system, undoing the
// CSS scale so the drag math below matches the ActionScript at any size.
function pointerToStage(evt) {
  const rect = canvas.getBoundingClientRect();
  const scale = rect.width / STAGE_W;
  return {
    x: (evt.clientX - rect.left) / scale - STAGE_CX,
    y: (evt.clientY - rect.top) / scale - STAGE_CY
  };
}

canvas.addEventListener('pointerdown', function (evt) {
  const p = pointerToStage(evt);
  drag = {
    id: evt.pointerId,
    xMouse: p.x, yMouse: p.y,
    theta: state.theta, phi: state.phi
  };
  canvas.setPointerCapture(evt.pointerId);
  // Clicking the sphere also focuses it, so the arrow keys work immediately.
  el.viewProxy.focus();
  evt.preventDefault();
});

canvas.addEventListener('pointermove', function (evt) {
  if (!drag || evt.pointerId !== drag.id) { return; }
  const p = pointerToStage(evt);
  setThetaAndPhi(
    RAD2DEG * (drag.theta - (p.x - drag.xMouse) / SPHERE_R),
    RAD2DEG * (drag.phi   + (p.y - drag.yMouse) / SPHERE_R)
  );
  evt.preventDefault();
});

function endDrag(evt) {
  if (!drag || (evt && evt.pointerId !== drag.id)) { return; }
  drag = null;
  announce('Viewing direction: azimuth ' + Math.round(viewerAzimuth()) +
           ' degrees, viewing altitude ' + Math.round(viewerAltitude()) +
           ' degrees.');
}
canvas.addEventListener('pointerup', endDrag);
canvas.addEventListener('pointercancel', endDrag);

/* --- keyboard equivalent for the drag ------------------------------------- */

const VIEW_STEP = 5;        // degrees per arrow press
const VIEW_STEP_BIG = 15;   // degrees per Page press

el.viewProxy.addEventListener('keydown', function (evt) {
  let dAz = 0, dAlt = 0, handled = true;
  const big = evt.shiftKey ? VIEW_STEP_BIG : VIEW_STEP;

  switch (evt.key) {
    case 'ArrowLeft':  dAz = -big; break;
    case 'ArrowRight': dAz =  big; break;
    case 'ArrowUp':    dAlt =  big; break;
    case 'ArrowDown':  dAlt = -big; break;
    case 'PageUp':     dAlt =  VIEW_STEP_BIG; break;
    case 'PageDown':   dAlt = -VIEW_STEP_BIG; break;
    case 'Home':       dAlt = MAX_PHI - viewerAltitude(); break;
    case 'End':        dAlt = MIN_PHI - viewerAltitude(); break;
    default: handled = false;
  }
  if (!handled) { return; }
  evt.preventDefault();

  setThetaAndPhi(
    mod(360 - (viewerAzimuth() + dAz), 360),
    viewerAltitude() + dAlt
  );
  announce('Azimuth ' + Math.round(viewerAzimuth()) + ' degrees, ' +
           'viewing altitude ' + Math.round(viewerAltitude()) + ' degrees.');
});

/* ---------------------------------------------------------------------------
   Latitude controls -- slider and number field share one state path
   --------------------------------------------------------------------------- */

const LAT_STEP = 0.1;       // matches initPrecision = 1
const LAT_PAGE = 5;

function commitLatitude(v, speak) {
  setLatitude(v);
  typesetLatitude();
  if (speak) { announce(latSpoken(latValue()) + '.'); }
}

el.latSlider.addEventListener('input', function () {
  setLatitude(parseFloat(el.latSlider.value));
  typesetLatitude();
});
el.latSlider.addEventListener('change', function () {
  commitLatitude(parseFloat(el.latSlider.value), true);
});

el.latNumber.addEventListener('input', function () {
  const v = parseFloat(el.latNumber.value);
  if (isFinite(v)) { setLatitude(v); typesetLatitude(); }
});
el.latNumber.addEventListener('change', function () {
  const v = parseFloat(el.latNumber.value);
  commitLatitude(isFinite(v) ? v : latValue(), true);
});

// Mouse wheel adjusts the focused numeric field, per the accessibility rules.
// The listener is non-passive so preventDefault can stop the page scrolling,
// and it only acts while the field actually has focus.
el.latNumber.addEventListener('wheel', function (evt) {
  if (document.activeElement !== el.latNumber) { return; }
  evt.preventDefault();
  const dir = evt.deltaY < 0 ? 1 : -1;
  commitLatitude(latValue() + dir * LAT_STEP, true);
}, { passive: false });

el.latSlider.addEventListener('wheel', function (evt) {
  if (document.activeElement !== el.latSlider) { return; }
  evt.preventDefault();
  const dir = evt.deltaY < 0 ? 1 : -1;
  commitLatitude(latValue() + dir * LAT_STEP, true);
}, { passive: false });

// <input type="number"> gives ArrowUp/ArrowDown for free; add Page/Home/End.
el.latNumber.addEventListener('keydown', function (evt) {
  let v = null;
  if (evt.key === 'PageUp')        { v = latValue() + LAT_PAGE; }
  else if (evt.key === 'PageDown') { v = latValue() - LAT_PAGE; }
  else if (evt.key === 'Home')     { v = -90; }
  else if (evt.key === 'End')      { v = 90; }
  if (v === null) { return; }
  evt.preventDefault();
  commitLatitude(v, true);
});

/* --- the four step checkboxes --------------------------------------------- */

// Labels are verbatim from the FCheckBox initialize handlers.
const STEPS = [
  { el: 'step1', flag: 'showPoles',    label: 'Step 1: Show Poles' },
  { el: 'step2', flag: 'showCE',       label: 'Step 2: Show CE' },
  { el: 'step3', flag: 'showEquinox',  label: 'Step 3: Show Equinox Path' },
  { el: 'step4', flag: 'showSolstice', label: 'Step 4: Show Solstice Paths' }
];

STEPS.forEach(function (step) {
  el[step.el].addEventListener('change', function () {
    state[step.flag] = el[step.el].checked;
    buildScene();
    render();
    announce(step.label + ' ' + (el[step.el].checked ? 'shown.' : 'hidden.') +
             ' ' + describeScene());
  });
});

/* ---------------------------------------------------------------------------
   Reset -- driven by the shared masthead's "sim-reset" event
   --------------------------------------------------------------------------- */

function resetSim() {
  state.theta = mod(360 - INIT_VIEWER_AZIMUTH, 360) * DEG2RAD;
  state.phi   = INIT_VIEWER_ALTITUDE * DEG2RAD;
  state.lat   = INIT_LATITUDE * DEG2RAD;
  state.sTime = 0;
  state.showPoles = false;
  state.showCE = false;
  state.showEquinox = false;
  state.showSolstice = false;

  buildScene();
  render();
  typesetLatitude();
  announce('Simulation reset. ' + describeScene());
}

document.addEventListener('sim-reset', resetSim);

/* ---------------------------------------------------------------------------
   Start-up
   --------------------------------------------------------------------------- */

// Redefining klunlInitEqn is the documented KL-UNL hook for initialising a
// sim's equations and components; kl-unl.js ships a placeholder for it.
window.klunlInitEqn = function () {
  typesetLatitude();
  suppressMathTabstops();
};

// A ResizeObserver on the canvas catches every reason its box can change --
// window resize, browser zoom, and the panel reflowing at a breakpoint --
// which a window resize listener alone would miss.
let resizeRaf = 0;
function scheduleResize() {
  if (resizeRaf) { return; }
  resizeRaf = window.requestAnimationFrame(function () {
    resizeRaf = 0;
    sizeCanvas();
    render();
  });
}

// Observe the wrapper, not the canvas: the wrapper's size is purely CSS-driven,
// whereas the canvas's own height follows its backing store, which sizeCanvas
// writes to -- observing that would feed back into itself.
if (window.ResizeObserver) {
  new ResizeObserver(scheduleResize).observe(canvas.parentNode);
}
window.addEventListener('resize', scheduleResize);

// Safety net. Both notifications above are the fast path, but either can be
// coalesced or missed (some embedding contexts deliver neither), which would
// leave the stage drawn at a stale scale until the next user action. A slow
// poll that compares one integer and only redraws on a real change closes that
// gap at negligible cost.
// It redraws synchronously rather than through scheduleResize, because
// requestAnimationFrame does not fire while a document is hidden -- exactly the
// case where the fast paths are also asleep -- and the poll is already
// rate-limited, so there is nothing for a frame callback to coalesce.
let lastSeenWidth = canvas.clientWidth;
window.setInterval(function () {
  const w = canvas.clientWidth;
  if (w && w !== lastSeenWidth) {
    lastSeenWidth = w;
    render();
  }
}, 500);

let booted = false;
function boot() {
  if (booted) { return; }
  booted = true;

  buildScene();
  sizeCanvas();
  render();
  window.klunlInitEqn();

  // Exported artwork arrives asynchronously; repaint once it is decoded.
  loadArt().then(function () {
    sizeCanvas();
    render();
  });
}

// Boot once MathJax has started up, so the readouts typeset on first paint.
if (window.MathJax && window.MathJax.startup && window.MathJax.startup.promise) {
  window.MathJax.startup.promise.then(boot, boot);
} else if (document.readyState !== 'loading') {
  boot();
} else {
  document.addEventListener('DOMContentLoaded', boot);
}
