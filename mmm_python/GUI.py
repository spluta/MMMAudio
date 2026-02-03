from PySide6.QtWidgets import QApplication, QWidget, QVBoxLayout, QSlider, QPushButton, QLabel, QHBoxLayout
from PySide6.QtCore import Qt, Signal
from PySide6.QtGui import QPainter, QPen, QBrush
from PySide6.QtCore import QPointF

from .python_utils import clip, linlin

class ControlSpec:
    def __init__(self, min: float = 0.0, max: float = 1.0, exp: float = 1.0):
        if min >= max:
            raise ValueError("ControlSpec min must be less than max")
        if exp <= 0:
            raise ValueError("ControlSpec exp must be positive")
        self.min = min
        self.max = max
        self.exp = exp
    
    def normalize(self, val: float) -> float:
        """Normalize a value to the range [0.0, 1.0] based on the control spec."""
        norm_val = linlin(val, self.min, self.max, 0.0, 1.0)
        return clip(norm_val ** self.exp, 0.0, 1.0)

    def unnormalize(self, norm_val: float) -> float:
        """Convert a normalized value [0.0, 1.0] back to the control spec range."""
        norm_val = clip(norm_val, 0.0, 1.0) ** (1.0 / self.exp)
        return linlin(norm_val, 0.0, 1.0, self.min, self.max)

class Handle(QWidget):
    def __init__(self, label: str, spec: ControlSpec = ControlSpec(), default: float = 0.0, callback=None, orientation=Qt.Horizontal, resolution: int = 1000, run_callback_on_init: bool = False):
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
        
class Slider2D(QWidget):
    """A custom 2D slider widget"""
    
    # Signal emitted when the slider value changes
    value_changed = Signal(float, float)
    mouse_updown = Signal(bool)
    
    def __init__(self, width=300, height=300, parent=None):
        super().__init__(parent)
        self.setMinimumSize(width, height)
        self.setMaximumSize(width, height)
        
        # Slider position (0.0 to 1.0 for both x and y)
        self._x = 0.5
        self._y = 0.5
        
        self._handle_radius = 10
        
    def get_values(self):
        """Get current X and Y values (0.0 to 1.0)"""
        return self._x, self._y
    
    def set_values(self, x, y):
        """Set X and Y values (0.0 to 1.0)"""
        self._x = max(0.0, min(1.0, x))
        self._y = max(0.0, min(1.0, y))
        self.update()
        self.value_changed.emit(self._x, self._y)
    
    def _pos_to_values(self, pos):
        """Convert widget position to slider values"""
        margin = self._handle_radius
        width = self.width() - 2 * margin
        height = self.height() - 2 * margin
        
        x = (pos.x() - margin) / width
        y = 1.0 - (pos.y() - margin) / height  # Invert Y so bottom is 0
        
        return max(0.0, min(1.0, x)), max(0.0, min(1.0, y))
    
    def _values_to_pos(self):
        """Convert slider values to widget position"""
        margin = self._handle_radius
        width = self.width() - 2 * margin
        height = self.height() - 2 * margin
        
        x = margin + self._x * width
        y = margin + (1.0 - self._y) * height  # Invert Y so bottom is 0
        
        return QPointF(x, y)
    
    def paintEvent(self, event):
        """Paint the slider"""
        painter = QPainter(self)
        painter.setRenderHint(QPainter.Antialiasing)
        
        # Draw background
        painter.fillRect(self.rect(), Qt.lightGray)
        
        # Draw border
        pen = QPen(Qt.black, 2)
        painter.setPen(pen)
        painter.drawRect(self.rect())
        
        # Draw grid lines
        pen = QPen(Qt.gray, 1)
        painter.setPen(pen)
        
        # Vertical lines
        for i in range(1, 4):
            x = self.width() * i / 4
            painter.drawLine(x, 0, x, self.height())
        
        # Horizontal lines
        for i in range(1, 4):
            y = self.height() * i / 4
            painter.drawLine(0, y, self.width(), y)
        
        # Draw center lines
        pen = QPen(Qt.darkGray, 2)
        painter.setPen(pen)
        center_x = self.width() / 2
        center_y = self.height() / 2
        painter.drawLine(center_x, 0, center_x, self.height())
        painter.drawLine(0, center_y, self.width(), center_y)
        
        # Draw handle
        handle_pos = self._values_to_pos()
        brush = QBrush(Qt.blue)
        painter.setBrush(brush)
        pen = QPen(Qt.darkBlue, 2)
        painter.setPen(pen)
        painter.drawEllipse(handle_pos, self._handle_radius, self._handle_radius)
    
    def mousePressEvent(self, event):
        """Handle mouse press"""
        if event.button() == Qt.LeftButton:
            self.mouse_updown.emit(True)
            x, y = self._pos_to_values(event.position())
            self.set_values(x, y)
    
    def mouseMoveEvent(self, event):
        """Handle mouse move"""
        if self.mouse_updown:
            x, y = self._pos_to_values(event.position())
            self.set_values(x, y)
    
    def mouseReleaseEvent(self, event):
        """Handle mouse release"""
        if event.button() == Qt.LeftButton:
            self.mouse_updown.emit(False)
        
    