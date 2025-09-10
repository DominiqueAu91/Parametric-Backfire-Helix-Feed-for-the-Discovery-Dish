# Parametric Backfire Helix Feed for the Discovery Dish

**Goal.** A fully parametric **backfire helical feed** (single-wire) for deep prime-focus dishes (e.g., the **Discovery Dish**), supporting **circular polarization** (LHCP/RHCP), printable scaffolding, and an annular reflector (“donut”) sized for backfire operation. The design is plug-and-play with Digitelektro’s ecosystem and my extension tube that houses an **LNA + bias-T** directly behind the reflector to minimize system noise figure.

## Background & motivation

This started as a **radio-astronomy feed** around **1520 MHz**. It quickly became a **parametric OpenSCAD model** and **3D-printable hardware** designed to be **plug-and-play** with **Digitelektro’s Discovery Dish** ecosystem and with an **extension tube** that shelters the **LNA** (plus bias-T) **in the reflector’s shadow**. Goals: switch L/S bands in minutes, **minimize overall NF** (LNA at the feed), and keep a **mechanically & RF-robust** setup for experimentation.

## What this model does

- **Backfire helix** scaffold + **annular reflector (“donut”)** sized for backfire (default inner diameter ≈ **0.29·λ**).
- **Dish reflection flips circular polarization**; set feed LH/RH accordingly (feed LHCP → sky RHCP, and vice-versa).
- **Parametric OpenSCAD**: frequency, turns, pitch angle (default **14°**), handedness, donut diameters, and vertical stiffening gussets.
- **Helix channel preview** (red) mirrors the subtracted volume for easy wire routing during assembly.

## Quick theory

- λ = c / f
- Circumference C ≈ k·λ (use k ≈ 1 for backfire) → D = k·λ / π
- Pitch per turn from pitch angle α:  
  p = π·D·tan(α)  (default α = 14°)
- Donut inner diameter ≈ 0.29·λ

## Key OpenSCAD parameters

- `freq_MHz`, `turns`, `pitch_angle_deg` (14° default), `circ_factor_k` (1.00 default)
- `helix_right_handed` (`true` / `false`). Remember: **dishes flip circular polarization**.
- `reflector_inner_factor` (0.29 default → donut inner ≈ 0.29·λ)
- `reflector_outer_d_mm` or `reflector_outer_factor` for outer diameter
- `support_inset_mm` to make the posts bite inside the helix radius
- Gussets: vertical plates, flat top / sloped bottom; join at center (`gusset_*`)

## Presets

See **BANDS.md** for L/S-band presets (GNSS, HRIT/HRPT, TT&C, 13 cm Amateur, Globalstar).

## Matching (¼-wave transformer)

Typical backfire single-wire helix impedance: `Z_feed ≈ 120–150 Ω`.  
Use a **quarter-wave transformer** with characteristic impedance: Z_t = √(50 · Z_feed)

Example: if `Z_feed = 125 Ω` → `Z_t ≈ 79 Ω`.  

Implement with a λ/4 section of coax, twin-line, or microstrip near the feed point.  
Fine-tune by trimming the first fraction of a turn.  

## Printing & assembly

PETG ~20% infill; use the red helix preview to pre-check the wire path. Put the LNA right behind the reflector (shadowed), bias-T at the SDR. Keep unintended metal away from the donut edge; **0.29·λ** inner diameter is RF-critical.

## Licensing & credits

- This repo (OpenSCAD + plugin + docs): **CC0**
- Digitelektro / BackfireHelix: **GPL-3.0** — keep attribution & GPL if you reuse their PCB files.
- Classic backfire references: **Nakano & Yamauchi (IEEE)**, **W1GHZ** notes.
