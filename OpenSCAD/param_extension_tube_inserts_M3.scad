//
// Parametric extension tube between Digitelektro's "Discovery Dish helix adapter"
// and "Backfire helix feed" to fit an LNA + Bias-T.
// Flange B: heat-set inserts ONLY (select M3 or M4). Clean & printable.
// Author: Cooperation between ChatGPT and Dominique F6EPY
// License: CC0

$fn = 96;

// ------------------------- User Parameters -------------------------

// Core tube
length_mm        = 120;   // extension length
id_mm            = 40;   // inner diameter
wall_mm          = 3;    // wall thickness
center_hole_A_d  = 40;   // central through-hole on flange A (Discovery side)
center_hole_B_d  = 40;   // central through-hole on flange B (Backfire side)
bevel_mm         = 0.6;  // small bevel on tube edges

// Flanges (A = Discovery side, B = Backfire side)
flangeA = [
  "thickness",   4,
  "outer_d",     60,
  "hole_count",  3,
  "bcd",         51.5,
  "hole_d",      4.5,   // A-side through holes
  "angle0_deg",  0,
  // optional features (set 0 to disable)
  "cbore_d",     7.5, "cbore_depth", 1.5,   // counterbore on OUTER face
  "boss_d",      42,  "boss_h",       1.0,  // boss (male) on INNER face
  "recess_d",     0,  "recess_h",     0     // recess (female) on INNER face
];

flangeB = [
  "thickness",   30,   // thicker, typically the tapered one
  "outer_d",     80,
  "hole_count",  3,
  "bcd",         72.0,
  "hole_d",      3.2,  // unused now (kept for compatibility)
  "angle0_deg",  0,
  // optional features
  "cbore_d",     0,   "cbore_depth", 0,
  "boss_d",      0,   "boss_h",      0,
  "recess_d",    42,  "recess_h",    1.0
];

// ---- Inserts on flange B ----
// Choose size M3/M4 (defaults below) OR override custom values
insert_size         = "M3";   // "M3" | "M4"
insert_override     = false;  // true -> use custom values below (ignoring size defaults)
insert_d_outer_M3   = 4.8;    // typical pocket Ø for Ruthex M3 in PLA/PETG
insert_len_M3       = 5.0;    // pocket depth for M3
insert_d_outer_M4   = 5.6;    // typical pocket Ø for Ruthex M4 in PLA/PETG
insert_len_M4       = 9.0;    // pocket depth for M4
insertB_d_outer     = 6.0;    // custom pocket Ø if override=true
insertB_length      = 6.0;    // custom pocket depth if override=true
insertB_chamfer     = 0.4;    // small entry chamfer height (mm)

// Taper setup — applies to ONE side only (kept as before)
tapered_flange     = "B";   // "A" or "B"
taper_enabled      = true;  // set false to disable taper entirely
big_at_outer       = true;  // true: big OD at OUTER face; false: big OD at INNER face
taper_flat_side    = "big"; // keep a flat at "big" or "small" OD side
taper_flat_h       = 10;    // default flat height (mm)
taper_flat_B_h     = 10;    // specific flat height for flange B (overrides default)

// ------------------------- Helpers -------------------------

function kv(h, k, default_val=0) =
    let (idx = search([k], [for(i=[0:len(h)/2-1]) h[2*i]]))
    (len(idx) > 0) ? h[2*idx[0]+1] : default_val;

function is_tapered(which) =
    (taper_enabled && ((tapered_flange == "A" && which=="A") || (tapered_flange == "B" && which=="B")));

function ins_d_default(size) = (size=="M3") ? insert_d_outer_M3 : insert_d_outer_M4;
function ins_h_default(size) = (size=="M3") ? insert_len_M3     : insert_len_M4;

module bevel_ring(id, od, h) {
  difference() {
    cylinder(h=h, d=od, center=false);
    translate([0,0,-0.01]) cylinder(h=h+0.02, d=id, center=false);
  }
}

module cbore(d, depth) { translate([0,0,-depth]) cylinder(h=depth, d=d, center=false); }

// ------------------------- Main geometry -------------------------

module adapter_tube() {
  tube_od = id_mm + 2*wall_mm;

  union() {
    // Tube
    difference() {
      cylinder(h=length_mm, d=tube_od, center=false);
      translate([0,0,-0.01]) cylinder(h=length_mm+0.02, d=id_mm, center=false);
    }
    if (bevel_mm > 0) {
      translate([0,0,0]) bevel_ring(id_mm, tube_od, bevel_mm);
      translate([0,0,length_mm]) rotate([180,0,0]) bevel_ring(id_mm, tube_od, bevel_mm);
    }

    // Flanges
    translate([0,0,0])         flange_end(flangeA, "A");           // inner face at Z=0
    translate([0,0,length_mm]) flange_end(flangeB, "B");           // inner face at Z=0 of this module
  }
}

module flange_end(params, which="A") {
  tube_od   = id_mm + 2*wall_mm;

  th        = kv(params,"thickness",4);
  od        = kv(params,"outer_d", tube_od + 10);
  hole_cnt  = kv(params,"hole_count",0);
  bcd       = kv(params,"bcd",0);
  hole_d    = kv(params,"hole_d",3.2);
  angle0    = kv(params,"angle0_deg",0);

  cbore_d     = kv(params,"cbore_d",0);
  cbore_depth = kv(params,"cbore_depth",0);
  boss_d      = kv(params,"boss_d",0);
  boss_h      = kv(params,"boss_h",0);
  recess_d    = kv(params,"recess_d",0);
  recess_h    = kv(params,"recess_h",0);

