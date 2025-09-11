# Backfire Donut Generator (KiCad pcbnew Action Plugin)
# Generates an annular reflector board sized from frequency (inner = 0.29*lambda).
# Round reflector PCB: Edge.Cuts circle, GND zones on F/B, optional mask-open,
# centered SMA (TE CONSMA001-C-G) footprint, and a silkscreen label.
# Places Edge.Cuts circles, GND zones on F.Cu/B.Cu, and plated GND mounting holes.
# Install: copy into your KiCad plugins folder and run from pcbnew (Tools → External Plugins).
#
# Author: Dominique F6EPY + ChatGPT (CC0)
donut_reflector_disk_sma.py  (KiCad 8)

import math
import wx
import pcbnew

# ----------------- KiCad 8 helpers -----------------
def mm(v): return pcbnew.FromMM(v)
def pt_mm(x, y): return pcbnew.VECTOR2I(mm(x), mm(y))   # position/point
def sz_mm(w, h): return pcbnew.VECTOR2I(mm(w), mm(h))   # size/drill

# ----------------- nets -----------------
def ensure_net(board, name: str):
    nets = board.GetNetsByName()
    if name in nets:
        return nets[name]
    ni = pcbnew.NETINFO_ITEM(board, name)
    board.Add(ni)
    return ni

# ----------------- drawing helpers -----------------
def add_edge_circle(board, center_pt, dia_mm):
    s = pcbnew.PCB_SHAPE(board)
    s.SetShape(pcbnew.SHAPE_T_CIRCLE)
    s.SetLayer(pcbnew.Edge_Cuts)
    s.SetCenter(center_pt)
    s.SetEnd(pt_mm(dia_mm/2.0, 0))        # radius point
    s.SetWidth(mm(0.10))
    board.Add(s)

def add_filled_circle(board, layer, center_pt, dia_mm):
    s = pcbnew.PCB_SHAPE(board)
    s.SetShape(pcbnew.SHAPE_T_CIRCLE)
    s.SetLayer(layer)
    s.SetCenter(center_pt)
    s.SetEnd(pt_mm(dia_mm/2.0, 0))
    s.SetWidth(mm(dia_mm))                # irrelevant when filled
    s.SetFilled(True)
    board.Add(s)

def add_silk_label(board, text, at_xy=(0,0), size_mm_val=2.0, layer=pcbnew.F_SilkS):
    t = pcbnew.PCB_TEXT(board)
    t.SetText(text)
    t.SetLayer(layer)
    t.SetPosition(pt_mm(at_xy[0], at_xy[1]))
    # Size (support both APIs)
    try:
        t.SetTextHeight(mm(size_mm_val))
        t.SetTextWidth(mm(size_mm_val))
    except Exception:
        t.SetTextSize(sz_mm(size_mm_val, size_mm_val))
    # Justification (best effort)
    try:
        t.SetHorizJustify(pcbnew.GR_TEXT_H_ALIGN_CENTER)
        t.SetVertJustify(pcbnew.GR_TEXT_V_ALIGN_CENTER)
    except Exception:
        pass
    board.Add(t)
    return t

# ----------------- zones (KiCad 8) -----------------
def add_circular_zone(board, netname, layer, center_xy=(0,0), dia_mm=60.0, nseg=240):
    net = ensure_net(board, netname)
    z = pcbnew.ZONE(board)
    z.SetIsRuleArea(False)
    z.SetLayer(layer)
    z.SetNetCode(net.GetNetCode())  # KiCad 8 API

    # Outline: approximate circle with polygon
    poly = z.Outline()
    poly.NewOutline()
    cx, cy = center_xy
    r = dia_mm/2.0
    for i in range(nseg):
        ang = 2.0*math.pi*i/nseg
        x = cx + r*math.cos(ang)
        y = cy + r*math.sin(ang)
        poly.Append(pt_mm(x, y))

    board.Add(z)
    # Fill all zones (wrapper wants a container; this is safe and simple)
    pcbnew.ZONE_FILLER(board).Fill(board.Zones())
    return z

# ----------------- SMA footprint helpers -----------------
def make_th_pad(parent_fp, name, at_xy, drill_mm, size_mm, net=None):
    pad = pcbnew.PAD(parent_fp)
    pad.SetName(str(name))
    pad.SetShape(pcbnew.PAD_SHAPE_CIRCLE)
    pad.SetPosition(pt_mm(at_xy[0], at_xy[1]))
    pad.SetDrillSize(sz_mm(drill_mm, drill_mm))  # non-zero drill => THT in v8
    pad.SetSize(sz_mm(size_mm, size_mm))
    pad.SetLayerSet(pcbnew.LSET.AllCuMask())
    # Attribute constants moved in v8; drill already marks it as THT
    try:
        pad.SetAttribute(pcbnew.PAD_ATTRIB_THROUGH_HOLE)
    except Exception:
        try:
            pad.SetAttribute(pcbnew.PAD_ATTR_THT)
        except Exception:
            pass
    if net is not None:
        pad.SetNet(net)
    return pad

