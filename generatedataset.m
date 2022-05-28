function [truthDs, cleanDs, noisyDs, alphaSize] = generatedataset(noises, coeffFloor, coeffCeil, outputFilename)
% ECE4095 - Digital Storage on Synthetic DNA
% Written by Ryan Wee (28327519)
% This is the updated version of generatedataset that generates noise
% at varied levels to improve training performance

%% Inputs
% noises = number of noisy samples to generate per squiggle
% coeffFloor = lower artificial noise scale coefficient
% coeffCeil = upper artificial noise scale coefficient
% outputFilename = filename to save output dataset

%% Output
% Writes generated dataset directly to output file

tic

%% Read raw squiggles
fileQuery = dir('squiggles/*');
fileNames = {fileQuery.name};
fileNames = fileNames(3:end);

%% Read squiggle
fileToRead = append('squiggles/',char(fileNames(1)));
[base, current, sd, dwell] = readsquiggle(fileToRead);

%% Expand states
[~, concatCurrent, concatSd, concatDwell] = concatstates(base, current, sd, dwell);

%% Pre-allocate
close all
truthDs = cell(noises,1);
cleanDs = cell(noises,1);
noisyDs = cell(noises,1);

for  i = 1:noises
    %% Generate noise
    % Bypass if clean non-noise scaled results needed (eg. for testing)
    if coeffFloor == 1 && coeffCeil == 1
        [truth, clean, noisy] = generatenoise(base, concatCurrent, concatSd, concatDwell);
    else
        coeff = (coeffCeil-coeffFloor).*rand(1) + coeffFloor;
        [truth, clean, noisy] = generatenoise(base, concatCurrent, coeff*concatSd, concatDwell);
    end

    %% Save
    alphaSize = size(concatCurrent,1);
    for j = 1:alphaSize
        cumIdx = ((i-1)*alphaSize) + j;
        truthDs{cumIdx,1} = truth(j);
        cleanDs{cumIdx,1} = clean(j,:);
        noisyDs{cumIdx,1} = noisy(j,:);
    end

end

%% Write to .mat file
ds_truth.(outputFilename(1)) = truthDs;
save(outputFilename(1),"ds_truth");
ds_clean.(outputFilename(2)) = cleanDs;
save(outputFilename(2),"ds_clean");
ds_noisy.(outputFilename(3)) = noisyDs;
save(outputFilename(3),"ds_noisy");
fprintf('%i noisy sets were generated; ', noises)
toc
