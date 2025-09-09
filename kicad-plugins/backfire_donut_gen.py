# Backfire Donut Generator (KiCad pcbnew Action Plugin)
# Generates an annular reflector board sized from frequency (inner = 0.29*lambda).
# Places Edge.Cuts circles, GND zones on F.Cu/B.Cu, and plated GND mounting holes.
# Install: copy into your KiCad plugins folder and run from pcbnew (Tools → External Plugins).
#
# Author: Dominique F6EPY + ChatGPT (CC0)

import math
import pcbnew

# ---------------- User parameters ----------------
F_MHZ = 1520.0              # center frequency (MHz)
INNER_FACTOR = 0.29         # donut inner = 0.29 * lambda
OUTER_D_MM = 0.0            # fixed outer diameter (mm); 0 => use OUTER_FACTOR
OUTER_FACTOR = 0.90         # donut outer = OUTER_FACTOR * lambda when OUTER_D_MM == 0

BOLT_COUNT = 3              # 3 or 4 (or anything)
BCD_MM = 54.0               # bolt-circle diameter
BOLT_DRILL_MM = 3.2         # drill size
BOLT_PAD_MM = 6.0           # plated pad diameter

ZONE_CLEAR_MM = 0.3         # copper-to-cutout/edge clearance
ANNULUS_MARGIN_MM = 0.25    # spacing from Edge.Cuts for the zone polygon
# ---------------------------------

def mm(v): return pcbnew.FromMM(v)

def ensure_net(board, name):
    netcode = board.GetNetsByName().get(name)
    if netcode is not None:
        return board.FindNet(netcode)
    ni = pcbnew.NETINFO_ITEM(board, name)
    board.Add(ni)
    return ni

def circle_edge(board, center, radius_mm, layer=pcbnew.Edge_Cuts, width_mm=0.1):
    s = pcbnew.PCB_SHAPE(board)
    s.SetShape(pcbnew.SHAPE_T_CIRCLE)
    s.SetLayer(layer)
    s.SetCenter(center)
    s.SetRadius(mm(radius_mm))
    s.SetWidth(mm(width_mm))
    board.Add(s)
    return s

def add_mount_hole(board, pos, drill_mm, pad_mm, netinfo):
    fp = pcbnew.FOOTPRINT(board)
    fp.SetReference("MH")
    pad = pcbnew.PAD(fp)
    pad.SetShape(pcbnew.PAD_SHAPE_CIRCLE)
    pad.SetAttribute(pcbnew.PAD_ATTRIB_THROUGH_HOLE)
    pad.SetSize(pcbnew.VECTOR2I(mm(pad_mm), mm(pad_mm)))
    pad.SetDrillSize(pcbnew.VECTOR2I(mm(drill_mm), mm(drill_mm)))
    pad.SetLayerSet(pcbnew.LSET.AllCuMask())
    pad.SetPosition(pos)
    pad.SetNet(netinfo)
    fp.Add(pad)
    board.Add(fp)
    return fp

class BackfireDonutAction(pcbnew.ActionPlugin):
    def defaults(self):
        self.name = "Backfire Donut Generator"
        self.category = "Board generators"
        self.description = "Generate/resize annular reflector board for backfire helix"

    def Run(self):
        board = pcbnew.GetBoard()
        if board is None:
            return

        # ---- compute λ and diameters ----
        f_mhz = F_MHZ
        lam_mm = 300000.0 / f_mhz  # (mm), c≈3e8 m/s
        d_inner = INNER_FACTOR * lam_mm
        d_outer = OUTER_D_MM if OUTER_D_MM > 0 else OUTER_FACTOR * lam_mm
        r_inner = d_inner / 2.0
        r_outer = d_outer / 2.0

        # ---- clear previous Edge.Cuts (generated) ----
        for d in list(board.GetDrawings()):
            if isinstance(d, pcbnew.PCB_SHAPE) and d.GetLayer() == pcbnew.Edge_Cuts:
                board.Remove(d)

        # ---- draw annulus edges ----
        center = pcbnew.VECTOR2I(0, 0)
        circle_edge(board, center, r_outer)
        circle_edge(board, center, r_inner)

        # ---- ensure GND & zones ----
        gnd = ensure_net(board, "GND")

        # Remove existing zones (simple approach)
        for z in list(board.Zones()):
            board.Remove(z)

        # Add zones (F.Cu / B.Cu) approximating the annulus
        def add_zone(layer):
            z = pcbnew.ZONE(board)
            z.SetLayer(layer)
            z.SetIsRuleArea(False)
            z.SetPadConnection(pcbnew.ZONE_CONNECTION_FULL)
            z.SetZoneClearance(mm(ZONE_CLEAR_MM))
            z.SetMinThickness(mm(0.2))
            z.SetIsFilled(True)
            z.Outline().NewOutline()
            outer = z.Outline().GetOutline(0)
            N = 256
            for i in range(N):
                a = 2*math.pi*i/N
                x = (r_outer - ANNULUS_MARGIN_MM) * math.cos(a)
                y = (r_outer - ANNULUS_MARGIN_MM) * math.sin(a)
                outer.Append(pcbnew.VECTOR2I(mm(x), mm(y)))
            hole = z.Outline().NewHole()
            for i in range(N):
                a = 2*math.pi*i/N
                x = (r_inner + ANNULUS_MARGIN_MM) * math.cos(a)
                y = (r_inner + ANNULUS_MARGIN_MM) * math.sin(a)
                hole.Append(pcbnew.VECTOR2I(mm(x), mm(y)))
            z.SetNet(gnd)
            board.Add(z)
            return z

        add_zone(pcbnew.F_Cu)
        add_zone(pcbnew.B_Cu)

        # ---- bolt circle holes (plated, GND) ----
        for f in list(board.GetFootprints()):
            if f.GetReference().startswith("MH"):
                board.Remove(f)

        for i in range(BOLT_COUNT):
            ang = 2*math.pi*i/BOLT_COUNT
            x = (BCD_MM/2.0) * math.cos(ang)
            y = (BCD_MM/2.0) * math.sin(ang)
            add_mount_hole(board,
                           pcbnew.VECTOR2I(mm(x), mm(y)),
                           BOLT_DRILL_MM,
                           BOLT_PAD_MM,
                           gnd)

        pcbnew.ZONE_FILLER(board).Fill(board.Zones())
        pcbnew.Refresh()

BackfireDonutAction().register()
