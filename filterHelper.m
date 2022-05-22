classdef filterHelper

    methods (Static)

        function output = coefficients(cForward, cBackward, signal)

            % parsing inputs
            p = inputParser;
            addRequired(p, 'cForward', @(x) (nnz(x ~= 0)) > 0);
            addRequired(p, 'cBackward', @(x) (nnz(x ~= 0)) > 0);
            addRequired(p, 'signal', @validSignal);
            parse(p, cForward, cBackward, signal);
            q = p.Results;

            % get the size of the input signal:
            [samples, channels] = size(q.signal);

            % pre-allocate memory for the output:
            output = zeros([samples, channels]);

            num_forward = length(q.cForward);
            num_backward = length(q.cBackward) - 1;

            norm_cForward = q.cForward ./ q.cBackward(1);
            norm_cBackward = q.cBackward(2:end) ./ q.cBackward(1);

            % now we loop through the samples to apply the filter
            for sample_index = 1:samples

                % value of filtered sample starts at zero, then we add
                % values based on the difference equation
                filtered_sample = 0;

                f_index = 0;

                while (f_index < num_forward && f_index < sample_index)
                    filtered_sample = filtered_sample ...
                        + norm_cForward(1 + f_index) .* ...
                        q.signal(sample_index - f_index, :);
                    f_index = f_index + 1;
                end

                b_index = 1;

                while (b_index < num_backward && b_index < sample_index)
                    filtered_sample = filtered_sample ...
                        + norm_cBackward(b_index) .* ... % not b_index + 1
                        output(sample_index - b_index, :);
                end

                output(sample_index, :) = filtered_sample;
            end

        end

        function output = allpass1(centre_freq, sampling_freq, signal, ...
                varargin)

            p = inputParser;
            addRequired(p, 'centre_freq', @(x) (x < 0.5 * sampling_freq));
            addRequired(p, 'sampling_freq', @(x) (x ~= 0));
            addRequired(p, 'signal', @validSignal);
            addOptional(p, 'purpose', 'general', @allpassType);
            addOptional(p, 'gain', 0, @(x) (isnumeric(x)));
            parse(p, centre_freq, sampling_freq, signal, varargin{:});
            q = p.Results;

            if (q.gain >= 0)
                pole = 2 / (tan(pi * q.centre_freq / q.sampling_freq) + 1) - 1;

            elseif strcmp(q.purpose, 'lowshelf') && (q.gain < 0)
                c = (10^(q.gain / 20));
                pole = 2 * c / (tan(pi * q.centre_freq / q.sampling_freq) + c) - 1;
            elseif strcmp(q.purpose, 'highshelf') && (q.gain < 0)
                c = (10^(q.gain / 20));
                pole = 2 / (c * tan(pi * q.centre_freq / q.sampling_freq) + 1) - 1;
            else
                error('allpass purpose %s does not accept a negative gain', ...
                    q.purpose);
            end

            % get the size of the input signal:
            [samples, channels] = size(q.signal);

            % pre-allocate memory for the output:
            output = zeros([samples, channels]);
            output(1, :) = -pole * q.signal(1, :);

            for sample_index = 2:samples
                output(sample_index, :) = ...
                    q.signal(sample_index - 1, :) ...
                    - pole .* q.signal(sample_index, :) ...
                    + pole .* output(sample_index - 1, :);
            end

        end

        function output = lowpass1(centre_freq, sampling_freq, signal)
            % parsing inputs
            p = inputParser;
            addRequired(p, 'centre_freq', @(x) (x < 0.5 * sampling_freq));
            addRequired(p, 'sampling_freq', @(x) (x ~= 0));
            addRequired(p, 'signal', @validSignal);
            parse(p, centre_freq, sampling_freq, signal);
            q = p.Results;

            ap = filterHelper.allpass1(q.centre_freq, q.sampling_freq, ...
                q.signal);
            output = (q.signal + ap) ./ 2;
        end

    end

end
