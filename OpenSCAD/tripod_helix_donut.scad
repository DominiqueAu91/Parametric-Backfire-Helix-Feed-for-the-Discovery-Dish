//
// Backfire Helix Tripod + Donut (parametric)
// - Donut: inner = 0.29·λ by default (backfire), outer set by factor or mm
// - Helix: pitch angle (default 14°), C = k·λ, RH/LH handedness
// - Vertical gussets: flat top, sloped bottom; join at center; printable slopes
// - Subtractive helix channel + (optional) red preview
// Author: Dominique F6EPY + ChatGPT — CC0
//

// --- engraving config ---
engrave_enable            = true;
engrave_text              = "Design by F6EPY";
engrave_support_angle     = 0;       // 0 / 120 / 240
engrave_size_mm           = 6;
engrave_depth_mm          = 1.8;     // must be > face_gap
engrave_pos_frac          = 0.50;    // 0..1 along height
engrave_face_gap          = 0.15;    // small air gap before wall
engrave_use_tangential    = false;   // true = side (+/-Y), false = radial (+/-X)
engrave_outer_face        = true;    // tangential: +Y outer / radial: +X outer(back)
engrave_y_frac            = 0.0;     // -0.5..+0.5 across width (radial mode)
engrave_text_rot_deg      = 0;       // rotate text on face
engrave_debug_cube        = false;    // notch first to verify
engrave_overlay_show      = true;    // draw red overlay (F5) if desired
engrave_flip_horizontal = true;   // flip text horizontally to correct mirroring


// --- preview controls ---
preview_mode        = 2;     // 0=subtractive, 1=transparent overlay, 2=subtractive+red-peek, 3=cutaway
structure_alpha     = 0.35;  // transparency for overlay mode (mode 1)
preview_expand_mm   = 0.30;  // extra radius for red preview (mode 2)

// Cutaway settings (mode 3)
cutaway_axis        = "X";   // "X","Y","Z"
cutaway_offset_mm   = 0;     // shift cut plane along axis
cutaway_keep_positive = true;// keep +axis side (true) or –axis side (false)

// ---------- Quality / robustness ----------
$fn_solid   = 96;    // donuts/supports/gussets
$fn_channel = 28;    // helix channel cylinders (keep lower)
eps_z       = 0.02;  // tiny Z nudge to avoid coplanar faces

// ---------- RF & helix ----------
freq_MHz           = 1420;
turns              = 3.0;
circ_factor_k      = 1.00;   // C = k*lambda (≈1 for backfire)
pitch_angle_deg    = 14;     // degrees (OpenSCAD trig uses degrees)
helix_right_handed = true;   // true = RH, false = LH
helix_phase0_deg   = 45;

// ---------- Donut (annular reflector) ----------
reflector_inner_factor = 0.29; // inner ≈ 0.29*lambda
reflector_outer_d_mm   = 80;    // if 0 => use factor below
reflector_outer_factor = 0.90; // outer ≈ 0.90*lambda when outer_d_mm==0
base_thick             = 3;

// ---------- Bolt circle (optional) ----------
bolt_hole_count   = 3;
bolt_circle_d     = 72;
bolt_hole_d       = 3.5;
bolt_angle0_deg   = 60;

// ---------- Supports (trapezoids) ----------
support_inset_mm     = 3.5;  // posts bite inside helix radius
support_w_outer      = 12;   // tangential width near donut
support_w_inner      = 6;    // tangential width near center
support_outer_margin = 0;    // setback from donut outer radius

// ---------- Vertical gussets (radial planes) ----------
gusset_enable        = true;
gusset_top_h         = 0;   // flat top height above donut
gusset_center_thick  = 3.5;  // vertical thickness at center (min)
gusset_post_thick    = 15.0;  // vertical thickness at support (target)
gusset_angle_max_deg = 45;   // max printable slope (degrees)
gusset_embed_rad     = 1.5;  // radial embed into support
gusset_min_tan       = 2.8;  // min tangential extrusion width
levels_per_rev       = 2.0;    // gusset rings per full turn (>=1)
show_gusset_debug    = false;

// ---------- Helix channel (subtractive) + preview ----------
wire_d             = 1.4;
wire_clearance     = 0.6;
helix_step_deg     = 8;      // 6..10 typical; larger = lighter
show_helix_preview = true;
helix_preview_alpha= 1.0;
helix_preview_d    = 0;      // 0 => same as channel_d

// ---------- Debug ----------
show_axis          = false;

