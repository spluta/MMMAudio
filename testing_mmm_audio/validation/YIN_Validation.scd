var dir = thisProcess.nowExecutingPath.dirname;
s.waitForBoot{

	var settings = CSVFileReader.read(dir+/+"flucoma_sc_results/yin_mojo_results.csv");
	var windowsize = settings[0][1].asInteger;
	var hopsize = settings[1][1].asInteger;
	var minfreq = settings[2][1].asFloat;
	var maxfreq = settings[3][1].asFloat;

	"windowsize: %".format(windowsize).postln;
	"hopsize:    %".format(hopsize).postln;
	"minfreq:    %".format(minfreq).postln;
	"maxfreq:    %".format(maxfreq).postln;

	b = Buffer.readChannel(s,dir+/+"../../resources/Shiverer.wav",channels:[0]);
	f = Buffer(s);
	s.sync;
	FluidBufPitch.processBlocking(
		server: s,
		source: b,
		features:f,
		algorithm:2,
		minFreq:minfreq,
		maxFreq:maxfreq,
		windowSize:windowsize,
		hopSize:hopsize,
		padding:1
	);
	s.sync;
	f.loadToFloatArray(action:{
		arg fa;
		var file = File.open(dir+/+"flucoma_sc_results/yin_flucoma_results.csv","w");
		fa = fa.clump(2);
		fa.size.do{
			arg i;
			// fa[i].postln;
			if(i > 0){ file.write("\n") };
			file.write(fa[i][0].asString ++ "," ++ fa[i][1].asString);
		};
		file.close;
	});

	s.quit;

	0.exit;
};