from python import PythonObject
from python import Python
from python.bindings import PythonModuleBuilder
from os import abort
from mmm_audio import *

@export
fn PyInit_MBufAnalysisBridge() -> PythonObject:
    try:
        var m = PythonModuleBuilder("MBufAnalysisBridge")
        m.def_function[MBufAnalysisBridge.rms]("rms")
        m.def_function[MBufAnalysisBridge.custom]("custom")
        return m.finalize()
    except e:
        abort(String("error creating Python Mojo module:", e))

struct AnalysisParams:
    var buf: Buffer
    var chan: Int
    var start_frame: Int
    var num_frames: Int
    var window_size: Int
    var hop_size: Int

    fn __init__(out self, py_dict: PythonObject) raises:
        self.buf = Buffer.load(String(py=py_dict["path"]))
        self.chan = Int(py=py_dict["chan"]) if "chan" in py_dict else 0
        self.start_frame = Int(py=py_dict["start_frame"]) if "start_frame" in py_dict else 0
        self.num_frames = Int(py=py_dict["num_frames"]) if "num_frames" in py_dict else Int(self.buf.num_frames) - self.start_frame
        self.window_size = Int(py=py_dict["window_size"]) if "window_size" in py_dict else 1024
        self.hop_size = Int(py=py_dict["hop_size"]) if "hop_size" in py_dict else self.window_size // 2

struct MBufAnalysisBridge:

    @staticmethod
    fn rms(py_dict: PythonObject) raises -> PythonObject:

        # make the analysis params instance
        analysis_params = AnalysisParams(py_dict)

        # define the window function that will be called for each window of audio. 
        # It has to be a function that takes a List[Float64] and returns a List[Float64] 
        # (even if it's just one value) so that it's consistent with other analyses we 
        # might want to add later
        fn rmsanalysis(mut window: List[Float64]) -> List[Float64]:
            return [RMS.from_window(window)]

        # run the analysis
        result = MBufAnalysisBridge.analyze(rmsanalysis, analysis_params)
        
        # return it as a numpy array
        return MBufAnalysisBridge.list_to_numpy(result)

    @staticmethod
    fn analyze(window_fn: fn(mut List[Float64]) -> List[Float64], analysis_params: AnalysisParams) raises -> List[List[Float64]]:
        result = List[List[Float64]]()
        frame: Int64 = analysis_params.start_frame
        window = List[Float64](length=analysis_params.window_size,fill=0.0)
        while frame < analysis_params.start_frame + analysis_params.num_frames:
            for i in range(analysis_params.window_size):
                if frame + i < analysis_params.buf.num_frames:
                    window[i] = analysis_params.buf.data[analysis_params.chan][frame + i]
                else:
                    window[i] = 0.0
            analysis_result = window_fn(window)
            # It's gotta be an array of arrays because other analyses might return multiple values
            # This way they'll all be consistent
            result.append(analysis_result^)
            frame += analysis_params.hop_size
        return result^

    @staticmethod
    fn list_to_numpy(list: List[List[Float64]]) raises -> PythonObject:
        np = Python.import_module("numpy")
        shape = Python.tuple(Int(len(list)), Int(len(list[0])))
        nparray = np.zeros(shape=shape,dtype=np.float64)
        for i in range(len(list)):
            for j in range(len(list[i])):
                nparray[i][j] = list[i][j]
        return nparray

    @staticmethod
    fn custom(py_path: PythonObject) raises -> PythonObject:
        path = String(py=py_path)
        print("custom analysis called, not yet implemented", path)
        return 42