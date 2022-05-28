function [base, current, sd, dwell] = readsquiggle(filename)
%% squiggle format
% pos = position along reference
% base = base from reference at position
% current = normalised current
% sd = standard dev of normalised current
% dwell = samples

%% read file
table = readtable(filename);

%% split table into arrays
baseLength = max(table.pos)+1;
noOfSequences = (height(table)+2)/(baseLength+2);

base = strings(noOfSequences,baseLength);
current = zeros(noOfSequences,baseLength);
sd = zeros(noOfSequences,baseLength);
dwell = zeros(noOfSequences,baseLength);
kTable = 1;

for iSeq = 1:noOfSequences
    for jBase = 1:baseLength
        base(iSeq,jBase) = table.base(kTable);
        current(iSeq,jBase) = table.current(kTable);
        sd(iSeq,jBase) = table.sd(kTable);
        dwell(iSeq,jBase) = table.dwell(kTable);
        kTable = kTable+1;
    end
    kTable = kTable+2;
end