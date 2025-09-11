# Parametric Backfire Helix Feed for the Discovery Dish

**Goal.** A fully parametric **backfire helical feed** (single-wire) for deep prime-focus dishes (e.g., the **Discovery Dish**), supporting **circular polarization** (LHCP/RHCP), printable scaffolding, and an annular reflector (“donut”) sized for backfire operation. The design is plug-and-play with **Digitelektro’s ecosystem** (see third_party folder) and my extension tube that houses an **LNA + bias-T** directly behind the reflector to minimize system noise figure.

## Background & motivation

This started as a **radio-astronomy feed** around **1420 MHz** to detect Milky Way H I line. It quickly became a **parametric OpenSCAD model** and **3D-printable hardware** designed to be **plug-and-play** with **Digitelektro’s Discovery Dish** ecosystem and with an **extension tube** that shelters the **LNA** (plus bias-T) **in the reflector’s shadow**. Goals: switch L/S bands in minutes, **minimize overall NF** (LNA at the feed), and keep a **mechanically & RF-robust** setup for experimentation.

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

See **BANDS.md** for L/S-band presets (H I + Radio-astro, GNSS, HRIT/HRPT, TT&C, 13 cm Amateur, Globalstar).

## How many turns? (illumination vs f/D)

The optimal number of helix turns depends on the dish focal ratio (f/D).  
A dish with smaller f/D (deeper dish) requires a **wider beam** (fewer turns).  
A dish with larger f/D (shallower dish) requires a **narrower beam** (more turns).

### Practical rule
- Dish edge angle from focus:  
  `θ_edge = arctan(0.5 / (f/D))`  
- Choose the helix length (number of turns × pitch) so that the **pattern taper at θ_edge** is about **–10 to –13 dB**.  
  This balances aperture efficiency and noise contribution.

### Typical values (backfire helix, D ≈ λ, pitch angle ≈ 14°)
- f/D ≈ 0.30 → 3.5–4 turns  
- f/D ≈ 0.35 → ~3.0 turns (Discovery Dish)  
- f/D ≈ 0.40 → 2.8–3.2 turns  
- f/D ≈ 0.45–0.50 → 2.5–3 turns

### Hydrogen line example
At 1420.42 MHz (`λ ≈ 211 mm`):  
- Helix diameter `≈ 67.2 mm`  
- Pitch per turn `≈ 52.6 mm`  
- For f/D = 0.35 → **3.0 turns** → helix height ≈ 158 mm  
- Donut inner diameter ≈ `0.29·λ ≈ 61 mm`  

This setting gives a clean illumination of the dish, with proper edge taper for low-noise radio astronomy work.

### Choosing the number of turns based on your noise environment

The “optimal” number of turns is not only a function of dish f/D, but also of your RF environment:

- **Quiet rural site:**  
  Use **~3 turns**. The dish edge is illuminated at about –10 dB, which maximizes aperture efficiency.  
  Ground spillover is low in quiet sites, so you benefit from the extra effective aperture.

- **Urban or noisy suburban site:**  
  Consider **5–7 turns**. The beam narrows and under-illuminates the dish (edge taper ≈ –15 to –18 dB).  
  Although efficiency drops slightly, spillover from the ground and local RFI is strongly reduced.  
  The effective system noise temperature is lower, so overall SNR can actually improve.

👉 Rule of thumb:  
- For **radio astronomy, HRPT, or weak-signal work in rural areas** → ~3 turns.  
- For **general SDR satellite reception in noisy areas** → 5–7 turns.


## Matching (¼-wave transformer)

Typical backfire single-wire helix impedance: `Z_feed ≈ 120–150 Ω`.  
Use a **quarter-wave transformer** with characteristic impedance: Z_t = √(50 · Z_feed)

Example: if `Z_feed = 125 Ω` → `Z_t ≈ 79 Ω`.  

Implement with a λ/4 section of coax, twin-line, or microstrip near the feed point.  
Fine-tune by trimming the first fraction of a turn.  

## Printing & assembly

PETG ~20% infill; use the red helix preview to pre-check the wire path. Put the LNA right behind the reflector (shadowed), bias-T at the SDR. Keep unintended metal away from the donut edge; **0.29·λ** inner diameter is RF-critical.
## Additional Files and Quick Start

Alongside the parametric OpenSCAD sources, two key design files are provided:

- **`tripod_helix_donut.scad`**  
  Parametric model of the backfire helix feed support with tripod posts, gussets, and donut base.  
  Fully customizable: frequency, reflector diameter, number of turns, pitch angle, etc.  
  Designed to generate a mechanically robust feed suitable for use at the focal point of the Discovery Dish or other parabolic reflectors.

