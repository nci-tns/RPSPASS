function [testArray]=testRange(input, threshold)

yData = sort(input);
toTest = yData(end)-threshold;
toTestInd = yData < toTest;
output = yData(toTestInd);

if isempty(output)

    testArray = yData(1);

else
    testArray = yData(1:numel(output)+1);

end

end