// ---------- Helpers ----------
function clamp(x,a,b) = (x < a) ? a : ((x > b) ? b : x);

// ---------- Derived ----------
lambda  = 300.0 / (freq_MHz/1000.0);
circum  = circ_factor_k * lambda;
helix_D = circum / PI;
helix_R = helix_D/2;
pitch   = PI * helix_D * tan(pitch_angle_deg);  // degrees OK in OpenSCAD
H_total = turns * pitch;

reflector_ir = (reflector_inner_factor * lambda) / 2;
reflector_or = (reflector_outer_d_mm > 0) ? (reflector_outer_d_mm/2)
                                          : ((reflector_outer_factor*lambda)/2);

// global radii for supports/gussets
post_inner_r = max(helix_R - support_inset_mm, 0.1);
post_outer_r = max(reflector_ir + 3, reflector_or - support_outer_margin);

// tangential width of support vs radius (linear interpolation)
function support_width_at(r) =
    (abs(post_outer_r - post_inner_r) < 1e-6)
    ? support_w_inner
    : let(t = clamp((r - post_inner_r) / (post_outer_r - post_inner_r), 0, 1))
      support_w_inner + t * (support_w_outer - support_w_inner);

// ---------- Modules ----------
module axis(len=80){
  color("red")   cube([len,0.8,0.8], center=true);
  color("green") cube([0.8,len,0.8], center=true);
  color("blue")  cube([0.8,0.8,len], center=true);
}

module reflector_donut(){
  difference(){
    cylinder(h=base_thick, r=reflector_or, center=false, $fn=$fn_solid);
    translate([0,0,-0.1])
      cylinder(h=base_thick+0.2, r=reflector_ir, center=false, $fn=$fn_solid);
    if (bolt_hole_count>0 && bolt_circle_d>0){
      for (i=[0:bolt_hole_count-1]){
        ang = bolt_angle0_deg + 360*i/bolt_hole_count;
        translate([ (bolt_circle_d/2)*cos(ang), (bolt_circle_d/2)*sin(ang), -0.1 ])
          cylinder(h=base_thick+0.2, d=bolt_hole_d, center=false, $fn=$fn_solid);
      }
    }
  }
}

module support_trapezoid(ang=0){
  r_in  = post_inner_r;
  r_out = post_outer_r;

  // trapezoid in XY before rotation
  p1x = r_in;  p1y = +support_w_inner/2;
  p2x = r_in;  p2y = -support_w_inner/2;
  p3x = r_out; p3y = -support_w_outer/2;
  p4x = r_out; p4y = +support_w_outer/2;

  c = cos(ang); s = sin(ang);
  P1 = [ p1x*c - p1y*s, p1x*s + p1y*c ];
  P2 = [ p2x*c - p2y*s, p2x*s + p2y*c ];
  P3 = [ p3x*c - p3y*s, p3x*s + p3y*c ];
  P4 = [ p4x*c - p4y*s, p4x*s + p4y*c ];

  // nudge up by eps_z so it's not coplanar with donut
  translate([0,0,base_thick + eps_z])
    linear_extrude(height=H_total)
      polygon(points=[ P1, P2, P3, P4 ]);
}

module tripod_supports(){
  support_trapezoid(0);
  support_trapezoid(120);
  support_trapezoid(240);
}

// Cylinder between two points p1 -> p2 with radius r (no norm(), all local)
// --- helper: cylinder between two points (no norm(), no globals)
module seg_cyl(p1, p2, r){
  v = [ p2[0]-p1[0], p2[1]-p1[1], p2[2]-p1[2] ];
  h = sqrt(v[0]*v[0] + v[1]*v[1] + v[2]*v[2]);
  if (h > 1e-6){
    ang = acos(v[2]/h) * 180/PI;     // degrees
    ax  = [ -v[1], v[0], 0 ];        // rotation axis (z -> v)
    translate(p1)
      rotate(ang, ax)
        cylinder(h=h, r=r, center=false, $fn=$fn_channel);
  }
}

