function [truth, clean, noisy] = generatenoise(base, current, sd, dwell)
% ECE4095 - Digital Storage on Synthetic DNA
% Written by Ryan Wee (28327519)

desiredSamples = 150;
truth = strings(size(current,1),1);
noisy = zeros(desiredSamples);
clean = zeros(desiredSamples);

for i = 1:size(current,1)
    appendNoisy = [];
    appendClean = [];
    for j = 1:size(current,2)
        % Number of samples per state, N
        % Random value from geometric distribution
        % Probability parameter P determined by 1/dwell
        % Reject inputs beyond geom(x) range
        p = 1/dwell(i,j);
        if p > 1
            continue
        end
        N = geornd(p);
        
        % Append and return
        ampVec = normrnd(current(i,j), sd(i,j), 1, N);
        appendNoisy = [appendNoisy ampVec];
        appendClean = [appendClean current(i,j).*ones(1, ceil(dwell(i,j)))];
    end

    % Resample to target number of samples
    % Optimise filter for large transients for clean signal
    n = 5;      % Kaiser filter window length
    beta = 30;  % Smoothing factor
    appendNoisy = resample(appendNoisy, desiredSamples, length(appendNoisy));
    appendClean = resample(appendClean, desiredSamples, length(appendClean), n, beta);

    % Form output matrix
    truth(i) = join(base(i,[7:18]));
    noisy(i,:) = appendNoisy;
    clean(i,:) = appendClean;
end