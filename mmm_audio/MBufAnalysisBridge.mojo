from python import PythonObject
from python import Python
from python import ConvertibleFromPython
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
        m.def_function[MBufAnalysisBridge.spectral_flux_onsets]("spectral_flux_onsets")
        m.def_function[MBufAnalysisBridge.spectral_centroid]("spectral_centroid")
        # m.def_function[MBufAnalysisBridge.custom]("custom")
        return m.finalize()
    except e:
        abort(String("error creating Python Mojo module:", e))

# [TODO]: also pass in a string that let's us know what *analysis* it comes from
fn getInt(py_dict: PythonObject, key: String, default: Optional[Int] = None) raises -> Int:
    if key in py_dict:
        return Int(py=py_dict[key])
    else:
        if default is None:
            abort(String("MBufAnalysis requires a '", key, "' key in the input dictionary"))
        else:
            print("No '", key, "' key in input dictionary, defaulting to ", default)
            return default.value()

fn getFloat64(py_dict: PythonObject, key: String, default: Optional[Float64] = None) raises -> Float64:
    if key in py_dict:
        return py_to_float64(py_dict[key])
    else:
        if default is None:
            abort(String("MBufAnalysis requires a '", key, "' key in the input dictionary"))
        else:
            print("No '", key, "' key in input dictionary, defaulting to ", default)
            return default.value()

fn getBool(py_dict: PythonObject, key: String, default: Optional[Bool] = None) raises -> Bool:
    if key in py_dict:
        return Bool(py=py_dict[key])
    else:
        if default is None:
            abort(String("MBufAnalysis requires a '", key, "' key in the input dictionary"))
        else:
            print("No '", key, "' key in input dictionary, defaulting to ", default)
            return default.value()

fn getString(py_dict: PythonObject, key: String, default: Optional[String] = None) raises -> String:
    if key in py_dict:
        return String(py=py_dict[key])
    else:
        if default is None:
            abort(String("MBufAnalysis requires a '", key, "' key in the input dictionary"))
        else:
            print("No '", key, "' key in input dictionary, defaulting to ", default)
            return default.value()

struct AnalysisParams:
    var buf: Buffer
    var chan: Int
    var start_frame: Int
    var num_frames: Int
    # [TODO]: padding

    fn __init__(out self, py_dict: PythonObject) raises:

        self.buf = Buffer.load(getString(py_dict, "path"))
        self.chan = getInt(py_dict, "chan", 0)
        self.start_frame = getInt(py_dict, "start_frame", 0)
        self.num_frames = getInt(py_dict, "num_frames", Int(self.buf.num_frames - self.start_frame))

