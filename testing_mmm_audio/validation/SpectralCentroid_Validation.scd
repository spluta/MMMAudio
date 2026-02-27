var dir = thisProcess.nowExecutingPath.dirname;
s.options.numWireBufs = 1024;
s.waitForBoot{

	var windowsize = 1024;
	var hopsize = 512;

	"windowsize: %".format(windowsize).postln;
	"hopsize: %".format(hopsize).postln;

	b = Buffer.readChannel(s,dir+/+"../../resources/Shiverer.wav",channels:[0]);
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
		var file = File.open(dir+/+"flucoma_sc_results/spectral_centroid_flucoma_results.csv","w");
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