// one vertical gusset (radial plane at ang), base offset z0 above donut
// tangential width equals support width at contact radius
module gusset_vertical_one(ang=0, z0=0){
  if (gusset_enable){
    Lr = clamp(post_inner_r + gusset_embed_rad, post_inner_r, post_outer_r);

    // printable slope constraint (bottom drop limit across radial run Lr)
    max_drop = Lr * tan(gusset_angle_max_deg);

    // top edge (flat) — nudge by eps_z to avoid coplanar
    z_top = base_thick + eps_z + z0 + gusset_top_h;

    // desired vertical thicknesses
    t_center = gusset_center_thick;
    t_post   = gusset_post_thick;

    // bottoms (limit post side by slope)
    z_bot_center      = z_top - t_center;
    z_bot_post_target = z_top - t_post;
    z_bot_allowed_min = z_bot_center - max_drop;
    z_bot_post        = max(z_bot_post_target, z_bot_allowed_min);

    // 2D radial section (X,Z)
    pts = [
      [ 0,  z_bot_center ],
      [ 0,  z_top        ],
      [ Lr, z_top        ],
      [ Lr, z_bot_post   ]
    ];

    tan_width = max(gusset_min_tan, support_width_at(Lr));

    if (show_gusset_debug)
      color([1,0,0,0.5])
        rotate([0,0,ang])
          rotate([90,0,0])
            linear_extrude(height=tan_width, center=true, convexity=10)
              polygon(points=pts);
    else
      rotate([0,0,ang])
        rotate([90,0,0])
          linear_extrude(height=tan_width, center=true, convexity=10)
            polygon(points=pts);
  }
}

module gusset_vertical_triplet(z0=0){
  gusset_vertical_one(0,   z0);
  gusset_vertical_one(120, z0);
  gusset_vertical_one(240, z0);
}

module gussets_vertical_all(){
  if (gusset_enable){
    max_t = floor(turns);
    stepN = (levels_per_rev < 1) ? 1 : levels_per_rev;
    for (t = [1 : stepN : max_t]){
      z0 = t * pitch;
      gusset_vertical_triplet(z0);
    }
  }
}

// --- helix channel built as fixed-count cylinder segments
module helix_channel(d_override=0){
  r      = helix_R;
  d      = (d_override>0) ? d_override : (wire_d + wire_clearance);
  rad    = d/2;
  step   = helix_step_deg;
  steps  = floor(turns*360/step);     // integer segment count
  hand   = helix_right_handed ? 1 : -1;

  // loop over segments i = 0 .. steps-1, from angle a1 to a2
  for (i = [0 : steps-1]){
    a1   = i*step;
    a2   = (i+1)*step;

    a1h  = hand*(a1 + helix_phase0_deg);
    a2h  = hand*(a2 + helix_phase0_deg);

    z1   = base_thick + eps_z + (a1/360)*pitch;
    z2   = base_thick + eps_z + (a2/360)*pitch;

    p1   = [ r*cos(a1h), r*sin(a1h), z1 ];
    p2   = [ r*cos(a2h), r*sin(a2h), z2 ];

    seg_cyl(p1, p2, rad);
  }
}

module helix_preview(expand=0){
  dprev = (helix_preview_d > 0 ? helix_preview_d : (wire_d + wire_clearance)) + expand;
  color([1,0,0,helix_preview_alpha]) helix_channel(dprev);
}

module structure(){
  union(){
    reflector_donut();
    tripod_supports();
    gussets_vertical_all();
  }
}

// Keep only a half-space using a huge cube (for cutaway mode)
module halfspace(axis="X", offset=0, keep_pos=true){
  s = 2000; // very large
  sign = keep_pos ? +1 : -1;
  if (axis == "X")
    translate([sign*s/2 + offset, 0, 0]) cube([s, 2*s, 2*s], center=true);
  else if (axis == "Y")
    translate([0, sign*s/2 + offset, 0]) cube([2*s, s, 2*s], center=true);
  else  // "Z"
    translate([0, 0, sign*s/2 + offset]) cube([2*s, 2*s, s], center=true);
}


