function output = reverb(signal, sampling_freq, wet_dry, varargin)

    %% default values
    delaylines = [887, 1279, 2089, 3167];

    % out decay -> how much to decay the signal after the delay line
    % in decay -> how much to decay the signal before the delay line
    outDecays = [.8; .8; .8; .8];
    inDecays = [1, 1, 1, 1];

    % time for low/high frequencies to decay by 60 dB, in seconds.
    decay_lo = 1.5;
    decay_hi = 0.7;

    fh = filterHelper;

    %% parsing inputs
    p = inputParser;
    addRequired(p, 'signal', @validSignal);
    addRequired(p, 'sampling_freq', @(x) (x ~= 0));
    addRequired(p, 'wet_dry', @(x) (0 <= x && x <= 1));
    addParameter(p, 'gain', 1, @(x) (x > 0) && (x <= 1));
    addParameter(p, 'delaylines', delaylines, @(x) (length(x) == 4));
    addParameter(p, 'outDecays', outDecays, @(x) (size(x) == [4, 1]));
    addParameter(p, 'inDecays', inDecays, @(x) (size(x) == [1, 4]));
    addParameter(p, 'decay_lo', decay_lo, @(x) (x > 0));
    addParameter(p, 'decay_hi', decay_hi, @(x) (x > 0));
    addParameter(p, 'post_lp_cut', 10000, @(x) (x < 0.5 * sampling_freq));
    addParameter(p, 'pre_lp_cut', 12000, @(x) (x < 0.5 * sampling_freq));
    parse(p, signal, sampling_freq, wet_dry, varargin{:});
    q = p.Results;

    if (q.decay_lo ~= decay_lo) || (q.decay_hi ~= decay_hi)
        warning('Changing the decay time can be glitchy.');
    end

    %% feedback matrix
    matrix = [ ...
        0 1 1 0;
        -1 0 0 -1;
        1 0 0 -1;
        0 1 -1 0 ...
        ];
    matrix = matrix .* (q.gain / sqrt(2));

    %% convert to mono
    mono = (q.signal(:, 1) + q.signal(:, 2)) / 2;

    %% pre lowpass filter
    mono = fh.lowpass1(q.pre_lp_cut, q.sampling_freq, mono);

    %% attenuating high frequencies
    r_lo = 1 - (ones(1, 4) * (6.91 / (q.sampling_freq * q.decay_lo))) .* ...
    q.delaylines;
    r_hi = 1 - (ones(1, 4) * (6.91 / (q.sampling_freq * q.decay_hi))) .* ...
        q.delaylines;
    g = (2 * r_lo .* r_hi) ./ (r_lo + r_hi);
    p = (r_lo - r_hi) ./ (r_lo + r_hi);

    %% tonal correction
    tonal_constant = (1 - q.decay_hi / q.decay_lo) / ...
    (1 + q.decay_hi / q.decay_lo);

    %% setting up buffer variables and preallocation
    buffers = zeros(max(q.delaylines), 4);

    filterBuffer = [0, 0, 0, 0];
    tonalBuffer = 0;

    % preallocate
    reverb_signal = zeros(length(mono), 1);

    %% generate reverb iteratively
    for sample_index = 1:length(mono)

        % read the buffers at their respective delay lengths
        readBuffer = [ ...
                buffers(q.delaylines(1), 1), ...
                    buffers(q.delaylines(2), 2), ...
                    buffers(q.delaylines(3), 3), ...
                    buffers(q.delaylines(4), 4) ...
                ];

        samp = (readBuffer * q.outDecays / 4 - tonal_constant * tonalBuffer) ...
            / (1 - tonal_constant);
        reverb_signal(sample_index) = samp;
        tonalBuffer = samp;

        filterBuffer = readBuffer .* g - filterBuffer .* p;

        feedbacks = q.inDecays * mono(sample_index) + filterBuffer * matrix';

        buffers = vertcat(feedbacks, buffers(1:end - 1, :));

    end

    %% add reverb to original signal
    reverb_signal = fh.lowpass1(q.post_lp_cut, ...
    q.sampling_freq, reverb_signal);

    output = (q.wet_dry * horzcat(reverb_signal, reverb_signal) + ...
        (1 - q.wet_dry) * q.signal) / 2;

end
