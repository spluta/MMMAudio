var dir = thisProcess.nowExecutingPath.dirname;
s.waitForBoot{

	var windowsize = 1024;
	var hopsize = 512;

	"windowsize: %".format(windowsize).postln;
	"hopsize: %".format(hopsize).postln;

	b = Buffer.readChannel(s,dir+/+"../../resources/Shiverer.wav",channels:[0]);
	f = Buffer(s);
	s.sync;
	FluidBufMelBands.processBlocking(
		server: s,
		source: b,
		features:f,
		numBands: 10,
		windowSize:windowsize,
		hopSize:hopsize,
		padding:0
	);
	s.sync;
	f.loadToFloatArray(action:{
		arg fa;
		var file = File.open(dir+/+"flucoma_sc_results/mel_bands_flucoma.csv","w");
		fa = fa.clump(f.numChannels);
		fa.do{
			arg row, i;
			if(i > 0){ file.write("\n") };
			row.do{
				arg val, j;
				if(j > 0){ file.write(",") };
				file.write(val.asString);
			}
		};
		file.close;
	});

	s.quit;

	0.exit;
};