- **`para_extension_tube_inserts_M3.scad`**  
  Parametric design of the extension tube adapter.  
  This tube fits between **Digitelektro’s backfire_helix_adapter_for_discovery_dish** (see third_party folder) and the backfire helix feed.  
  Its purpose is to house and protect an LNA (e.g. **SPF5189Z**), filter (e.g. **Mini-Circuits VHF 1200+**) and a Bias-T immediately behind the helix reflector, in the geometric shadow of the reflector.  
  It supports Ruthex threaded inserts (M3 or M4), making it easy to switch between different feeds (L-band and S-band) while maintaining strong mechanical stability.

### Pre-generated STL Files

For convenience, **STL files are provided for the 1420.42 MHz hydrogen line (H I radio astronomy)** configuration.  
These can be directly printed — PETG recommended, ≥20% infill — to assemble a ready-to-use feed for neutral hydrogen observations.

### Quick Start

1. If your goal is **1420 MHz radio astronomy (hydrogen line)**:  
   - Print the supplied STL files directly.  
   - Mount the backfire helix feed on your Discovery Dish using the extension tube.  
   - Insert your LNA + Bias-T inside the tube.

2. If you want to explore **other bands**:  
   - Open `tripod_helix_donut.scad` in OpenSCAD.  
   - Adjust parameters (frequency, turns, reflector diameter, polarization).  
   - Export your own STL for printing.  
   - Optional: use `para_extension_tube_inserts_M3.scad` if you need the protected LNA/Bias-T housing.

This makes the project **plug-and-play** for hydrogen line observations while still giving full flexibility for other L-band and S-band satellite experiments.
## Generating Gerber Files for Your Custom Reflector Disk

This project includes a KiCad 8 **action plugin** (`donut_reflector_disk_sma.py`) to generate a parametric round reflector PCB with:

- **Circular Edge.Cuts outline**  
- **Ground planes (F.Cu & B.Cu)** tied to the SMA ground pins  
- **Optional soldermask opening** (bare copper reflector)  
- **Centered CONSMA001-C-G SMA footprint** (square GND pads)  
- **Custom silkscreen label**

### Steps to Generate Gerbers

1. **Run the plugin**  
   - In KiCad PCB Editor:  
     `Tools → External Plugins → Parametric Reflector Disk + SMA`  
   - Enter:
     - Frequency in MHz (auto-calculates reflector diameter = 0.29·λ)  
     - Custom silkscreen label  
     - Option: open soldermask (bare copper)  

2. **Verify in PCB Editor**  
   - Confirm the reflector disk outline is present.  
   - Ensure the copper zones fill properly and connect to the SMA ground pins.  
   - Use the **Highlight Net** tool: selecting any SMA ground pin should highlight the whole disk.

3. **Generate Gerbers**  
   - Go to: `File → Plot…`  
   - Choose **Gerber** format.  
   - Enable at least these layers:
     - `F.Cu`, `B.Cu`  
     - `F.Mask`, `B.Mask`  
     - `F.SilkS` (optional, for label)  
     - `Edge.Cuts` (always required)  
   - Click **Plot**.

4. **Generate Drill Files**  
   - In the same dialog, click **Generate Drill Files…**  
   - Select **Excellon format** and include **PTH drills**.  
   - Click **Generate Drill File**.

5. **Check with Gerber Viewer**  
   - Open the output in KiCad’s **GerbView**.  
   - Confirm:
     - Copper fills are present on both sides.  
     - Mask opening (if enabled) exposes the reflector area.  
     - Drill holes are correct for the SMA center pin and ground legs.  

6. **Prepare for Fabrication**  
   - Zip the Gerber and drill files.  
   - Upload to your fab (e.g., JLCPCB).  
   - Recommended JLCPCB options:
     - Material: FR-4, 1.6 mm  
     - Copper: 1 oz  
     - Surface finish: ENIG (1U")  
     - Soldermask: Black (or your choice)  
     - Silkscreen: White  

---

👉 With this workflow you can generate **custom reflector disks** for any band (L-band, S-band, hydrogen line at 1420 MHz, etc.) simply by entering the frequency in the plugin dialog.

## Licensing & credits

- This repo (OpenSCAD + plugin + docs): **CC0**
- Digitelektro / BackfireHelix: **GPL-3.0** — keep attribution & GPL if you reuse their PCB files.
- Classic backfire references: **Nakano & Yamauchi (IEEE)**, **W1GHZ**, **N1BWT** notes.