struct MBufAnalysisBridge:

    @staticmethod
    fn mel_bands(py_dict: PythonObject) raises -> PythonObject:

        ap = AnalysisParams(py_dict)
        window_size = getInt(py_dict, "window_size", 1024)
        hop_size = getInt(py_dict, "hop_size", window_size // 2)
        num_bands = getInt(py_dict, "num_bands", 40)
        min_freq = getFloat64(py_dict, "min_freq", 20.0)
        max_freq = getFloat64(py_dict, "max_freq", 20000.0)
        
        mel_bands = MelBands(ap.buf.sample_rate, num_bands, min_freq, max_freq, window_size)
        result = MBufAnalysis.fft_process[WindowType.hann](mel_bands, ap.buf, ap.chan, ap.start_frame, ap.num_frames, window_size=window_size, hop_size=hop_size)

        return MBufAnalysisBridge.matrix_to_numpy(result)

    @staticmethod
    fn mfcc(py_dict: PythonObject) raises -> PythonObject:
        # make the analysis params instance
        ap = AnalysisParams(py_dict)
        num_bands = getInt(py_dict, "num_bands", 40)
        num_coeffs = getInt(py_dict, "num_coeffs", 13)
        min_freq = getFloat64(py_dict, "min_freq", 20.0)
        max_freq = getFloat64(py_dict, "max_freq", 20000.0)

        # # run the analysis
        mfcc = MFCC(ap.buf.sample_rate, num_coeffs, num_bands, min_freq, max_freq)
        window_size = getInt(py_dict, "window_size", 1024)
        hop_size = getInt(py_dict, "hop_size", window_size // 2)
        result = MBufAnalysis.fft_process[WindowType.hann](mfcc, ap.buf, ap.chan, ap.start_frame, ap.num_frames, window_size=window_size, hop_size=hop_size)
        
        # return it as a numpy array
        return MBufAnalysisBridge.matrix_to_numpy(result)

    @staticmethod
    fn rms(py_dict: PythonObject) raises -> PythonObject:

        # make the analysis params instance
        ap = AnalysisParams(py_dict)

        # # run the analysis
        rms = RMS()
        window_size = getInt(py_dict, "window_size", 1024)
        hop_size = getInt(py_dict, "hop_size", window_size // 2)
        result = MBufAnalysis.buffered_process(rms, ap.buf, ap.chan, ap.start_frame, ap.num_frames, window_size=window_size, hop_size=hop_size)
        
        # return it as a numpy array
        return MBufAnalysisBridge.matrix_to_numpy(result)

    @staticmethod
    fn yin(py_dict: PythonObject) raises -> PythonObject:
        
        # make the analysis params instance
        ap = AnalysisParams(py_dict)

        # params specific to this analysis
        min_freq = getFloat64(py_dict, "min_freq", 20.0)
        max_freq = getFloat64(py_dict, "max_freq", 20000.0)

        # define the window function that will be called for each window of audio. 
        # It has to be a function that takes a List[Float64] and returns a List[Float64] 
        # (even if it's just one value) so that it's consistent with other analyses we 
        # might want to add later
        window_size = getInt(py_dict, "window_size", 1024)
        hop_size = getInt(py_dict, "hop_size", window_size // 2)
        yin = YIN(ap.buf.sample_rate, window_size, min_freq=min_freq, max_freq=max_freq)

        # run the analysis
        result = MBufAnalysis.buffered_process(yin,ap.buf, ap.chan, ap.start_frame, ap.num_frames, window_size=window_size, hop_size=hop_size)
        
        # return it as a numpy array
        return MBufAnalysisBridge.matrix_to_numpy(result)

    @staticmethod
    fn spectral_centroid(py_dict: PythonObject) raises -> PythonObject:
        # make the analysis params instance
        ap = AnalysisParams(py_dict)
        min_freq = getFloat64(py_dict, "min_freq", 20.0)
        max_freq = getFloat64(py_dict, "max_freq", 20000.0)
        power_mag = getBool(py_dict, "power_mag", False)
        window_size = getInt(py_dict, "window_size", 1024)
        hop_size = getInt(py_dict, "hop_size", window_size // 2)

        # # run the analysis
        sc = SpectralCentroid(ap.buf.sample_rate, min_freq=min_freq, max_freq=max_freq, power_mag=power_mag)
        result = MBufAnalysis.fft_process[WindowType.hann](sc, ap.buf, ap.chan, ap.start_frame, ap.num_frames, window_size=window_size, hop_size=hop_size)
        
        # return it as a numpy array
        return MBufAnalysisBridge.matrix_to_numpy(result)

    @staticmethod
    fn spectral_flux_onsets(py_dict: PythonObject) raises -> PythonObject:
        # make the analysis params instance
        analysis_params = AnalysisParams(py_dict)
        thresh = getFloat64(py_dict, "thresh", 0.01)
        window_size = getInt(py_dict, "window_size", 1024)
        hop_size = getInt(py_dict, "hop_size", window_size // 2)
        filter_size = getInt(py_dict, "filter_size", 5)
        min_slice_len = getFloat64(py_dict, "min_slice_len", 0.1)
        
        w = alloc[MMMWorld](1) 
        w.init_pointee_move(MMMWorld(analysis_params.buf.sample_rate))

        # run the analysis
        sf_onsets = SpectralFluxOnsets(w,window_size,hop_size,filter_size)
        sf_onsets.thresh = thresh
        sf_onsets.min_slice_len = min_slice_len

        onsets = List[Int]()

        for i in range(analysis_params.buf.num_frames):
            samp = analysis_params.buf.data[analysis_params.chan][i]
            if sf_onsets.next(samp):
                onsets.append(i)

        # return it as a numpy array
        return MBufAnalysisBridge.list_to_numpy(onsets)
    
    @staticmethod
    fn list_to_numpy(list: List[Int]) raises -> PythonObject:
        np = Python.import_module("numpy")
        shape = Python.tuple(Int(len(list)))
        nparray = np.zeros(shape=shape,dtype=np.int64)
        for i in range(len(list)):
            nparray[i] = list[i]
        return nparray

    @staticmethod
    fn matrix_to_numpy(list: List[List[Float64]]) raises -> PythonObject:
        np = Python.import_module("numpy")
        shape = Python.tuple(Int(len(list)), Int(len(list[0])))
        nparray = np.zeros(shape=shape,dtype=np.float64)
        for i in range(len(list)):
            for j in range(len(list[i])):
                nparray[i][j] = list[i][j]
        return nparray

struct MBufAnalysis:

    # [TODO]: add windowing
    @staticmethod
    fn buffered_process[T: GetFloat64Featurable & BufferedProcessable](mut analyzer: T,buf: Buffer, chan: Int, start_frame: Int, var num_frames: Int, window_size: Int, hop_size: Int) raises -> List[List[Float64]]:
        result = List[List[Float64]]()
        frame: Int = start_frame
        if num_frames < 0:
            num_frames = buf.num_frames - start_frame
        window_samps = List[Float64](length=window_size,fill=0.0)
        while frame < start_frame + num_frames:
            for i in range(window_size):
                if frame + i < buf.num_frames:
                    window_samps[i] = buf.data[chan][frame + i]
                else:
                    window_samps[i] = 0.0
            analyzer.next_window(window_samps)
            result.append(analyzer.get_features())
            frame += hop_size
        return result^
    
    @staticmethod
    fn fft_process[T: GetFloat64Featurable & FFTProcessable,//,input_win: Int = WindowType.hann](mut analyzer: T, buf: Buffer, chan: Int, start_frame: Int, var num_frames: Int, window_size: Int, hop_size: Int) raises -> List[List[Float64]]:
        result = List[List[Float64]]()
        frame: Int = start_frame
        if num_frames < 0:
            num_frames = buf.num_frames - start_frame
        window_samps = List[Float64](length=window_size,fill=0.0)
        fft = RealFFT(window_size)
        window_func = Windows.make_window[input_win](window_size)
        while frame < start_frame + num_frames:
            for i in range(window_size):
                if frame + i < buf.num_frames:
                    window_samps[i] = buf.data[chan][frame + i] * window_func[i]
                else:
                    window_samps[i] = 0.0
            # apply window function
            fft.fft(window_samps)
            analyzer.next_frame(fft.mags,fft.phases)
            result.append(analyzer.get_features())
            frame += hop_size
        return result^

    # @staticmethod
    # fn custom(py_path: PythonObject) raises -> PythonObject:
    #     path = String(py=py_path)
    #     print("custom analysis called, not yet implemented", path)
    #     return 42