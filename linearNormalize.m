function output = linearNormalize(signal, varargin)
    
    %% parsing inputs
    p = inputParser;
    addRequired(p, 'signal', @validSignal);
    addOptional(p, 'level', 1, @(x) (x > 0));
    parse(p, signal, varargin{:});
    q = p.Results;

    %% set up variables
    max_amplitude = max(abs(q.signal(:))); % max across all channels
    [samples, channels] = size(q.signal);
    output = zeros(samples, channels); % preallocate!

    %% normalize signal
    for sample = 1:samples
        output(sample, :) = ...
            (q.signal(sample, :) ./ max_amplitude) .* q.level;
    end

end
