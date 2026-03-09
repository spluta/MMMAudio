var dir = thisProcess.nowExecutingPath.dirname;
s.waitForBoot{

	var settings = CSVFileReader.read(dir+/+"flucoma_sc_results/rms_mojo_results.csv");
	var windowsize = settings[0][1].asInteger;
	var hopsize = settings[1][1].asInteger;

	"windowsize: %".format(windowsize).postln;
	"hopsize: %".format(hopsize).postln;

	b = Buffer.readChannel(s,dir+/+"../resources/Shiverer.wav",channels:[0]);
	f = Buffer(s);
    s.sync;
	FluidBufLoudness.processBlocking(
		server: s,
		source: b,
		features:f,
		select:[\loudness],
		windowSize:windowsize,
		hopSize:hopsize,
		padding:1
	);
	s.sync;
	f.loadToFloatArray(action:{
		arg fa;
		var file = File.open(dir+/+"flucoma_sc_results/rms_flucoma_results.csv","w");
		fa.size.do{
			arg i;
			// fa[i].postln;
			if(i > 0){ file.write("\n") };
			file.write(fa[i].dbamp.asString);
		};
		file.close;
	});

	s.quit;

	0.exit;
};