  // Resolve insert dimensions by size/override (used only if which=="B")
  ins_d  = insert_override ? insertB_d_outer : ins_d_default(insert_size);
  ins_h  = insert_override ? insertB_length  : ins_h_default(insert_size);

  difference() {
    // ---- BODY (core + outer skin) ----
    union() {
      // Core: keeps inner bore unchanged
      cylinder(h=th, d=tube_od, center=false);

      if (is_tapered(which)) {
        flat_h = min((which=="B" ? taper_flat_B_h : taper_flat_h), th);

        // Inner face is Z=0, outer face is Z=th.
        big_at_z   = big_at_outer ? th : 0;   // where OD = od
        small_at_z = big_at_outer ? 0  : th;  // where OD = tube_od

        if (taper_flat_side == "big") {
          if (big_at_z == 0) {
            // Flat z=0..flat_h at OD=od
            difference() {
              cylinder(h=flat_h, d=od, center=false);
              translate([0,0,-0.01]) cylinder(h=flat_h+0.02, d=tube_od, center=false);
            }
            if (th > flat_h) translate([0,0,flat_h]) difference() {
              cylinder(h=th-flat_h, d1=od, d2=tube_od, center=false);
              translate([0,0,-0.01]) cylinder(h=th-flat_h+0.02, d=tube_od, center=false);
            }
          } else {
            if (th > flat_h) difference() {
              cylinder(h=th-flat_h, d1=tube_od, d2=od, center=false);
              translate([0,0,-0.01]) cylinder(h=th-flat_h+0.02, d=tube_od, center=false);
            }
            translate([0,0,th-flat_h]) difference() {
              cylinder(h=flat_h, d=od, center=false);
              translate([0,0,-0.01]) cylinder(h=flat_h+0.02, d=tube_od, center=false);
            }
          }
        } else { // flat on "small" side
          if (small_at_z == 0) {
            if (th > flat_h) translate([0,0,flat_h]) difference() {
              cylinder(h=th-flat_h, d1=tube_od, d2=od, center=false);
              translate([0,0,-0.01]) cylinder(h=th-flat_h+0.02, d=tube_od, center=false);
            }
          } else {
            if (th > flat_h) difference() {
              cylinder(h=th-flat_h, d1=od, d2=tube_od, center=false);
              translate([0,0,-0.01]) cylinder(h=th-flat_h+0.02, d=tube_od, center=false);
            }
            // top flat implicit by core
          }
        }
      } else {
        // Non-tapered outer cylinder at OD + tiny shoulder to tube OD
        cylinder(h=th, d=od, center=false);
        shoulder_h = max(0.01, min(1.2, th*0.25));
        cylinder(h=shoulder_h, d=tube_od, center=false);
      }
    }

    // ---- SUBTRACTIONS ----

    // Flange A: bolt circle (traversant classique)
    if (which=="A" && hole_cnt > 0 && bcd > 0) {
      for (i=[0:hole_cnt-1]) {
        ang = angle0 + 360*i/hole_cnt;
        px = (bcd/2)*cos(ang);
        py = (bcd/2)*sin(ang);
        translate([px, py, 0]) cylinder(h=th+0.4, d=hole_d, center=false);
      }
    }

    // Flange B: inserts (M3/M4) — blind pockets on OUTER flat
    if (which=="B" && hole_cnt > 0 && bcd > 0) {
      depth = min(ins_h, th-0.4);
      for (i=[0:hole_cnt-1]) {
        ang = angle0 + 360*i/hole_cnt;
        px = (bcd/2)*cos(ang);
        py = (bcd/2)*sin(ang);
        if (depth > 0) {
          translate([px, py, th - depth]) cylinder(h=depth+0.2, d=ins_d, center=false);
          if (insertB_chamfer > 0 && insertB_chamfer < depth)
            translate([px, py, th - insertB_chamfer])
              cylinder(h=insertB_chamfer+0.2, d1=ins_d+0.6, d2=ins_d, center=false);
        }
      }
    }

    // Central through-hole (per flange)
    chd = (which=="A") ? center_hole_A_d : center_hole_B_d;
    translate([0,0,-1]) cylinder(h=th+2, d=chd, center=false);
    translate([0,0,-1]) cylinder(h=th+2, d=chd+0.2, center=false);

    // Female recess on inner face (optional)
    if (recess_d > 0 && recess_h > 0)
      translate([0,0,0]) cylinder(h=recess_h, d=recess_d, center=false);
  }

  // Counterbores on OUTER face (optional, flange A only here)
  if (which=="A" && cbore_d > 0 && cbore_depth > 0) {
    faceZ = th;
    for (i=[0:hole_cnt-1]) if (hole_cnt > 0 && bcd > 0) {
      ang = angle0 + 360*i/hole_cnt;
      p = [ (bcd/2)*cos(ang), (bcd/2)*sin(ang), faceZ ];
      translate(p) cbore(cbore_d, cbore_depth);
    }
  }

  // Male boss on inner face (optional)
  if (boss_d > 0 && boss_h > 0)
    translate([0,0,0]) cylinder(h=boss_h, d=boss_d, center=false);
}

// ------------------------------ Render ---------------------------------
difference() {
  adapter_tube();
  // End A cut (base)
  translate([0,0,-2])
    cylinder(h=kv(flangeA,"thickness",4)+4, d=center_hole_A_d+0.2, center=false);
  // End B cut (top)
  translate([0,0,length_mm - kv(flangeB,"thickness",4) - 2])
    cylinder(h=kv(flangeB,"thickness",4)+4, d=center_hole_B_d+0.2, center=false);
}