// Engraves either tangential side (+/-Y) or radial face (+/-X) of a chosen support.
// Uses engrave_flip_horizontal to un-mirror the characters.
module engrave_cutter(ang=0){
  if (engrave_enable) {
    z_mid = base_thick + eps_z + H_total * clamp(engrave_pos_frac, 0, 1);
    depth = max(engrave_depth_mm, engrave_face_gap + 0.3);

    rotate([0,0,ang]) {  // pick the leg (0 / 120 / 240)

      if (engrave_use_tangential) {
        // ----- TANGENTIAL (+/-Y) -----
        r_sel  = (post_inner_r + post_outer_r)/2;
        w_half = support_width_at(r_sel)/2;

        side_sign = engrave_outer_face ? +1 : -1;   // +Y or -Y
        tiltX     = engrave_outer_face ? +90 : -90; // map +Z into wall

        translate([ r_sel, side_sign*(w_half + engrave_face_gap), z_mid ])
          rotate([tiltX,0,0])            // +Z -> +/-Y (into wall)
            rotate([0,0,engrave_text_rot_deg]) {
              if (engrave_debug_cube) {
                translate([-engrave_size_mm/2, 0, -engrave_size_mm/2])
                  cube([engrave_size_mm, depth, engrave_size_mm], center=false);
              } else {
                // ---- UN-MIRROR HERE IF NEEDED ----
                if (engrave_flip_horizontal)
                  scale([-1, 1, 1])
                    linear_extrude(height=depth, center=false, convexity=8)
                      text(engrave_text, size=engrave_size_mm, halign="center", valign="center");
                else
                  linear_extrude(height=depth, center=false, convexity=8)
                    text(engrave_text, size=engrave_size_mm, halign="center", valign="center");
              }
            }

      } else {
        // ----- RADIAL (+/-X)  (BACK = +X when engrave_outer_face==true) -----
        r_face  = engrave_outer_face ? post_outer_r : post_inner_r;
        w_half  = support_width_at(r_face)/2;
        y_off   = clamp(engrave_y_frac, -0.5, 0.5) * (2*w_half);

        tiltY   = engrave_outer_face ? -90 : +90;   // +Z -> +/-X (into wall)
        x_pos   = r_face + (engrave_outer_face ? +engrave_face_gap : -engrave_face_gap);

        translate([ x_pos, y_off, z_mid ])
          rotate([0, tiltY, 0]) {   // +Z -> +/-X (into wall)
            if (engrave_debug_cube) {
              translate([-engrave_size_mm/2, 0, -engrave_size_mm/2])
                cube([engrave_size_mm, depth, engrave_size_mm], center=false);
            } else {
              // ---- UN-MIRROR HERE IF NEEDED ----
              if (engrave_flip_horizontal)
                scale([-1, 1, 1])
                  linear_extrude(height=depth, center=false, convexity=8)
                    text(engrave_text, size=engrave_size_mm, halign="center", valign="center");
              else
                linear_extrude(height=depth, center=false, convexity=8)
                  text(engrave_text, size=engrave_size_mm, halign="center", valign="center");
            }
          }
      }

    }
  }
}


// ---------------- RENDER (with modes + engraving) ----------------
if (preview_mode == 0) {
  // Final: subtractive solid (helix hole + engraving)
  difference(){
    structure();
    helix_channel(0);
    engrave_cutter(engrave_support_angle);
  }
  if (show_helix_preview) helix_preview(0);
  if (engrave_overlay_show && engrave_enable)
    color([1,0,0,0.35]) engrave_cutter(engrave_support_angle);

} else if (preview_mode == 1) {
  // Transparent overlay: no subtraction -> see red helix inside
  if (show_helix_preview) helix_preview(0);
  color([0.8,0.8,0.8,structure_alpha]) structure();
  if (engrave_overlay_show && engrave_enable)
    color([1,0,0,0.35]) engrave_cutter(engrave_support_angle);

} else if (preview_mode == 2) {
  // Subtractive solid + red helix slightly larger so it peeks out
  difference(){
    structure();
    helix_channel(0);
    engrave_cutter(engrave_support_angle);
  }
  if (show_helix_preview) helix_preview(preview_expand_mm);
  if (engrave_overlay_show && engrave_enable)
    color([1,0,0,0.35]) engrave_cutter(engrave_support_angle);

} else if (preview_mode == 3) {
  // Cutaway / section view: slice solid, then subtract helix & engraving
  difference(){
    intersection(){
      structure();
      halfspace(cutaway_axis, cutaway_offset_mm, cutaway_keep_positive);
    }
    helix_channel(0);
    engrave_cutter(engrave_support_angle);
  }
  if (show_helix_preview) helix_preview(0);
  if (engrave_overlay_show && engrave_enable)
    color([1,0,0,0.35]) engrave_cutter(engrave_support_angle);

} else {
  // Fallback = mode 2
  difference(){
    structure();
    helix_channel(0);
    engrave_cutter(engrave_support_angle);
  }
  if (show_helix_preview) helix_preview(preview_expand_mm);
  if (engrave_overlay_show && engrave_enable)
    color([1,0,0,0.35]) engrave_cutter(engrave_support_angle);
}

if (show_axis) axis(80);
