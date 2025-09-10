//
// Backfire Helix Tripod + Donut (parametric)
// - Donut: inner = 0.29·λ by default (backfire), outer set by factor or mm
// - Helix: pitch angle (default 14°), C = k·λ, RH/LH handedness
// - Vertical gussets: flat top, sloped bottom; join at center; printable slopes
// - Subtractive helix channel + (optional) red preview
// Author: Dominique F6EPY + ChatGPT — CC0
//

$fn = 96;

// ------------------------- PARAMETERS -------------------------

// RF & helix
freq_MHz              = 1520;
turns                 = 3.5;
circ_factor_k         = 1.00;    // C = k·λ (≈1 for backfire)
pitch_angle_deg       = 14;      // pitch angle α (deg)
helix_right_handed    = true;    // true=RH, false=LH (feed handedness)
helix_phase0_deg      = 0;       // initial phase (deg)

// Donut reflector
reflector_inner_factor = 0.29;   // donut inner = 0.29·λ (default backfire)
reflector_outer_d_mm   = 0;      // fixed outer diameter (mm); 0 => use factor below
reflector_outer_factor = 0.45;   // donut outer = factor·λ when outer_d_mm == 0
base_thick            = 3;

// Bolt circle (optional)
bolt_hole_count       = 3;
bolt_circle_d         = 51.5;
bolt_hole_d           = 3.5;
bolt_angle0_deg       = 60;

// Make posts bite a few mm *inside* helix radius so the channel intersects
support_inset_mm      = 3.5;     // 2–4 mm typical

// Helix channel (subtraction)
wire_d                = 2.0;     // wire diameter
wire_clearance        = 0.6;     // extra clearance
helix_step_deg        = 6;       // helix discretization (3..10)

// Trapezoidal supports (plan XY), extruded over H_total
support_w_outer       = 15;      // tangential width near donut
support_w_inner       = 5;       // tangential width near center
support_outer_margin  = 6;       // setback from donut outer edge (mm)

// Vertical gussets (radial plane); flat top, sloped bottom
gusset_enable         = true;
gusset_thick          = 2.8;     // tangential thickness (centered)
gusset_top_h          = 10;      // z_top - z_center_base (height of flat top)
gusset_center_thick   = 3.5;     // vertical thickness at center (min)
gusset_post_thick     = 20.0;     // vertical thickness at support (target)
gusset_angle_max_deg  = 45;      // max printable slope for bottom
gusset_embed_rad      = 1.5;     // radial embed into support (mm)
gusset_tan_over       = 1.20;    // tan_thick = max(gusset_thick, support_w_inner*1.20)
levels_per_rev        = 1;       // 1 gusset level per turn

// Helix preview (visualization)
show_helix_preview    = true;
helix_preview_alpha   = 0.7;     // 0..1
helix_preview_d       = 0;       // 0 => same as channel_d

// Debug
show_axis             = false;

// ------------------------- DERIVED -------------------------

lambda   = 300.0 / (freq_MHz/1000.0);
circum   = circ_factor_k * lambda;
helix_D  = circum / PI;
helix_R  = helix_D/2;
pitch    = PI * helix_D * tan(pitch_angle_deg);  // p = π·D·tan(α)
H_total  = turns * pitch;

reflector_ir  = (reflector_inner_factor * lambda) / 2;
reflector_or  = (reflector_outer_d_mm > 0)
                ? reflector_outer_d_mm/2
                : (reflector_outer_factor * lambda)/2;

// handedness
helix_hand = helix_right_handed ? 1 : -1;

// support inner radius (bite inside helix by support_inset_mm)
post_inner_r  = max(helix_R - support_inset_mm, 0.1);

// helix channel
channel_d     = wire_d + wire_clearance;

// ------------------------- MODULES -------------------------

module axis(len=80){
  color("red")   cube([len,0.8,0.8], center=true);
  color("green") cube([0.8,len,0.8], center=true);
  color("blue")  cube([0.8,0.8,len], center=true);
}

// reflector donut (annulus) + optional bolt circle
module reflector_donut(){
  difference(){
    cylinder(h=base_thick, r=reflector_or, center=false);
    translate([0,0,-0.1]) cylinder(h=base_thick+0.2, r=reflector_ir, center=false);
    if (bolt_hole_count>0 && bolt_circle_d>0){
      for (i=[0:bolt_hole_count-1]){
        ang = bolt_angle0_deg + 360*i/bolt_hole_count;
        translate([ (bolt_circle_d/2)*cos(ang), (bolt_circle_d/2)*sin(ang), -0.1 ])
          cylinder(h=base_thick+0.2, d=bolt_hole_d, center=false);
      }
    }
  }
}

