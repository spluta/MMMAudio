var dir = thisProcess.nowExecutingPath.dirname;
s.options.sampleRate = 44100;
s.waitForBoot{

	var windowsize = 1024;
	var hopsize = 512;
	var numCoeffs = 13;
	var numBands = 40;
	var minFreq = 20.0;
	var maxFreq = 20000.0;

	"windowsize: %".format(windowsize).postln;
	"hopsize: %".format(hopsize).postln;
	"numCoeffs: %".format(numCoeffs).postln;
	"numBands: %".format(numBands).postln;

	b = Buffer.readChannel(s,dir+/+"../resources/Shiverer.wav",channels:[0]);
	f = Buffer(s);
	s.sync;
	FluidBufMFCC.processBlocking(
		server: s,
		source: b,
		features: f,
		numCoeffs: numCoeffs,
		numBands: numBands,
		minFreq: minFreq,
		maxFreq: maxFreq,
		windowSize: windowsize,
		hopSize: hopsize,
		padding: 0
	);
	s.sync;
	f.loadToFloatArray(action:{
		arg fa;
		var file = File.open(dir+/+"flucoma_sc_results/mfcc_flucoma_results.csv","w");
		fa = fa.clump(numCoeffs);
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
