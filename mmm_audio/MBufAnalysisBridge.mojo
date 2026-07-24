from std.python import PythonObject
from std.python import Python
from std.python import ConvertibleFromPython
from std.python.bindings import PythonModuleBuilder
from std.os import abort
from mmm_audio import *

@export
def PyInit_MBufAnalysisBridge() abi("C") -> PythonObject:
    try:
        var m = PythonModuleBuilder("MBufAnalysisBridge")
        m.def_function[MBufAnalysisBridge.rms]("rms")
        m.def_function[MBufAnalysisBridge.yin]("yin")
        m.def_function[MBufAnalysisBridge.mfcc]("mfcc")
        m.def_function[MBufAnalysisBridge.mel_bands]("mel_bands")
        m.def_function[MBufAnalysisBridge.onset_detection]("onset_detection")
        m.def_function[MBufAnalysisBridge.onset_detection_feature]("onset_detection_feature")
        m.def_function[MBufAnalysisBridge.spectral_centroid]("spectral_centroid")
        m.def_function[MBufAnalysisBridge.top_n_freqs]("top_n_freqs")
        return m.finalize()
    except e:
        abort(String("error creating Python Mojo module:", e))

def get_at_key[T: ConvertibleFromPython & ImplicitlyCopyable & Writable](analysis: String, py_dict: PythonObject, key: String, default: Optional[T] = None) raises -> T:
    if key in py_dict:
        return T(py=py_dict[key])
    else:
        if default is None:
            abort(String("MBufAnalysis", analysis, "requires a '", key, "' key in the input dictionary"))
        else:
            print("MBufAnalysis", analysis, ": No '", key, "' key in input dictionary, defaulting to ", default)
            return default.value()

# the above get_at_key doesn't work with Float64 🤷🏼
# it can stay as a separate function until Modular
# fixes what looks like a bug
def getFloat64(analysis: String, py_dict: PythonObject, key: String, default: Optional[Float64] = None) raises -> Float64:
    if key in py_dict:
        return Float64(py=py_dict[key])
    else:
        if default is None:
            abort(String("MBufAnalysis", analysis, "requires a '", key, "' key in the input dictionary"))
        else:
            print("MBufAnalysis", analysis, ": No '", key, "' key in input dictionary, defaulting to ", default)
            return default.value()

struct AnalysisParams:
    var buf: Buffer
    var chan: Int
    var start_frame: Int
    var num_frames: Int
    # [TODO]: padding

    def __init__(out self, py_dict: PythonObject) raises:

        self.buf = Buffer.load(get_at_key[String]("AnalysisParams", py_dict, "path"))
        self.chan = get_at_key[Int]("AnalysisParams", py_dict, "chan", 0)
        self.start_frame = get_at_key[Int]("AnalysisParams", py_dict, "start_frame", 0)
        self.num_frames = get_at_key[Int]("AnalysisParams", py_dict, "num_frames", Int(self.buf.num_frames - self.start_frame))

