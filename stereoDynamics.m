function output = stereoDynamics(signal, comp_threshold, comp_slope, ...
        exp_threshold, exp_slope, varargin)

    %% parsing inputs
    p = inputParser;
    addRequired(p, 'signal', @validSignal);
    addRequired(p, 'comp_threshold', @(x) (x < 0));
    addRequired(p, 'comp_slope', @(x) (x > 0));
    addRequired(p, 'exp_threshold', @(x) (x < 0));
    addRequired(p, 'exp_slope', @(x) (isnumeric(x)));
    addParameter(p, 'rms_width', 0.1, @(x) (x >= 0) && (x <= 1));
    addParameter(p, 'attack', 0.05, @(x) (x > 0) && (x <= 1));
    addParameter(p, 'release', 0.005, @(x) (x > 0) && (x <= 1))
    parse(p, signal, comp_threshold, comp_slope, ...
        exp_threshold, exp_slope, varargin{:});
    q = p.Results;

    %% setting initial values
    rms_amplitude = 0;
    gain = 1;

    [samples, channels] = size(q.signal);
    output = zeros(samples, channels);

    %% iteratively apply dynamic gain modification
    for channel = 1:channels % treat each channel separately

        for sample = 1:samples % iterate over each sample
            current_sample = q.signal(sample, channel);

            rms_amplitude = (1 - q.rms_width) * rms_amplitude ...
                + q.rms_width * current_sample^2;

            % converting to dB conveniently makes the signal logarithmic
            rms_dB = 10 * log10(rms_amplitude);

            % positive comp. slope = scale is negative for val > threshold
            comp_scale = q.comp_slope * (q.comp_threshold - rms_dB);

            % negative exp. slope = scale is negative for val < threshold
            exp_scale = q.exp_slope * (q.exp_threshold - rms_dB);

            scaling_factor = 10^(min([0, comp_scale, exp_scale]) / 20);

            if scaling_factor < gain
                gain = (1 - q.attack) * gain + q.attack * scaling_factor;
            else
                gain = (1 - q.release) * gain + q.release * scaling_factor;
            end

            % ok now scale this data point, then we're on to the next one
            output(sample, channel) = gain * current_sample;
        end

    end

end
