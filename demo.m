%% read in sample.wav file
fprintf('--------------Reading sample--------------');
fprintf('\nReading file ''sample-2.wav''...\n');

[test, sampling_freq] = audioread('sample-2.wav');
disp('File read.');

%% apply a series of effects
fprintf('\n----------Applying audio effects----------\n');

% stereo dynamics (a.k.a. audio compression)
tic;
disp('Applying stereoDynamics...');
comp = stereoDynamics(test, -38, 0.3, -40, - .009);
fprintf('\tStereodynamics applied.\n\tTime: %.4f sec.\n', toc);

% tape saturation
tic;
disp('Applying tapeSaturate...');
sat = tapeSaturate(comp, 10);
fprintf('\ttapeSaturate applied.\n\tTime: %.4f sec.\n', toc);

% FIR lowpass filter via 'coefficients' function
tic;
disp('Applying filterHelper.coefficients...');
coef = filterHelper.coefficients(ones(1, 30), 1, comp);
fprintf('\tfilterHelper.coefficients applied.\n\tTime: %.4f sec.\n', toc);

% first-order lowpass filter
tic;
disp('Applying filterHelper.lowpass1...');
lp1 = filterHelper.lowpass1(1000, sampling_freq, comp);
fprintf('\tfilterHelper.lowpass1 applied.\n\tTime: %.4f sec.\n', toc);

% reverb, 50/50 wet/dry
tic;
disp('Applying reverb...');
rvb = reverb(test, sampling_freq, 0.5);
fprintf('\treverb applied.\n\tTime: %.4f sec.\n', toc);

%% play the effects
fprintf('\n-----------Playing the effects------------\nNow playing:\n');
fprintf('\t\t\tdry signal.\n');
sound(linearNormalize(test), sampling_freq, 24);
pause(4);
fprintf('\t\t\tcompressed signal.\n');
sound(linearNormalize(comp), sampling_freq, 24);
pause(4);
fprintf('\t\t\ttape saturated signal.\n');
sound(linearNormalize(sat, .15), sampling_freq, 24);
pause(4);
fprintf('\t\t\tFIR lowpassed signal.\n');
sound(linearNormalize(coef), sampling_freq, 24);
pause(4);
fprintf('\t\t\tfirst-order lowpassed signal.\n');
sound(linearNormalize(lp1), sampling_freq, 24);
pause(4);
fprintf('\t\t\treverberated signal.\n');
sound(linearNormalize(rvb), sampling_freq, 24);
pause(4);
