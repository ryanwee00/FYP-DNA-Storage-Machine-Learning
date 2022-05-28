function [concatBase, concatCurrent, concatSd, concatDwell] = concatstates(base, current, sd, dwell)
% ECE4095 - Digital Storage on Synthetic DNA
% Written by Ryan Wee (28327519)

% Scrappie delivers mean value, concatstates combines previous and
% future states to return true value

%% Dimensions
% Buffer takes out 2 endpoint values at sequence start and end
basesPerState = 5;
bufferSize = (basesPerState-1)/2;

alphaSize = size(base,1);
alphaLength = size(base,2) - (2*bufferSize);

%% Pre allocate memory
concatBase = strings(alphaSize, alphaLength);
concatCurrent = zeros(alphaSize, alphaLength);
concatSd = zeros(alphaSize, alphaLength);
concatDwell = zeros(alphaSize, alphaLength);

%% Loop through
for i = 1:alphaSize
    for j = (1+bufferSize):(alphaLength+bufferSize)
        concatBase(i, j-bufferSize) = append(base(i, j-2), base(i, j-1), base(i, j), base(i, j+1), base(i, j+2));
        concatCurrent(i, j-bufferSize) = current(i, j);
        concatSd(i, j-bufferSize) = sd(i, j);
        concatDwell(i, j-bufferSize) = dwell(i, j);
    end
end
