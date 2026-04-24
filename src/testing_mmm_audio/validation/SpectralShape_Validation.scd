var dir = thisProcess.nowExecutingPath.dirname;
s.waitForBoot{

	var settingsPath = dir+/+"outputs/spectral_shape_settings.csv";
	var settings, windowsize, hopsize;

	if(File.exists(settingsPath).not){
		"SpectralShape settings file missing: %".format(settingsPath).postln;
		s.quit;
		0.exit;
	};

	settings = CSVFileReader.read(settingsPath);
	windowsize = settings[0][1].asInteger;
	hopsize = settings[1][1].asInteger;

	"windowsize: %".format(windowsize).postln;
	"hopsize: %".format(hopsize).postln;

	b = Buffer.readChannel(s,dir+/+"../resources/Shiverer.wav",channels:[0]);
	f = Buffer(s);
    s.sync;
	FluidBufSpectralShape.processBlocking(
		server: s,
		source: b,
		features: f,
		select: [\centroid, \spread, \skewness, \kurtosis, \rolloff, \flatness, \crest],
		windowSize: windowsize,
		hopSize: hopsize,
		padding: 1
	);
	s.sync;
	f.loadToFloatArray(action:{
		arg fa;
		var file = File.open(dir+/+"outputs/spectral_shape_flucoma_results.csv","w");
		var numFrames = (fa.size / 7).asInteger;
		numFrames.do{
			arg i;
			var idx = i * 7;
			var line = [
				fa[idx],
				fa[idx + 1],
				fa[idx + 2],
				fa[idx + 3],
				fa[idx + 4],
				fa[idx + 5],
				fa[idx + 6]
			].collect(_.asString).join($,);
			if(i > 0){ file.write("\n") };
			file.write(line);
		};
		file.close;
	});

	s.quit;

	0.exit;
};
