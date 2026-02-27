import sys
from pathlib import Path
import numpy as np

sys.path.insert(0, str(Path(__file__).parent.parent))

from mmm_python import *
from PySide6.QtWidgets import QApplication, QMainWindow, QGraphicsView, QGraphicsScene, QGraphicsRectItem
from PySide6.QtCore import Signal, QObject, Qt
from PySide6.QtGui import QBrush, QPen, QColor

class SpectrogramGraphicsView(QGraphicsView):
    
    def __init__(self, num_bars=513, parent=None):
        super().__init__(parent)
        self.num_bars = num_bars
        self.bar_height = 400
        
        self.scene = QGraphicsScene(self)
        self.setScene(self.scene)
        
        self.setHorizontalScrollBarPolicy(Qt.ScrollBarAlwaysOff)
        self.setVerticalScrollBarPolicy(Qt.ScrollBarAlwaysOff)
        self.setRenderHint(self.renderHints().Antialiasing, False)
        self.setViewportUpdateMode(QGraphicsView.MinimalViewportUpdate)
        self.setOptimizationFlags(QGraphicsView.DontSavePainterState)
        self.setBackgroundBrush(QBrush(QColor(0, 0, 0)))
        
        self.bars = []
        self.bar_width = 800 / num_bars
        brush = QBrush(QColor(255, 255, 255))
        pen = QPen(Qt.NoPen)
        
        for i in range(num_bars):
            bar = QGraphicsRectItem(0, 0, self.bar_width, 0)
            bar.setBrush(brush)
            bar.setPen(pen)
            bar.setPos(i * self.bar_width, self.bar_height)
            self.scene.addItem(bar)
            self.bars.append(bar)
        
        self.scene.setSceneRect(0, 0, 800, self.bar_height)
        self.setMinimumSize(800, 400)
    
    def update_data(self, data):
        for i, mag in enumerate(data):
            normalized = mag / 15.0
            bar_height = normalized * self.bar_height
            
            self.bars[i].setRect(0, 0, self.bar_width, bar_height)
            self.bars[i].setPos(i * self.bar_width, self.bar_height - bar_height)
    
    def resizeEvent(self, event):
        super().resizeEvent(event)
        self.fitInView(self.scene.sceneRect(), Qt.IgnoreAspectRatio)


class SpectrogramWindow(QMainWindow):
    data_ready = Signal(object)

    def __init__(self):
        super().__init__()
        self.setWindowTitle("Real-time Spectrogram")
        
        self.spectrogram_widget = SpectrogramGraphicsView(num_bars=513)
        self.setCentralWidget(self.spectrogram_widget)
        
        self.data_ready.connect(self.spectrogram_widget.update_data)
        
    def callback(self, args):
        self.data_ready.emit(args)
    
    def closeEvent(self, event):
        QApplication.quit()
        event.accept()


if __name__ == "__main__":
    
    app = QApplication()
    
    window = SpectrogramWindow()
    window.show()
    
    m = MMMAudio(128, graph_name="SpectrogramExample", package_name="examples")
    m.register_callback("mags", window.callback)
    m.start_audio()

    def shutdown():
        m.stop_audio()
        m.stop_process()

    app.aboutToQuit.connect(shutdown)
    
    sys.exit(app.exec())