// Planting Cup
// A small seedling pot with drainage holes, and a deep saucer to catch the
// water that runs out.
//
//  - Thin straight walls, small rounded foot, and a gently wavy rim
//  - Floor holes scattered around a center hole
//  - Side holes scattered over the lower half of the wall, jittered so they
//    look random but never crowd each other
//  - Side holes have pointed tops so they print round without supports
//  - The saucer has a sunken well the cup seats into, a softly rounded
//    (convex) inner face, and a wavy rim to match the cup
//
// Printing: both pieces are laid out side by side, upright, ready to slice.
// No supports needed.

/* [Color] */
print_color = "#EFE6D2"; // beige / off-white

/* [Export] */
part = "both";     // Which piece to render [both, cup, saucer]

/* [Size] */
rim_d = 45;       // Diameter across the top [30:120]
height = 56;      // How tall it stands [40:160]
taper = 0;        // How much narrower the base is [0:30]

/* [Details] */
wall = 1.6;        // Wall thickness [1.2:0.1:5]
floor_t = 2.5;     // Floor thickness [2:0.5:8]
foot_r = 0.8;      // Rounding at the bottom edge [0:0.2:4]

/* [Wavy rim] */
lip_waves = 8;        // Waves around the cup rim [0:16]
lip_amp = 1.2;        // How far the cup rim rises and dips [0:0.1:4]
saucer_waves = 12;    // Waves around the saucer rim [0:24]
saucer_amp = 1;       // How far the saucer rim rises and dips [0:0.1:4]

/* [Holes] */
hole_d = 2.5;      // Drainage hole size [1.5:0.5:10]
hole_count = 10;   // Holes in the outer floor ring [3:16]
inner_count = 5;   // Holes in the inner floor ring [0:10]
side_count = 16;   // Side holes in each ring [6:24]
side_z = 6;        // How high the lowest ring sits [5:0.5:14]
side_top = 0.5;    // How far up the wall the holes reach, as a fraction of height [0.2:0.05:0.8]
row_gap = 5;       // Vertical gap between rings [3.5:0.5:10]
jitter = 0.3;      // How far each hole wanders from a neat grid [0:0.05:0.4]
seed = 7;          // Change for a different random hole pattern

/* [Saucer] */
saucer_d = 68;      // How wide the saucer is [50:140]
saucer_h = 16;      // How tall the saucer rim stands [6:0.5:35]
well_depth = 1.5;   // How deep the cup sits into it [1:0.5:5]
saucer_curve = 1.2; // How far the inner face bulges (negative = bowl) [-3:0.1:3]

$fn = 64;
sweep_steps = 192;  // Smoothness of the wavy pieces around the circle

base_d = rim_d - taper;
core_r = 4;         // the swept body stops here; a plain disc fills the center

// Outer radius of the cup wall at a given height
function wall_r(z) = base_d/2 + (rim_d - base_d)/2 * z / height;

// Points along a quadratic curve from p0 to p2, endpoints left out
function bez(p0, p1, p2, n) =
  [for (k = [1 : n - 1]) let(t = k / n)
    (1 - t) * (1 - t) * p0 + 2 * t * (1 - t) * p1 + t * t * p2];

// Like rotate_extrude, but everything above z0 gets lifted or dropped with
// a sine wave around the circle, reaching the full amount at z1. Below z0
// the shape is untouched, so floors and wells stay flat.
module wavy_sweep(profile, waves, amp, z0, z1) {
  P = len(profile);
  pts = [for (i = [0 : sweep_steps - 1])
           let(a = i * 360 / sweep_steps, w = amp * sin(waves * a))
           for (p = profile)
             let(s = min(1, max(0, (p[1] - z0) / (z1 - z0))))
             [p[0] * cos(a), p[0] * sin(a), p[1] + w * s]];
  faces = [for (i = [0 : sweep_steps - 1], j = [0 : P - 1])
             let(i2 = (i + 1) % sweep_steps, j2 = (j + 1) % P,
                 a = i * P + j, b = i * P + j2, c = i2 * P + j2, d = i2 * P + j)
             each [[a, b, c], [a, c, d]]];
  polyhedron(pts, faces);
}

