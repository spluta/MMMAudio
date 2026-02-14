from mojmelo import *
from python import PythonObject

struct MKDTree(Movable,Copyable):
    var tree: KDTree

    fn __init__(out self):
        self.tree = KDTree()

    fn from_numpy(out self, data: PythonObject):
        self.tree.from_numpy(data)

    fn k_nearest(self):
        pass
