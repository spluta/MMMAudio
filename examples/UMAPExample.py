import numpy as np
from PySide6.QtCore import Qt
from PySide6.QtWidgets import QApplication, QMainWindow, QWidget, QVBoxLayout
from matplotlib.backends.backend_qtagg import FigureCanvasQTAgg as FigureCanvas
from matplotlib.figure import Figure
from matplotlib import colors as mcolors
from pathlib import Path
import sys
sys.path.insert(0, str(Path(__file__).parent.parent))
from mmm_python import *
from umap import UMAP
from sklearn.neighbors import KDTree

class MPlot(QMainWindow):
    def __init__(self, points, on_mouse_move=None, xlabel=None, ylabel=None):
        super().__init__()
        self.on_mouse_move = on_mouse_move
        self._pressed_button = None
        self._modifiers = set()
        self._points = points

        self.fig = Figure(figsize=(5, 4), dpi=100)
        self.canvas = FigureCanvas(self.fig)
        self.canvas.setFocusPolicy(Qt.StrongFocus)
        self.canvas.setFocus()
        self.ax = self.fig.add_subplot(111)

        self._scatter = self.ax.scatter(points[:, 0], points[:, 1], s=4, zorder=1)
        self._highlight_color = mcolors.to_rgba("orange")
        self._highlight_index = None
        self._highlight_marker = self.ax.scatter(
            [],
            [],
            s=30,
            color=self._highlight_color,
            edgecolors="black",
            linewidths=0.5,
            zorder=3,
        )
    
        if xlabel:
            self.ax.set_xlabel(xlabel)
        if ylabel:
            self.ax.set_ylabel(ylabel)

        self.canvas.mpl_connect("motion_notify_event", self._on_motion)
        self.canvas.mpl_connect("button_press_event", self._on_press)
        self.canvas.mpl_connect("button_release_event", self._on_release)
        self.canvas.mpl_connect("key_press_event", self._on_key_press)
        self.canvas.mpl_connect("key_release_event", self._on_key_release)
        self.canvas.mpl_connect("scroll_event", self._on_scroll)

        root = QWidget()
        layout = QVBoxLayout(root)
        layout.addWidget(self.canvas)
        self.setCentralWidget(root)

    def _on_motion(self, event):
        # event.xdata, event.ydata are in data coords; None if outside axes
        if self._pressed_button is None:
            return
        self._emit_point(event, is_dragging=True)

    def _on_press(self, event):
        if event.inaxes != self.ax:
            return
        self._pressed_button = event.button
        self._emit_point(event, is_dragging=False)

    def _on_release(self, event):
        if event.button == self._pressed_button:
            self._pressed_button = None

    def _on_scroll(self, event):
        if event.inaxes != self.ax:
            return
        self._emit_point(event, is_dragging=False)

    def _on_key_press(self, event):
        self._update_modifiers(event, pressed=True)

    def _on_key_release(self, event):
        self._update_modifiers(event, pressed=False)

    def _update_modifiers(self, event, pressed):
        if not event.key:
            return
        keys = event.key.split("+")
        for key in keys:
            if pressed:
                self._modifiers.add(key)
            else:
                self._modifiers.discard(key)

    def _emit_point(self, event, is_dragging):
        if event.inaxes != self.ax or event.xdata is None or event.ydata is None:
            return
        key = self._modifiers_from_event(event)
        button = event.button if event.button is not None else self._pressed_button
        step = getattr(event, "step", None)
        step = step if step != 0 else None
        dblclick = getattr(event, "dblclick", False)
        if self.on_mouse_move:
            self.on_mouse_move(
                self,
                event.xdata,
                event.ydata,
                button,
                is_dragging,
                key,
                dblclick,
                step,
            )

    def _modifiers_from_event(self, event):
        gui_event = getattr(event, "guiEvent", None)
        if gui_event is not None:
            mods = gui_event.modifiers()
            names = []
            if mods & Qt.ShiftModifier:
                names.append("shift")
            if mods & Qt.ControlModifier:
                names.append("cmd")
            if mods & Qt.AltModifier:
                names.append("alt")
            if mods & Qt.MetaModifier:
                names.append("ctrl")
            return "+".join(names) if names else None
        if self._modifiers:
            return "+".join(sorted(self._modifiers))
        return None

    def highlight_index(self, idx):
        if idx is None or idx < 0 or idx >= len(self._points):
            return
        self._highlight_index = idx
        self._highlight_marker.set_offsets(self._points[idx])
        self.canvas.draw_idle()

app = QApplication([])

mfccs = MBufAnalysis.mfcc({"path": "resources/Shiverer.wav"})
print("MFCC shape:", mfccs.shape)

reducs = UMAP().fit_transform(mfccs)
kdtree = KDTree(reducs)

def get_nearest(view, x, y, button, is_dragging, key, dblclick, step):
    if step is None:
        dist, idx = kdtree.query([[x, y]], k=1)
        view.highlight_index(int(idx[0][0]))
        print(
            f"Nearest idx: {idx[0][0]}, dist: {dist[0][0]:.4f}"
        )

win = MPlot(reducs, on_mouse_move=get_nearest)
win.resize(700, 500)
win.show()
app.exec()