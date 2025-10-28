from PySide6.QtWidgets import QApplication, QWidget, QVBoxLayout, QSlider, QPushButton, QLabel, QHBoxLayout
from PySide6.QtCore import Qt
from .functions import clip, scale

class ControlSpec:
    def __init__(self, min: float, max: float, exp: float = 1.0):
        if min >= max:
            raise ValueError("ControlSpec min must be less than max")
        if exp <= 0:
            raise ValueError("ControlSpec exp must be positive")
        self.min = min
        self.max = max
        self.exp = exp
    
    def normalize(self, val: float) -> float:
        """Normalize a value to the range [0.0, 1.0] based on the control spec."""
        norm_val = scale(val, self.min, self.max, 0.0, 1.0)
        return clip(norm_val ** self.exp, 0.0, 1.0)

    def unnormalize(self, norm_val: float) -> float:
        """Convert a normalized value [0.0, 1.0] back to the control spec range."""
        norm_val = clip(norm_val, 0.0, 1.0) ** (1.0 / self.exp)
        return scale(norm_val, 0.0, 1.0, self.min, self.max)

class Handle(QWidget):
    def __init__(self, label: str, spec: ControlSpec, default: float, callback=None, orientation=Qt.Horizontal, resolution: int = 1000, run_callback_on_init: bool = False):
        super().__init__()
        self.resolution = resolution
        self.handle = QSlider(orientation)
        self.display = QLabel(f"{default:.4f}")
        self.label = QLabel(label)
        self.layout = QHBoxLayout()
        self.layout.addWidget(self.label)
        self.layout.addWidget(self.handle)
        self.layout.addWidget(self.display)
        self.setLayout(self.layout)
        self.handle.setMinimum(0)
        self.handle.setMaximum(resolution)
        self.spec = spec
        self.handle.setValue(int(spec.normalize(clip(default, spec.min, spec.max)) * resolution))
        self.callback = callback
        self.handle.valueChanged.connect(self.update)
        if run_callback_on_init:
            self.update()
        
    def update(self):
        v = self.get_value()
        self.display.setText(f"{v:.2f}")
        if self.callback:
            self.callback(v)

    def get_value(self):
        return self.spec.unnormalize(self.handle.value() / self.resolution)
    
    def set_value(self, value: float):
        value = self.spec.normalize(clip(value, self.spec.min, self.spec.max))
        self.handle.setValue(int(value * self.resolution))
        
    