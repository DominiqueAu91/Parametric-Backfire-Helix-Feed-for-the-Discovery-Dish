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

- \( \lambda = \dfrac{c}{f} \)
- Circumference \(C \approx k\,\lambda\) (use \(k\approx 1\) for backfire) ⇒ \( D = \dfrac{k\,\lambda}{\pi} \)
- Pitch per turn from pitch angle \( \alpha \): \( p = \pi D \tan \alpha \) (default \( \alpha = 14^\circ \))
- Donut inner diameter ≈ \(0.29\,\lambda\)

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

Typical backfire single-wire helix \(Z_\text{feed}\sim120–150\,\Omega\). Use \( Z_t=\sqrt{50\,Z_\text{feed}} \) and a λ/4 section (coax or microstrip/twin-line) near the feed point; trim the first fraction of a turn for fine-tuning.

## Printing & assembly

PETG ~20% infill; use the red helix preview to pre-check the wire path. Put the LNA right behind the reflector (shadowed), bias-T at the SDR. Keep unintended metal away from the donut edge; **0.29·λ** inner diameter is RF-critical.

## Licensing & credits

- This repo (OpenSCAD + plugin + docs): **CC0**
- Digitelektro / BackfireHelix: **GPL-3.0** — keep attribution & GPL if you reuse their PCB files.
- Classic backfire references: **Nakano & Yamauchi (IEEE)**, **W1GHZ** notes.