def add_sma_consma001_cg(board, at_xy=(0.0, 0.0)):
    """
    TE Connectivity CONSMA001-C-G (THT) recommended pattern:
      - Center pin: drill 1.40 mm @ (0,0), pad ~2.20 mm (pad 1, net RF)
      - 4 GND legs: drill 1.50 mm @ (+/-5.10, +/-2.55), pad ~2.40 mm (pads 2..5, net GND)
    """
    fp = pcbnew.FOOTPRINT(board)
    fp.SetReference("J1")
    fp.SetValue("CONSMA001-C-G")
    fp.SetPosition(pt_mm(at_xy[0], at_xy[1]))

    net_rf  = ensure_net(board, "RF")
    net_gnd = ensure_net(board, "GND")

    # Small silk ring for visual aid
    ring = pcbnew.PCB_SHAPE(fp)
    ring.SetShape(pcbnew.SHAPE_T_CIRCLE)
    ring.SetLayer(pcbnew.F_SilkS)
    ring.SetCenter(pt_mm(0,0))
    ring.SetEnd(pt_mm(3.0,0))  # ~Ø6 mm ring
    ring.SetWidth(mm(0.12))
    fp.Add(ring)

    # Pad 1: RF center
    fp.Add(make_th_pad(fp, 1, (0.0, 0.0), drill_mm=1.40, size_mm=2.20, net=net_rf))

    # Pads 2–5: grounds
    for idx, (x, y) in enumerate([( +5.10, +2.55 ),
                                  ( +5.10, -2.55 ),
                                  ( -5.10, +2.55 ),
                                  ( -5.10, -2.55 )], start=2):
        fp.Add(make_th_pad(fp, idx, (x, y), drill_mm=1.50, size_mm=2.40, net=net_gnd))

    board.Add(fp)
    return fp

# ----------------- dialog -----------------
class ReflectorDialog(wx.Dialog):
    def __init__(self, parent=None):
        super().__init__(parent,
                         title="Reflector Disk + SMA (CONSMA001-C-G)",
                         size=(640, 420))
        self.SetMinSize((640, 420))

        # Root sizer on dialog
        root = wx.BoxSizer(wx.VERTICAL)

        # Content panel
        p = wx.Panel(self)
        v = wx.BoxSizer(wx.VERTICAL)

        # Controls
        self.t_diam   = wx.TextCtrl(p, value="62.0")  # set to donut inner diameter
        self.t_label  = wx.TextCtrl(p, value="Backfire Helix 1.42 GHz")
        self.chk_mask = wx.CheckBox(p, label="Open soldermask (bare copper) on both sides")
        self.chk_mask.SetValue(True)

        # Grid that grows
        grid = wx.FlexGridSizer(rows=0, cols=2, vgap=8, hgap=12)
        grid.AddGrowableCol(1, 1)

        grid.Add(wx.StaticText(p, label="Disk diameter (mm):"), 0, wx.ALIGN_CENTER_VERTICAL)
        grid.Add(self.t_diam, 1, wx.EXPAND)

        grid.Add(wx.StaticText(p, label="Silkscreen label:"), 0, wx.ALIGN_CENTER_VERTICAL)
        grid.Add(self.t_label, 1, wx.EXPAND)

        grid.Add(self.chk_mask, 0, wx.ALIGN_LEFT)
        grid.Add((1,1))  # spacer

        v.Add(grid, 1, wx.ALL | wx.EXPAND, 14)
        p.SetSizer(v)

        # Buttons at bottom (always visible)
        btns = self.CreateSeparatedButtonSizer(wx.OK | wx.CANCEL)

        root.Add(p,    1, wx.EXPAND)
        root.Add(btns, 0, wx.ALL | wx.EXPAND, 10)
        self.SetSizer(root)

        # Make OK default
        ok = self.FindWindowById(wx.ID_OK)
        if ok:
            ok.SetDefault()
            ok.SetFocus()

        self.Layout()
        self.CentreOnParent()

    def get_values(self):
        return float(self.t_diam.GetValue()), self.t_label.GetValue(), self.chk_mask.GetValue()

# ----------------- action plugin -----------------
class DonutReflectorWithSMA(pcbnew.ActionPlugin):
    def defaults(self):
        self.name = "Parametric Reflector Disk + SMA (CONSMA001-C-G)"
        self.category = "Generate"
        self.description = "Round reflector board: GND zones, mask-open, CONSMA001-C-G at center"
        self.show_toolbar_button = True
        self.icon_file_name = ""  # optional icon path

    def Run(self):
        board = pcbnew.GetBoard()
        dlg = ReflectorDialog(None)
        if dlg.ShowModal() != wx.ID_OK:
            dlg.Destroy()
            return
        try:
            disk_d_mm, label_text, open_mask = dlg.get_values()
        finally:
            dlg.Destroy()

        center = pt_mm(0, 0)

        # 1) Outline
        add_edge_circle(board, center, disk_d_mm)

        # 2) GND zones (clearance comes from Board Setup / netclass)
        add_circular_zone(board, "GND", pcbnew.F_Cu, center_xy=(0,0), dia_mm=disk_d_mm, nseg=240)
        add_circular_zone(board, "GND", pcbnew.B_Cu, center_xy=(0,0), dia_mm=disk_d_mm, nseg=240)

        # 3) Optional soldermask opening (bare copper reflector)
        if open_mask:
            add_filled_circle(board, pcbnew.F_Mask, center, disk_d_mm)
            add_filled_circle(board, pcbnew.B_Mask, center, disk_d_mm)

        # 4) SMA footprint at center
        add_sma_consma001_cg(board, at_xy=(0.0, 0.0))

        # 5) Silkscreen label near rim
        add_silk_label(board, label_text, at_xy=(0, disk_d_mm/2 - 8.0), size_mm_val=2.0, layer=pcbnew.F_SilkS)

        pcbnew.Refresh()
        wx.MessageBox(
            "Reflector disk generated:\n"
            f"- Edge.Cuts Ø{disk_d_mm:.2f} mm\n"
            "- GND zones on F.Cu / B.Cu (clearance from board rules)\n"
            "- Optional mask-open (F.Mask / B.Mask)\n"
            "- CONSMA001-C-G footprint at (0,0)\n"
            "- Silkscreen label near rim",
            "Done", wx.OK | wx.ICON_INFORMATION
        )

# Register plugin with KiCad
DonutReflectorWithSMA().register()