// single trapezoidal support at angle ang (deg)
module support_trapezoid(ang=0){
  r_out = max(reflector_ir + 3, reflector_or - support_outer_margin);
  r_in  = post_inner_r;

  // trapezoid vertices in XY (clockwise) before rotation
  p1x = r_in;  p1y = +support_w_inner/2;
  p2x = r_in;  p2y = -support_w_inner/2;
  p3x = r_out; p3y = -support_w_outer/2;
  p4x = r_out; p4y = +support_w_outer/2;

  // rotate by ang (deg)
  c = cos(ang); s = sin(ang);
  P1 = [ p1x*c - p1y*s, p1x*s + p1y*c ];
  P2 = [ p2x*c - p2y*s, p2x*s + p1y*c ];
  P3 = [ p3x*c - p3y*s, p3x*s + p3y*c ];
  P4 = [ p4x*c - p4y*s, p4x*s + p4y*c ];

  translate([0,0,base_thick])
    linear_extrude(height=H_total)
      polygon(points=[ P1, P2, P3, P4 ]);
}

module tripod_supports(){
  support_trapezoid(0);
  support_trapezoid(120);
  support_trapezoid(240);
}

// vertical gusset in radial plane ang (deg), base level offset z0 from the donut top
module gusset_vertical_one(ang=0, z0=0){
  if (gusset_enable){
    // center -> inside the support wall
    Lx = post_inner_r + gusset_embed_rad;

    // printable slope limit (bottom drop)
    max_drop = Lx * tan(gusset_angle_max_deg);

    // top edge is horizontal at z_top
    z_top = base_thick + z0 + gusset_top_h;

    // thicknesses
    t_center = gusset_center_thick;
    t_post_desired = gusset_post_thick;

    // bottom at center
    z_bot_center = z_top - t_center;

    // bottom at post: as low as desired but no lower than slope limit
    z_bot_allowed_min = z_bot_center - max_drop;
    z_bot_post_desired = z_top - t_post_desired;
    z_bot_post = max(z_bot_post_desired, z_bot_allowed_min);

    // 2D section in (X,Z)
    pts = [
      [ 0,  z_bot_center ],
      [ 0,  z_top        ],
      [ Lx, z_top        ],
      [ Lx, z_bot_post   ]
    ];

    tan_thick = max(gusset_thick, support_w_inner * gusset_tan_over);

    // orient radial plane, then rotate so polygon Y->Z, then extrude tangentially
    rotate([0,0,ang])
      rotate([90,0,0])
        linear_extrude(height=tan_thick, center=true, convexity=10)
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
    for (t = [1 : levels_per_rev : max_t]){
      z0 = t * pitch;
      gusset_vertical_triplet(z0);
    }
  }
}

// subtractive helix channel (and preview if requested)
module helix_channel(d_override=0){
  r = helix_R;
  d = (d_override>0) ? d_override : channel_d;
  step = helix_step_deg;
  last = turns*360 - step;
  for (a = [0 : step : last]){
    a1 = helix_hand*(a + helix_phase0_deg);
    a2 = helix_hand*(a + step + helix_phase0_deg);
    z1 = base_thick + (a/360)*pitch;
    z2 = base_thick + ((a+step)/360)*pitch;
    x1 = r*cos(a1); y1 = r*sin(a1);
    x2 = r*cos(a2); y2 = r*sin(a2);
    hull(){
      translate([x1,y1,z1]) sphere(d=d);
      translate([x2,y2,z2]) sphere(d=d);
    }
  }
}

// red helix preview (same path as channel)
module helix_preview(){
  dprev = (helix_preview_d > 0) ? helix_preview_d : channel_d;
  helix_channel(dprev);
}

// structure
module structure(){
  union(){
    reflector_donut();
    tripod_supports();
    gussets_vertical_all();
  }
}

// ------------------------- RENDER -------------------------

// Solid with subtractive helix channel
difference(){
  structure();
  helix_channel(0);
}

// Red preview of the removed helix
if (show_helix_preview)
  color([1,0,0,helix_preview_alpha]) helix_preview();

if (show_axis) axis(80);
