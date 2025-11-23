var dir = thisProcess.nowExecutingPath.dirname;
s.waitForBoot{

	var settings = CSVFileReader.read(dir+/+"outputs/spectral_centroid_mojo_results.csv");
	var windowsize = settings[0][1].asInteger;
	var hopsize = settings[1][1].asInteger;

	"windowsize: %".format(windowsize).postln;
	"hopsize: %".format(hopsize).postln;

	b = Buffer.readChannel(s,dir+/+"../resources/Shiverer.wav",channels:[0]);
	f = Buffer(s);
    s.sync;
	FluidBufSpectralShape.processBlocking(
		server: s,
		source: b,
		features:f,
		select:[\centroid],
		windowSize:windowsize,
		hopSize:hopsize,
		padding:1
	);
	s.sync;
	f.loadToFloatArray(action:{
		arg fa;
		var file = File.open(dir+/+"outputs/spectral_centroid_flucoma_results.csv","w");
		fa.size.do{
			arg i;
			// fa[i].postln;
			if(i > 0){ file.write("\n") };
			file.write(fa[i].asString);
		};
		file.close;
	});

	s.quit;

	0.exit;
};