% ECE4095 - Digital Storage on Synthetic DNA
% Written by Ryan Wee (28327519)
clear all
clc

%% Generate or import dataset
% Row - sample (row 1 - reference)
% Col - squiggle (different alphabet sets)
generateDatasetFlag = true;
normaliseFlag = false;

if generateDatasetFlag == true
    % Generate multiple noisy datasets
    % Artificial scaling of nosie variance can be performed to improve
    % robustness

    % Scaled and non-scaled data used for training and validation
    % Only non-scaled data used for testing
    % Scale ratio represents proportion of scaled data used
    % Testset ratio represents size of testing dataset relative to
    % training and validation dataset size
    datasetSize = 15000;
    scaleRatio = 0;
    testsetRatio = 0.2;
    coeffFloor = 0.8;
    coeffCeil = 1.5;
    scaleSize = floor(datasetSize*scaleRatio);
    testsetSize = floor(datasetSize*testsetRatio);
    if scaleSize ~= 0
        [truthDsScale, cleanDsScale, noisyDsScale, ~] = generatedataset(scaleSize, coeffFloor, coeffCeil, ["ds_sc_truth","ds_sc_clean","ds_sc_noisy"]);
    end
    [truthDsNonsc, cleanDsNonsc, noisyDsNonsc, alphaSize] = generatedataset((datasetSize-scaleSize), 1, 1, ["ds_ns_truth","ds_ns_clean","ds_ns_noisy"]);
    [truthDsTest, cleanDsTest, noisyDsTest, ~] = generatedataset(testsetSize, 1, 1, ["ds_test_truth","ds_test_clean","ds_test_noisy"]);
else
%     % Load all mat files within folder
%     % Currently broken
%     datasetDir = dir('*.mat');
%     for i = 1:length(datasetDir)
%         load(datasetDir(i).name);
% 
%         if fieldnames(output) == "ds_scale"
%             scaleDataset = output.ds_scale;
%             clear output.ds_scale
%         elseif fieldnames(output) == "ds_nonscale"
%             nonscaleDataset = output.ds_nonscale;
%             clear output.ds_nonscale
%         elseif fieldnames(output) == "ds_test"
%             testDataset = output.ds_test;
%             clear output.ds_test
%         end
%     end
end

%% Process dataset
% Noises are the noisy signals
% Labels are ground truths (DNA base strings)
% Combine scaled and non scaled datasets
if scaleSize == 0
    noises = noisyDsNonsc;
    labels = truthDsNonsc;
else
    noises = [noisyDsScale; noisyDsNonsc];
    labels = [truthDsScale; truthDsNonsc];
end

% Normalise dataset with Z-score for mean 0 stdev 1
if normaliseFlag == true
    % Note that dataset is normalised on a per-cell basis
    % This is not good practice but is done to save complexity
    noises = cellfun(@normalize,noises,'UniformOutput',false);
    noisyDsTest = cellfun(@normalize,noisyDsTest,'UniformOutput',false);
end

% Randomly divide targets into training and validation sets
% Testing dataset bypasses this step as only an unscaled dataset is used
trainRatio = 0.7;
valRatio = 1-trainRatio;
testRatio = 0;
[trainInd, valInd, ~] = dividerand(length(noises), trainRatio, valRatio, testRatio);

% Create training, validation and testing sets
% trainSet = noises(trainInd);
% trainLabel = labels(trainInd);
% 
% testSet = noisyDsTest;
% testLabel = truthDsTest;
% 
% valSet = cell(1,2);
% noises(valInd);
% testSet = testDataset;
trainSet = cellfun(@transpose,noises(trainInd),'un',0);
trainLabel = cellfun(@transpose,labels(trainInd),'un',0);
valSet = cellfun(@transpose,noises(valInd),'un',0);
valLabel = cellfun(@transpose,labels(valInd),'un',0);
testSet = cellfun(@transpose,noisyDsTest,'un',0);
testLabel = cellfun(@transpose,truthDsTest,'un',0);

