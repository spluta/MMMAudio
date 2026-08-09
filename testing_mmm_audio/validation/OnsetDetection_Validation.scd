(
var dir = thisProcess.nowExecutingPath.dirname;
~optimize_thresh = {
	arg metric_int, ground_truth, tolerance = 0, low = 0, high = 3200, max_iterations = 100;
	var thresh, continue = true, n_slices, iterations = 0, slice_points;

	while{
		continue && (iterations < max_iterations)
	}{
		thresh = (high + low) / 2;

		FluidBufOnsetSlice.processBlocking(
			server: s,
			source: b,
			indices: f,
			metric: metric_int,
			windowSize:1024,
			hopSize:512,
			threshold: thresh,
		);

		s.sync;

		f.loadToFloatArray(action:{
			arg fa;
			slice_points = fa;
			n_slices = fa.size;
			if( abs(n_slices - ground_truth) <= tolerance ){
				continue = false;
			}{
				if( n_slices > ground_truth ){ low = thresh };
				if( n_slices < ground_truth ){ high = thresh };
			}
		});

		s.sync;

		iterations = iterations + 1;
	};

	[thresh,n_slices,iterations, slice_points];
};

s.waitForBoot{
	~slice_points = Array.newClear(10);
	~thresholds = Array.newClear(10);

	b = Buffer.read(s,FluidFilesPath("Nicol-LoopE-M.wav"));
	f = Buffer(s);

	~thresholds[9] = 0.5;
	FluidBufOnsetSlice.processBlocking(
		server: s,
		source: b,
		indices: f,
		metric: 9,
		windowSize:1024,
		hopSize:512,
		threshold: 0.5,
	);

	f.loadToFloatArray(action:{
		arg fa;
		fa.postln;
		~slice_points[9] = fa;
		~ground_truth = fa.size;
		"metric_int: 9 --- n slices: %".format(~ground_truth).postln;
	});

	9.do{
		arg metric_int;
		var thresh, n_slices, iterations, slice_points;
		# thresh, n_slices, iterations, slice_points = ~optimize_thresh.(metric_int,~ground_truth);
		"metric_int: % --- thresh: % --- n slices: % --- iterations: %".format(metric_int,thresh,n_slices,iterations).postln;
		~thresholds[metric_int] = thresh;
		~slice_points[metric_int] = slice_points
	};

	~thresholds_file = File.open(dir+/+"flucoma_sc_results/onset_detection_flucoma_thresholds.csv","w");
	~thresholds_file.write(~thresholds.asCompileString.replace("[","").replace("]",""));
	~thresholds_file.close;

	~slice_points_file = File.open(dir+/+"flucoma_sc_results/onset_detection_flucoma_slice_points.csv","w");
	~slice_points.do{
		arg line, i;
		if(i != 0){ ~slice_points_file.write("\n") };
		line.do{
			arg val, j;
			if( j != 0 ){ ~slice_points_file.write(",") };
			~slice_points_file.write(val.asCompileString)
		};
	};
	~slice_points_file.close;
};
)