// A sideways hole with a pointed roof, so it prints round instead of sagging oval.
module teardrop(d, len) {
  rotate([-90, 0, 0]) {
    cylinder(d = d, h = len, center = true, $fn = 24);
    rotate([0, 0, 45])
      cube([d * 0.707, d * 0.707, len], center = true);
  }
}

// A ring of floor holes, each nudged a little in angle and radius
module floor_ring(count, r, seed_off) {
  j = rands(-1, 1, count * 2, seed + seed_off);
  for (i = [0 : count - 1])
    rotate([0, 0, (i + j[2*i] * jitter) * 360 / count])
      translate([r + j[2*i + 1] * jitter * 4, 0, -0.01])
        cylinder(d = hole_d, h = floor_t + 0.02);
}

// ---- The cup ----
if (part != "saucer")
translate([-(rim_d + 6) / 2, 0, 0])
color(print_color)
difference() {
  // Half the silhouette, spun around the center axis. The rim is a flat
  // ring one wall thick that rides up and down in gentle waves.
  union() {
    wavy_sweep([
      [core_r, 0],
      [base_d/2 - foot_r, 0],
      // small rounded foot so the bottom edge doesn't chip
      [base_d/2, foot_r],
      // outer wall straight up to the rim
      [rim_d/2, height],
      // flat top, one wall thick
      [rim_d/2 - wall, height],
      // inner wall coming back down
      [rim_d/2 - wall, floor_t + 0.01],
      [base_d/2 - wall, floor_t],
      [core_r, floor_t]
    ], lip_waves, lip_amp, height / 2, height);
    cylinder(r = core_r + 0.5, h = floor_t);
  }

  // One hole dead center of the floor, then two loose rings around it,
  // kept well in from the wall
  translate([0, 0, -0.01]) cylinder(d = hole_d, h = floor_t + 0.02);
  if (inner_count > 0) floor_ring(inner_count, base_d / 8, 1);
  floor_ring(hole_count, base_d / 4 + 1, 2);

  // Side holes over the lower part of the wall. They start on a staggered
  // grid, then each one wanders a bit in angle and height so the pattern
  // reads as random while keeping a solid web between neighbours.
  z_jit = row_gap * jitter * 0.5;
  side_rows = floor((height * side_top - side_z - z_jit - hole_d / 2) / row_gap) + 1;
  sj = rands(-1, 1, side_rows * side_count * 2, seed);
  for (r = [0 : side_rows - 1], i = [0 : side_count - 1])
    let(k = 2 * (r * side_count + i),
        z = side_z + r * row_gap + sj[k + 1] * z_jit)
    rotate([0, 0, (i + (r % 2) * 0.5 + sj[k] * jitter) * 360 / side_count])
      translate([0, wall_r(z), z])
        teardrop(hole_d, wall * 6);
}

// ---- The saucer, laid flat on the plate beside the cup ----
// Deep dish: the rim stands tall and the inner face rolls down from it in
// a soft convex curve into the sunken well, so it still holds water.
well_d = base_d + 1;   // 0.5mm clearance all round so the cup seats easily

rim_in = [saucer_d/2 - wall - 0.8, saucer_h - 1.2];
well_top = [well_d/2, floor_t + well_depth];
chord = well_top - rim_in;
bulge_dir = [chord[1], -chord[0]] / norm(chord);   // points into the dish
// keep the curve from pushing in past the well wall
bulge_ctl = rim_in + chord / 2 + bulge_dir * saucer_curve * 2;
ctl = [max(well_d/2 + 0.5, bulge_ctl[0]), bulge_ctl[1]];

if (part != "cup")
translate([(saucer_d + 6) / 2, 0, 0])
color(print_color)
union() {
  wavy_sweep(concat(
    [
      [core_r, 0],
      [saucer_d/2 - 1.5, 0],
      // outer wall leaning out slightly to the tall rim
      [saucer_d/2, saucer_h - 1.2],
      [saucer_d/2 - 0.8, saucer_h],
      // inner face rolling back down into the deeper dish
      rim_in
    ],
    bez(rim_in, ctl, well_top, 16),
    [
      well_top,
      // the sunken well floor where the cup sits
      [well_d/2, floor_t],
      [core_r, floor_t]
    ]), saucer_waves, saucer_amp, floor_t + well_depth, saucer_h);
  cylinder(r = core_r + 0.5, h = floor_t);
}
