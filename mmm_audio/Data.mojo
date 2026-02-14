from mojmelo.utils.KDTree import KDTree, KDTreeResultVector
from mojmelo.utils.Matrix import Matrix
from python import PythonObject, Python

struct MKDTree(Movable,Copyable):
    var tree: KDTree[]
    var resultvector: KDTreeResultVector

    fn __init__(out self, mat: Matrix) raises:
        self.tree = KDTree(mat)
        self.resultvector = KDTreeResultVector()

    fn n_nearest(mut self, mut qv: List[Float32], n: Int) -> Int:
        self.tree.n_nearest(qv, n, self.resultvector)
        return self.resultvector[0].idx

fn main():
    try:
        np = Python.import_module("numpy")
        shape: PythonObject = Python.tuple(Int(3), Int(3))
        ndarray = np.ndarray(shape=shape, dtype=np.float32)
        for i in range(3):
            for j in range(3):
                ndarray[i][j] = i * 3 + j

        mat = Matrix.from_numpy(ndarray)
        tree = MKDTree(mat)
        qv: List[Float32] = [0.0, 1.0, 2.0]
        idx = tree.n_nearest(qv,2)
        print("result:", idx)
    except e:
        print("Error:", e)