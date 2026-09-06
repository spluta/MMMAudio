var dir = thisProcess.nowExecutingPath.dirname;
s.waitForBoot{
	~time_series = Array.newClear(10);

	b = Buffer.read(s,FluidFilesPath("Nicol-LoopE-M.wav"));
	f = Buffer(s);

	10.do{
		arg metric;
		FluidBufOnsetFeature.processBlocking(
			server: s,
			source: b,
			features: f,
			metric: metric,
			windowSize:1024,
			hopSize:512,
			padding:1
		);

		s.sync;

		f.loadToFloatArray(action:{
			arg fa;
			~time_series[metric] = fa;
		});

		s.sync;
	};

	~time_series_file = File.open(dir+/+"flucoma_sc_results/onset_detection_features_flucoma.csv","w");
	~time_series.do{
		arg line, i;
		if(i != 0){ ~time_series_file.write("\n") };
		line.do{
			arg val, j;
			if( j != 0 ){ ~time_series_file.write(",") };
			~time_series_file.write(val.asCompileString)
		};
	};
	~time_series_file.close;

	s.quit;

	0.exit
};