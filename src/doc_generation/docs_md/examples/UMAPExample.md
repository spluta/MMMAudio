*For more information about the examples, such as how the Python and Mojo files interact with each other, see the [Examples Overview](index.md)*

# UMAPExample

<!-- Use mkdocs ":::" syntax to get docstring from Python file -->
:::examples.UMAPExample
    options:
      members: []


## Python Code
<!-- Puts the remaining lines from the Python script here -->
```python

from PySide6.QtWidgets import QApplication
from pathlib import Path
import sys
sys.path.insert(0, str(Path(__file__).parent.parent))
from mmm_python import *
from umap import UMAP
from sklearn.neighbors import KDTree

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

win = MPlot(reducs, mouse_callback=get_nearest)
win.resize(700, 500)
win.show()
app.exec()

```

## Mojo Code
<!-- Put the contents of the .mojo file *of the same name!* here -->
```mojo

--8<-- "examples/UMAPExample.mojo"

```