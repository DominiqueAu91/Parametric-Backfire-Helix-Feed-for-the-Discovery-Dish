# donut_reflector_disk_sma.py  — KiCad 8
# Round reflector PCB: Edge.Cuts circle, GND zones (F/B), optional mask-open,
# centered TE CONSMA001-C-G SMA, silkscreen label, plus frequency→diameter calculator.

import math
import wx
import pcbnew

# ----------------- KiCad 8 helpers -----------------
def mm(v): return pcbnew.FromMM(v)
def pt_mm(x, y): return pcbnew.VECTOR2I(mm(x), mm(y))     # point/position
def sz_mm(w, h): return pcbnew.VECTOR2I(mm(w), mm(h))     # size/drill

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
    s.SetEnd(pt_mm(dia_mm/2.0, 0))      # radius point
    s.SetWidth(mm(0.10))
    board.Add(s)

def add_filled_circle(board, layer, center_pt, dia_mm):
    s = pcbnew.PCB_SHAPE(board)
    s.SetShape(pcbnew.SHAPE_T_CIRCLE)
    s.SetLayer(layer)
    s.SetCenter(center_pt)
    s.SetEnd(pt_mm(dia_mm/2.0, 0))
    s.SetWidth(mm(dia_mm))              # irrelevant when filled
    s.SetFilled(True)
    board.Add(s)

def add_silk_label(board, text, at_xy=(0,0), size_mm_val=2.0, layer=pcbnew.F_SilkS):
    t = pcbnew.PCB_TEXT(board)
    t.SetText(text)
    t.SetLayer(layer)
    t.SetPosition(pt_mm(at_xy[0], at_xy[1]))
    # size (support both APIs)
    try:
        t.SetTextHeight(mm(size_mm_val)); t.SetTextWidth(mm(size_mm_val))
    except Exception:
        t.SetTextSize(sz_mm(size_mm_val, size_mm_val))
    # center it (best-effort across builds)
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
    z.SetNetCode(net.GetNetCode())  # KiCad 8
    # outline: circle approx
    poly = z.Outline(); poly.NewOutline()
    cx, cy = center_xy; r = dia_mm/2.0
    for i in range(nseg):
        ang = 2.0*math.pi*i/nseg
        x = cx + r*math.cos(ang); y = cy + r*math.sin(ang)
        poly.Append(pt_mm(x, y))
    board.Add(z)
    # fill all zones (wrapper expects container)
    pcbnew.ZONE_FILLER(board).Fill(board.Zones())
    return z

# ----------------- SMA footprint helpers -----------------
def make_th_pad(parent_fp, name, at_xy, drill_mm, size_w_mm, size_h_mm, net=None, shape_square=False):
    pad = pcbnew.PAD(parent_fp)
    pad.SetName(str(name))
    # shape: square rectangles for GND legs if requested
    if shape_square and abs(size_w_mm - size_h_mm) < 1e-6:
        pad.SetShape(pcbnew.PAD_SHAPE_RECT)
    else:
        pad.SetShape(pcbnew.PAD_SHAPE_CIRCLE)
    pad.SetPosition(pt_mm(at_xy[0], at_xy[1]))
    pad.SetDrillSize(sz_mm(drill_mm, drill_mm))          # non-zero drill => THT in v8
    pad.SetSize(sz_mm(size_w_mm, size_h_mm))
    pad.SetLayerSet(pcbnew.LSET.AllCuMask())
    # attribute constants moved; drill already implies THT
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