% Concatenate validation dataset
% valSetConc = cell(1,2);
% valSetConc(1,1) = {valSet(:,1)};
% valSetConc(1,2) = {valLabel(:,1)};

% Convert labels to categorical
trainLabel = categorical(string(trainLabel));
testLabel = categorical(string(testLabel));
valLabel = categorical(string(valLabel));

%% Network architecture
% Define network architecture
inputSize = size(trainSet{1},1);
numHiddenUnits = 150;        % proportional to complexity
numClasses = alphaSize;

fc3 = alphaSize;
fc2 = sqrt(fc3);
fc1 = sqrt(fc2);

layers = [
    sequenceInputLayer(inputSize)
    bilstmLayer(numHiddenUnits, 'OutputMode', 'last')
    bilstmLayer(numHiddenUnits, 'OutputMode', 'last')
    bilstmLayer(numHiddenUnits, 'OutputMode', 'last')
    %bilstmLayer(numHiddenUnits, 'OutputMode', 'last')
    %fullyConnectedLayer(fc1)
    %batchNormalizationLayer
    %fullyConnectedLayer(fc2)
    %batchNormalizationLayer
    fullyConnectedLayer(fc3)
    softmaxLayer
    classificationLayer]

% Specify training options
maxEpochs = 7;
miniBatchSize = 256;
valFreq = 100;

options = trainingOptions('adam', ...
    ExecutionEnvironment = 'cpu', ...
    MaxEpochs = maxEpochs, ...
    MiniBatchSize = miniBatchSize, ...
    LearnRateSchedule = 'piecewise', ...
    InitialLearnRate = 1e-2, ...
    LearnRateDropFactor = 0.5, ...
    LearnRateDropPeriod = 1, ...
    ValidationData = {valSet, valLabel}, ...
    ValidationFrequency = valFreq, ...
    GradientThreshold = 1, ...
    Shuffle = 'every-epoch', ...
    Verbose = false, ...
    SequenceLength = 'longest', ...
    Plots = 'training-progress', ...
    OutputNetwork = 'last-iteration')

%% Train network
trainNetFlag = true;

if trainNetFlag == true
    net = trainNetwork(trainSet, trainLabel, layers, options);
    save net
else
    load("net.mat");
end

%% Denoise noisy signals with network
testPred = predict(net, testSet, 'ReturnCategorical', true);
accuracy = 0;

for i = 1:size(testSet,1)
    if testPred(i) == testLabel(i)
        accuracy = accuracy + 1;
    end
end

accuracy = accuracy/size(testSet,1);
    





% %% Denoise noisy signals with network
% % Preallocate MSE arrays
% % denoised = zeros(length(testSet));
% mseDenoised = zeros(length(testSet));
% mseNoisy = zeros(length(testSet));
% denoised = predict(net, testSet);
% 
% %% Quantify results
% % Calculate MSE
% accuracy = 0;
% for i = 1:length(testSet)
%     mseDenoised(i) = sum((testLabel{i} - denoised{i}).^2)/numel(denoised);
%     mseNoisy(i) = sum((testLabel{i} - testSet{i}).^2)/numel(denoised);
%     for j = 1:size(testSet{1},1)
%         if testSet{i}(j) == testLabel{i}(j)
%             accuracy = accuracy + 1;
%         end
%     end
% end
% 
% mseDenoised = mseDenoised(:,1);
% mseNoisy = mseNoisy(:,1);
% 
% % Plot MSE
% figure
% plot(mseNoisy)
% hold on
% plot(mseDenoised)
% title('MSE of Noisy and Denoised Test Dataset')
% legend('MSE noisy', 'MSE denoised')
% 
% % Overlay average MSE
% mseText = {'Average MSE:',['Noisy = ' num2str(mean(mseNoisy))],['Denoised = ' num2str(mean(mseDenoised))]};
% text(80,200,mseText)