struct MBufAnalysisBridge:

    @staticmethod
    def mel_bands(py_dict: PythonObject) raises -> PythonObject:

        ap = AnalysisParams(py_dict)
        window_size = get_at_key[Int]("mel_bands", py_dict, "window_size", 1024)
        hop_size = get_at_key[Int]("mel_bands", py_dict, "hop_size", window_size // 2)
        num_bands = get_at_key[Int]("mel_bands", py_dict, "num_bands", 40)
        min_freq: Float64 = getFloat64("mel_bands", py_dict, "min_freq", 20.0)
        max_freq: Float64 = getFloat64("mel_bands", py_dict, "max_freq", 20000.0)

        mel_bands = MelBands(ap.buf.sample_rate, num_bands, min_freq, max_freq, window_size)
        result = MBufAnalysis.fft_process[WindowType.hann](mel_bands, ap.buf, ap.chan, ap.start_frame, ap.num_frames, window_size=window_size, hop_size=hop_size)

        return MBufAnalysisBridge.matrix_to_numpy(result)

    @staticmethod
    def mfcc(py_dict: PythonObject) raises -> PythonObject:
        # make the analysis params instance
        ap = AnalysisParams(py_dict)
        num_bands = get_at_key[Int]("mfcc", py_dict, "num_bands", 40)
        num_coeffs = get_at_key[Int]("mfcc", py_dict, "num_coeffs", 13)
        min_freq = getFloat64("mfcc", py_dict, "min_freq", 20.0)
        max_freq = getFloat64("mfcc", py_dict, "max_freq", 20000.0)

        # # run the analysis
        mfcc = MFCC(ap.buf.sample_rate, num_coeffs, num_bands, min_freq, max_freq)
        window_size = get_at_key[Int]("mfcc", py_dict, "window_size", 1024)
        hop_size = get_at_key[Int]("mfcc", py_dict, "hop_size", window_size // 2)
        result = MBufAnalysis.fft_process[WindowType.hann](mfcc, ap.buf, ap.chan, ap.start_frame, ap.num_frames, window_size=window_size, hop_size=hop_size)
        
        # return it as a numpy array
        return MBufAnalysisBridge.matrix_to_numpy(result)

    @staticmethod
    def top_n_freqs(py_dict: PythonObject) raises -> PythonObject:
        # make the analysis params instance
        ap = AnalysisParams(py_dict)
        num_peaks = get_at_key[Int]("top_n_freqs",py_dict, "num_peaks", 5)
        thresh = getFloat64("top_n_freqs",py_dict, "thresh", -30.0)
        sort_by_freq = get_at_key[Bool]("top_n_freqs",py_dict, "sort_by_freq", False)

        window_size = get_at_key[Int]("top_n_freqs",py_dict, "window_size", 1024)
        hop_size = get_at_key[Int]("top_n_freqs",py_dict, "hop_size", window_size // 2)

        # # run the analysis
        top_n_freqs = TopNFreqs(ap.buf.sample_rate, window_size, num_peaks, sort_by_freq, thresh)
        result = MBufAnalysis.fft_process[WindowType.hann](top_n_freqs, ap.buf, ap.chan, ap.start_frame, ap.num_frames, window_size=window_size, hop_size=hop_size)
        
        # return it as a numpy array
        return MBufAnalysisBridge.matrix_to_numpy(result)

    @staticmethod
    def rms(py_dict: PythonObject) raises -> PythonObject:

        # make the analysis params instance
        ap = AnalysisParams(py_dict)

        # # run the analysis
        rms = RMS()
        window_size = get_at_key[Int]("rms",py_dict, "window_size", 1024)
        hop_size = get_at_key[Int]("rms",py_dict, "hop_size", window_size // 2)
        result = MBufAnalysis.buffered_process(rms, ap.buf, ap.chan, ap.start_frame, ap.num_frames, window_size=window_size, hop_size=hop_size)
        
        # return it as a numpy array
        return MBufAnalysisBridge.matrix_to_numpy(result)

    @staticmethod
    def yin(py_dict: PythonObject) raises -> PythonObject:
        
        # make the analysis params instance
        ap = AnalysisParams(py_dict)

        # params specific to this analysis
        min_freq = getFloat64("yin",py_dict, "min_freq", 20.0)
        max_freq = getFloat64("yin",py_dict, "max_freq", 20000.0)

        # define the window function that will be called for each window of audio. 
        # It has to be a function that takes a List[Float64] and returns a List[Float64] 
        # (even if it's just one value) so that it's consistent with other analyses we 
        # might want to add later
        window_size = get_at_key[Int]("yin",py_dict, "window_size", 1024)
        hop_size = get_at_key[Int]("yin",py_dict, "hop_size", window_size // 2)
        yin = YIN(ap.buf.sample_rate, window_size, min_freq=min_freq, max_freq=max_freq)

        # run the analysis
        result = MBufAnalysis.buffered_process(yin,ap.buf, ap.chan, ap.start_frame, ap.num_frames, window_size=window_size, hop_size=hop_size)
        
        # return it as a numpy array
        return MBufAnalysisBridge.matrix_to_numpy(result)

    @staticmethod
    def spectral_centroid(py_dict: PythonObject) raises -> PythonObject:
        # make the analysis params instance
        ap = AnalysisParams(py_dict)
        min_freq = getFloat64("spectral_centroid",py_dict, "min_freq", 20.0)
        max_freq = getFloat64("spectral_centroid",py_dict, "max_freq", 20000.0)
        power_mag = get_at_key[Bool]("spectral_centroid",py_dict, "power_mag", False)
        window_size = get_at_key[Int]("spectral_centroid",py_dict, "window_size", 1024)
        hop_size = get_at_key[Int]("spectral_centroid",py_dict, "hop_size", window_size // 2)

        # # run the analysis
        sc = SpectralCentroid(ap.buf.sample_rate, min_freq=min_freq, max_freq=max_freq, power_mag=power_mag)
        result = MBufAnalysis.fft_process[WindowType.hann](sc, ap.buf, ap.chan, ap.start_frame, ap.num_frames, window_size=window_size, hop_size=hop_size)
        
        # return it as a numpy array
        return MBufAnalysisBridge.matrix_to_numpy(result)

    @staticmethod
    def onset_detection_feature(py_dict: PythonObject) raises -> PythonObject:
        """Onset feature analysis of a buffer.

        Uses the OnsetDetectionFeature class to analyze a buffer for onset detection function values. 
        The output is a List of Lists, where each inner List contains one Float64 value (the onset 
        detection function value) for each analysis hop.

        Args:
            py_dict: Input options dictionary. Required and optional keys include:
                path (String): Path to the source audio file.
                chan (Int, optional): Channel index to analyze. Defaults to 0.
                start_frame (Int, optional): First frame to analyze. Defaults to 0.
                num_frames (Int, optional): Number of frames to analyze. Defaults to the remaining buffer.
                metric (String, optional): Onset metric name. Defaults to "complex_domain".
                window_size (Int, optional): FFT window size in samples. Defaults to 1024.
                hop_size (Int, optional): Hop size in samples. Defaults to window_size // 2.
                filter_size (Int, optional): Median-filter size. Defaults to 5.
                frame_delta (Int, optional): Frame offset for metrics that use delayed comparison. Defaults to 0.

        Returns:
            A NumPy float64 matrix where each row contains one onset detection-function value
            for an analysis hop.

        Raises:
            Error: If input parsing, buffer loading, metric conversion, analysis, or NumPy conversion fails.
        """
        ap = AnalysisParams(py_dict)
        metric_string = get_at_key[String]("onset_detection_feature", py_dict, "metric", "complex_domain")
        window_size = get_at_key[Int]("onset_detection_feature", py_dict, "window_size", 1024)
        hop_size = get_at_key[Int]("onset_detection_feature", py_dict, "hop_size", window_size // 2)
        filter_size = get_at_key[Int]("onset_detection_feature", py_dict, "filter_size", 5)
        frame_delta = get_at_key[Int]("onset_detection_feature", py_dict, "frame_delta", 0)

        result = OnsetDetectionFeature.buf_analysis(
            ap.buf,
            ap.chan,
            ap.start_frame,
            ap.num_frames,
            OnsetMetric.from_string(metric_string),
            window_size,
            hop_size,
            filter_size,
            frame_delta,
        )
        return MBufAnalysisBridge.matrix_to_numpy(result)

    @staticmethod
    def onset_detection(py_dict: PythonObject) raises -> PythonObject:
        """Onset Detection on a buffer.

        Uses `OnsetDetection` to analyze a buffer for onsets and return the sample indices of detected onsets.

        Args:
            py_dict: Input options dictionary. Required and optional keys include:
                path (String): Path to the source audio file.
                chan (Int, optional): Channel index to analyze. Defaults to 0.
                start_frame (Int, optional): First frame to analyze. Defaults to 0.
                num_frames (Int, optional): Number of frames to analyze. Defaults to the remaining buffer.
                metric (String, optional): Onset metric name. Defaults to "complex_domain".
                threshold (Float64, optional): Descriptor threshold for trigger detection. Defaults to 0.5.
                debounce (Float64, optional): Minimum seconds between triggers. Defaults to 0.1.
                window_size (Int, optional): FFT window size in samples. Defaults to 1024.
                hop_size (Int, optional): Hop size in samples. Defaults to window_size // 2.
                filter_size (Int, optional): Median-filter size. Defaults to 5.
                frame_delta (Int, optional): Frame offset for metrics that use delayed comparison. Defaults to 0.

        Returns:
            A NumPy int64 vector of onset sample indices.

        Raises:
            Error: If input parsing, world setup, metric conversion, analysis, or NumPy conversion fails.
        """
        ap = AnalysisParams(py_dict)
        metric_string = get_at_key[String]("onset_detection", py_dict, "metric", "complex_domain")
        threshold = getFloat64("onset_detection", py_dict, "threshold", 0.5)
        debounce = getFloat64("onset_detection", py_dict, "debounce", 0.1)
        window_size = get_at_key[Int]("onset_detection", py_dict, "window_size", 1024)
        hop_size = get_at_key[Int]("onset_detection", py_dict, "hop_size", window_size // 2)
        filter_size = get_at_key[Int]("onset_detection", py_dict, "filter_size", 5)
        frame_delta = get_at_key[Int]("onset_detection", py_dict, "frame_delta", 0)

        w = alloc[MMMWorld](1)
        environment = alloc[Environment](1)
        environment.init_pointee_move(Environment(64, 2, 2))
        w.init_pointee_move(MMMWorld(ap.buf.sample_rate, environment))

        result = OnsetDetection.buf_analysis(
            w,
            ap.buf,
            ap.chan,
            ap.start_frame,
            ap.num_frames,
            OnsetMetric.from_string(metric_string),
            threshold,
            debounce,
            window_size,
            hop_size,
            filter_size,
            frame_delta,
        )
        return MBufAnalysisBridge.list_to_numpy(result)
    
    @staticmethod
    def list_to_numpy(list: List[Int]) raises -> PythonObject:
        np = Python.import_module("numpy")
        shape = Python.tuple(Int(len(list)))
        nparray = np.zeros(shape=shape,dtype=np.int64)
        for i in range(len(list)):
            nparray[i] = list[i]
        return nparray

    @staticmethod
    def matrix_to_numpy(list: List[List[Float64]]) raises -> PythonObject:
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
    def buffered_process[T: GetFloat64Featurable & BufferedProcessable](mut analyzer: T,buf: Buffer, chan: Int, start_frame: Int, var num_frames: Int, window_size: Int, hop_size: Int) raises -> List[List[Float64]]:
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
    def fft_process[T: GetFloat64Featurable & FFTProcessable,//,input_win: WindowType = WindowType.hann](mut analyzer: T, buf: Buffer, chan: Int, start_frame: Int, var num_frames: Int, window_size: Int, hop_size: Int) raises -> List[List[Float64]]:
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
            fft.fft(window_samps)
            analyzer.next_frame(fft.mags,fft.phases)
            result.append(analyzer.get_features())
            frame += hop_size
        return result^

    # @staticmethod
    # def custom(py_path: PythonObject) raises -> PythonObject:
    #     path = String(py=py_path)
    #     print("custom analysis called, not yet implemented", path)
    #     return 42