def add_sma_consma001_cg(board, at_xy=(0.0, 0.0), square_gnd=True):
    """
    TE CONSMA001-C-G (THT) recommended pattern:
      Center pin: drill 1.40 mm @ (0,0), pad ≈ 2.20 mm (Pad 1, RF)
      4 GND legs: drill 1.50 mm @ (+/-5.10, +/-2.55), pad ≈ 2.40 mm (Pads 2..5, GND)
      'square_gnd=True' makes the four ground pad annuli square.
    """
    fp = pcbnew.FOOTPRINT(board)
    fp.SetReference("J1"); fp.SetValue("CONSMA001-C-G")
    fp.SetPosition(pt_mm(at_xy[0], at_xy[1]))
    net_rf  = ensure_net(board, "RF")
    net_gnd = ensure_net(board, "GND")

    # small silk ring for visual aid
    ring = pcbnew.PCB_SHAPE(fp)
    ring.SetShape(pcbnew.SHAPE_T_CIRCLE)
    ring.SetLayer(pcbnew.F_SilkS)
    ring.SetCenter(pt_mm(0,0)); ring.SetEnd(pt_mm(3.0,0))  # ~Ø6 mm
    ring.SetWidth(mm(0.12)); fp.Add(ring)

    # Pad 1: RF center (round annulus)
    fp.Add(make_th_pad(fp, 1, (0.0, 0.0), drill_mm=1.40, size_w_mm=2.20, size_h_mm=2.20, net=net_rf, shape_square=False))

    # Pads 2–5: GND legs (square annulus)
    for idx, (x, y) in enumerate([( +5.10, +2.55 ),
                                  ( +5.10, -2.55 ),
                                  ( -5.10, +2.55 ),
                                  ( -5.10, -2.55 )], start=2):
        fp.Add(make_th_pad(fp, idx, (x, y), drill_mm=1.50, size_w_mm=2.40, size_h_mm=2.40,
                           net=net_gnd, shape_square=square_gnd))

    board.Add(fp)
    return fp

# ----------------- dialog -----------------
class ReflectorDialog(wx.Dialog):
    def __init__(self, parent=None):
        super().__init__(parent,
                         title="Reflector Disk + SMA (CONSMA001-C-G)",
                         size=(680, 460))
        self.SetMinSize((680, 460))

        root = wx.BoxSizer(wx.VERTICAL)

        # content panel
        p = wx.Panel(self); v = wx.BoxSizer(wx.VERTICAL)

        # --- Frequency → diameter calculator ---
        freq_row = wx.BoxSizer(wx.HORIZONTAL)
        self.chk_use_f = wx.CheckBox(p, label="Compute disk diameter from frequency:")
        self.t_freq    = wx.TextCtrl(p, value="1420.0", size=(100,-1))
        freq_row.Add(self.chk_use_f, 0, wx.RIGHT|wx.ALIGN_CENTER_VERTICAL, 8)
        freq_row.Add(wx.StaticText(p, label="f (MHz):"), 0, wx.ALIGN_CENTER_VERTICAL|wx.RIGHT, 6)
        freq_row.Add(self.t_freq, 0, wx.RIGHT, 12)

        self.lbl_calc = wx.StaticText(p, label="λ=211.0 mm → D_reflector≈61.2 mm, D_helix≈67.5 mm")
        v.Add(freq_row, 0, wx.ALL, 10)
        v.Add(self.lbl_calc, 0, wx.LEFT|wx.RIGHT|wx.BOTTOM, 10)

        # --- Core parameters ---
        grid = wx.FlexGridSizer(rows=0, cols=2, vgap=8, hgap=12)
        grid.AddGrowableCol(1, 1)

        self.t_diam   = wx.TextCtrl(p, value="61.2")  # donut inner Ø or computed
        self.t_label  = wx.TextCtrl(p, value="Backfire Helix 1.42 GHz")
        self.chk_mask = wx.CheckBox(p, label="Open soldermask (bare copper) on both sides")
        self.chk_mask.SetValue(True)

        grid.Add(wx.StaticText(p, label="Disk diameter (mm):"), 0, wx.ALIGN_CENTER_VERTICAL); grid.Add(self.t_diam, 1, wx.EXPAND)
        grid.Add(wx.StaticText(p, label="Silkscreen label:"),   0, wx.ALIGN_CENTER_VERTICAL); grid.Add(self.t_label, 1, wx.EXPAND)
        grid.Add(self.chk_mask, 0, wx.ALIGN_LEFT); grid.Add((1,1))

        # --- Layout assemble ---
        v.Add(grid, 0, wx.LEFT|wx.RIGHT|wx.BOTTOM|wx.EXPAND, 12)
        p.SetSizer(v)

        btns = self.CreateSeparatedButtonSizer(wx.OK | wx.CANCEL)
        root.Add(p,    1, wx.EXPAND)
        root.Add(btns, 0, wx.ALL|wx.EXPAND, 10)
        self.SetSizer(root)

        # defaults
        self.chk_use_f.SetValue(True)
        self._update_from_freq()

        # events
        self.t_freq.Bind(wx.EVT_TEXT, lambda evt: self._update_from_freq())
        self.chk_use_f.Bind(wx.EVT_CHECKBOX, lambda evt: self._update_from_freq())

        self.Layout(); self.CentreOnParent()

    @staticmethod
    def _lambda_mm_from_mhz(f_mhz: float) -> float:
        # λ (mm) = c_mm_per_s / f(Hz) = 299792.458 mm/ns * 1e9 / (f_MHz * 1e6) = 299792.458 / f_MHz
        return 299792.458 / f_mhz if f_mhz > 0 else 0.0

    def _update_from_freq(self):
        try:
            f = float(self.t_freq.GetValue())
            lam = self._lambda_mm_from_mhz(f) if f > 0 else 0.0
            d_ref = 0.29 * lam
            d_hex = 0.32 * lam
            self.lbl_calc.SetLabel(f"λ={lam:.1f} mm → D_reflector≈{d_ref:.1f} mm, D_helix≈{d_hex:.1f} mm")
            if self.chk_use_f.GetValue() and d_ref > 0:
                self.t_diam.SetValue(f"{d_ref:.1f}")
        except Exception:
            # leave previous values; display neutral text
            self.lbl_calc.SetLabel("Enter a valid frequency in MHz (e.g., 1420.0)")
        self.Layout()

    def get_values(self):
        return (
            float(self.t_diam.GetValue()),
            self.t_label.GetValue(),
            self.chk_mask.GetValue()
        )

