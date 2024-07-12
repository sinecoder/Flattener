/*declare name "Flatten";*/
// flatten with a few modifications (Flattener), check the original on: https://git.sr.ht/~kdsch/flatten/tree/master/item/flatten.dsp
declare name "Flattener";
declare version "0.1";
declare author "Karl Schultheisz";
declare license "GPL";
declare copyright "Haxbli";

import ("stdfaust.lib");

flattener = flatten (tau, smoothness, gain) * level
with{	
    tau = 10 ^ (hslider("Distortion", 2.5, 0, 5, 0.01) * -1 : si.smoo);
			
    gain = hslider("Max gain[unit:dB]", 20, 0, 60, 0.1) * -1 : si.smoo : ba.db2linear;
    
    smoothness = hslider("Smoothing", 0, 0, 1, 0.01) ^ 3 * 0.5 : si.smoo;
    
    level = hslider ("brickgain[unit:dB]", -3, -96, 0, 0.1) : si.smoo : ba.db2linear;
};


// flatten reduces the dynamics of the input signal
// by dividing out its envelope with respect to a
// certain metric of its magnitude.
flatten(tau, smoothness, gain, x) = x / an.amp_follower(tau, magnitude_normalized (smoothness, gain, x));


// magnitude_normalized is a scaled version of
// magnitude so as to satisfy the constraints
//
//   magnitude_normalized (s, m, 0) = m
//
//    lim  magnitude_normalized (s, m, x)/x = 1
//   x → ∞
// 
magnitude_normalized(s, m, x) = magnitude (s, m, b * x) / b
with {	
    b = magnitude (s, m, 0) / m;
};

// magnitude implements a smooth version
// of max(m, abs(x)) where s controls smoothness
// and m controls the absolute minimum.
magnitude(s, m, x) = smoothmax(s, m, smoothmax (s, -1 * x, x));

// smoothmax is a smooth maximum function
// with smoothness parameter s, approximating
// max (x, y), minimizing error when s = 0.
smoothmax (s, x, y) = 0.5 * (x + y + sqrt(4*s^2 + (x - y)^2));


stereoproc(l, r) = l, r : flattener, flattener;

bypass = checkbox("[0]bypass");

follower_onoff = checkbox("follower_on_off");
smoothness = hslider("attack",  1, 1, 1000, 1)/10000;
smooth = si.smooth(ba.tau2pole(smoothness));
relf2 = hslider("relfol[style:knob]", 1, 1, 10000, 1)/10000;
follower = hgroup("[1]Follower", (1, gain*(max((an.amp_follower(relf2)), 0)):smooth, smooth) : select2(follower_onoff));
gain = hgroup("[1]Follower", hslider("gainfollower", 1, 0, 10, 0.01));

drywet = hslider("Dry/Wet", 1, 0, 1, 0.001);

flatten_process(l, r) = ((l <: *(min(follower, 1) , flattener)), (r <: *(min(follower, 1) , flattener))); 

process(l, r) = l, r :  ba.bypass2(bypass, ef.dryWetMixer(drywet, flatten_process));
