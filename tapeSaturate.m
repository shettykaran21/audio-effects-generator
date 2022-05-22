function output = tapeSaturate(signal, knob, varargin)
    
    %% parsing inputs
    p = inputParser;
    addRequired(p, 'signal', @validSignal); %  \_/    |  to 11 so you can  |
    addRequired(p, 'knob', @(x) (x >= 0) && (x <= 10)); % | 'turn it to 11':) |
    addOptional(p, 'gain', 1, @(x) (x >= 0) && (x <= 1)); % |____________________|
    parse(p, signal, knob, varargin{:});
    q = p.Results;

    %% setting up variables
    [samples, channels] = size(q.signal);
    output = zeros(samples, channels);
    lin_knob = 10^((-q.knob) / 7.5); % the knob is actually logarithmic
    normSignal = linearNormalize(q.signal);

    %% apply saturation
    for channel = 1:channels % for each channel separately

        for sample = 1:samples
            current_sample = normSignal(sample, channel);
            output(sample, channel) = q.gain * tanh(current_sample / lin_knob);
        end

    end

end