# ----------------- action plugin -----------------
class DonutReflectorWithSMA(pcbnew.ActionPlugin):
    def defaults(self):
        self.name = "Parametric Reflector Disk + SMA (CONSMA001-C-G)"
        self.category = "Generate"
        self.description = "Round reflector board: GND zones, optional mask-open, CONSMA001-C-G at center"
        self.show_toolbar_button = True
        self.icon_file_name = ""

    def Run(self):
        board = pcbnew.GetBoard()
        dlg = ReflectorDialog(None)
        if dlg.ShowModal() != wx.ID_OK:
            dlg.Destroy(); return
        try:
            disk_d_mm, label_text, open_mask = dlg.get_values()
        finally:
            dlg.Destroy()

        center = pt_mm(0, 0)

        # 1) outline
        add_edge_circle(board, center, disk_d_mm)

        # 2) GND zones (clearance per Board Setup / netclasses)
        add_circular_zone(board, "GND", pcbnew.F_Cu, center_xy=(0,0), dia_mm=disk_d_mm, nseg=240)
        add_circular_zone(board, "GND", pcbnew.B_Cu, center_xy=(0,0), dia_mm=disk_d_mm, nseg=240)

        # 3) optional soldermask opening (bare copper reflector)
        if open_mask:
            add_filled_circle(board, pcbnew.F_Mask, center, disk_d_mm)
            add_filled_circle(board, pcbnew.B_Mask, center, disk_d_mm)

        # 4) SMA at center (with square GND pads)
        add_sma_consma001_cg(board, at_xy=(0.0, 0.0), square_gnd=True)

        # 5) silkscreen label near rim (move inward a bit so it’s not in the Cu→edge gap)
        inset = 8.0
        add_silk_label(board, label_text, at_xy=(0, disk_d_mm/2 - inset), size_mm_val=2.0, layer=pcbnew.F_SilkS)

        pcbnew.Refresh()
        wx.MessageBox(
            "Reflector disk generated:\n"
            f"- Edge.Cuts Ø{disk_d_mm:.1f} mm\n"
            "- GND zones on F.Cu / B.Cu (clearance from board rules)\n"
            "- Optional mask-open\n"
            "- CONSMA001-C-G at center (square GND pads)\n"
            "- Silkscreen label placed near rim",
            "Done", wx.OK | wx.ICON_INFORMATION
        )

# Register plugin
DonutReflectorWithSMA().register()
