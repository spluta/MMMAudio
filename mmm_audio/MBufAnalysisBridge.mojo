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
        m.def_function[MBufAnalysisBridge.yin]("yin")
        m.def_function[MBufAnalysisBridge.mfcc]("mfcc")
        m.def_function[MBufAnalysisBridge.mel_bands]("mel_bands")
        m.def_function[MBufAnalysisBridge.spectral_centroid]("spectral_centroid")
        # m.def_function[MBufAnalysisBridge.custom]("custom")
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
    # TODO: padding

    fn __init__(out self, py_dict: PythonObject) raises:
        self.buf = Buffer.load(String(py=py_dict["path"]))
        self.chan = Int(py=py_dict["chan"]) if "chan" in py_dict else 0
        self.start_frame = Int(py=py_dict["start_frame"]) if "start_frame" in py_dict else 0
        self.num_frames = Int(py=py_dict["num_frames"]) if "num_frames" in py_dict else Int(self.buf.num_frames) - self.start_frame
        self.window_size = Int(py=py_dict["window_size"]) if "window_size" in py_dict else 1024
        self.hop_size = Int(py=py_dict["hop_size"]) if "hop_size" in py_dict else self.window_size // 2

struct MBufAnalysisBridge:

    @staticmethod
    fn mel_bands(py_dict: PythonObject) raises -> PythonObject:

        ap = AnalysisParams(py_dict)
        num_bands = Int(py=py_dict["num_bands"]) if "num_bands" in py_dict else 40
        min_freq = Float64(py=py_dict["min_freq"]) if "min_freq" in py_dict else 20.0
        max_freq = Float64(py=py_dict["max_freq"]) if "max_freq" in py_dict else 20000.0

        mel_bands = MelBands(ap.buf.sample_rate, num_bands, min_freq, max_freq, ap.window_size)
        result = MBufAnalysisBridge.fft_process[WindowType.hann](mel_bands, ap)

        return MBufAnalysisBridge.list_to_numpy(result)

    @staticmethod
    fn mfcc(py_dict: PythonObject) raises -> PythonObject:
        # make the analysis params instance
        ap = AnalysisParams(py_dict)
        num_bands = Int(py=py_dict["num_bands"]) if "num_bands" in py_dict else 40
        num_coeffs = Int(py=py_dict["num_coeffs"]) if "num_coeffs" in py_dict else 13
        min_freq = Float64(py=py_dict["min_freq"]) if "min_freq" in py_dict else 20.0
        max_freq = Float64(py=py_dict["max_freq"]) if "max_freq" in py_dict else 20000.0

        # # run the analysis
        mfcc = MFCC(ap.buf.sample_rate, num_coeffs, num_bands, min_freq, max_freq, ap.window_size)
        result = MBufAnalysisBridge.fft_process[WindowType.hann](mfcc, ap)
        
        # return it as a numpy array
        return MBufAnalysisBridge.list_to_numpy(result)

    @staticmethod
    fn rms(py_dict: PythonObject) raises -> PythonObject:

        # make the analysis params instance
        analysis_params = AnalysisParams(py_dict)

        # # run the analysis
        rms = RMS()
        result = MBufAnalysisBridge.buffered_process(rms, analysis_params)
        
        # return it as a numpy array
        return MBufAnalysisBridge.list_to_numpy(result)

    @staticmethod
    fn yin(py_dict: PythonObject) raises -> PythonObject:
        
        # make the analysis params instance
        ap = AnalysisParams(py_dict)

        # params specific to this analysis
        min_freq = Float64(py=py_dict["min_freq"]) if "min_freq" in py_dict else 20.0
        max_freq = Float64(py=py_dict["max_freq"]) if "max_freq" in py_dict else 20000.0

        # define the window function that will be called for each window of audio. 
        # It has to be a function that takes a List[Float64] and returns a List[Float64] 
        # (even if it's just one value) so that it's consistent with other analyses we 
        # might want to add later
        yin = YIN(ap.buf.sample_rate, ap.window_size, min_freq=min_freq, max_freq=max_freq)

        # run the analysis
        result = MBufAnalysisBridge.buffered_process(yin,ap)
        
        # return it as a numpy array
        return MBufAnalysisBridge.list_to_numpy(result)

    @staticmethod
    fn spectral_centroid(py_dict: PythonObject) raises -> PythonObject:
        # make the analysis params instance
        analysis_params = AnalysisParams(py_dict)
        min_freq = Float64(py=py_dict["min_freq"]) if "min_freq" in py_dict else 20.0
        max_freq = Float64(py=py_dict["max_freq"]) if "max_freq" in py_dict else 20000.0
        power_mag = Bool(py=py_dict["power_mag"]) if "power_mag" in py_dict else False

        # # run the analysis
        sc = SpectralCentroid(analysis_params.buf.sample_rate, min_freq=min_freq, max_freq=max_freq, power_mag=power_mag)
        result = MBufAnalysisBridge.fft_process[WindowType.hann](sc, analysis_params)
        
        # return it as a numpy array
        return MBufAnalysisBridge.list_to_numpy(result)

    # TODO: add windowing
    @staticmethod
    fn buffered_process[T: GetFeaturable & BufferedProcessable](mut analyzer: T,analysis_params: AnalysisParams) raises -> List[List[Float64]]:
        result = List[List[Float64]]()
        frame: Int64 = analysis_params.start_frame
        window = List[Float64](length=analysis_params.window_size,fill=0.0)
        while frame < analysis_params.start_frame + analysis_params.num_frames:
            for i in range(analysis_params.window_size):
                if frame + i < analysis_params.buf.num_frames:
                    window[i] = analysis_params.buf.data[analysis_params.chan][frame + i]
                else:
                    window[i] = 0.0
            analyzer.next_window(window)
            result.append(analyzer.get_features())
            frame += analysis_params.hop_size
        return result^

    @staticmethod
    fn fft_process[T: GetFeaturable & FFTProcessable,//,input_win: Int = WindowType.hann](mut analyzer: T, analysis_params: AnalysisParams) raises -> List[List[Float64]]:
        result = List[List[Float64]]()
        frame: Int64 = analysis_params.start_frame
        window_samps = List[Float64](length=analysis_params.window_size,fill=0.0)
        fft = RealFFT(analysis_params.window_size)
        window_func = Windows.make_window[input_win](analysis_params.window_size)
        while frame < analysis_params.start_frame + analysis_params.num_frames:
            for i in range(analysis_params.window_size):
                if frame + i < analysis_params.buf.num_frames:
                    window_samps[i] = analysis_params.buf.data[analysis_params.chan][frame + i] * window_func[i]
                else:
                    window_samps[i] = 0.0
            # apply window function
            fft.fft(window_samps)
            analyzer.next_frame(fft.mags,fft.phases)
            result.append(analyzer.get_features())
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

    # @staticmethod
    # fn custom(py_path: PythonObject) raises -> PythonObject:
    #     path = String(py=py_path)
    #     print("custom analysis called, not yet implemented", path)
    #     return 42