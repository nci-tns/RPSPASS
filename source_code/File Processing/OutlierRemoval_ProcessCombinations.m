function [Best]=OutlierRemoval_ProcessCombinations(iteration, index, IndexFields, test)

% set default outlier gating
Best_num = 0;
Best.NoCombs = size(index.uniquecomb,1); % get total number of unique combinations
test_fieldNo = test.fieldNo;
thresholdSets = test.thresholdSets;


% test each unique combination to maximize sets meeting threshold
% criteria within range
for i = 1:Best.NoCombs
    test_array = [];
    proceed = true;

    % build testing array for each unique combination
    for ii = 1:numel(IndexFields)
        test_array = [test_array, index.(IndexFields{ii})(:,index.uniquecomb(i,ii))];
        if sum(sum(test_array,2) == size(test_array,2)) < thresholdSets
            proceed = false;
            break
        end
    end

    if proceed == true
        test_index = sum(test_array,2)==test_fieldNo;
        test_events = sum(test_index);

        % test array has more passing sets than current best save it
        if test_events > Best_num
            Best_index = test_index;
            Best_num = sum(Best_index);
            Best_uniqueComb = index.uniquecomb(i,:);
        end
    end
end


% number of sets in best index
Best.num = Best_num;

if Best.num ~= 0
    Best.index = Best_index;

    % obtain threshold values for each tested criteria
    for ii = 1:numel(IndexFields)
        Best.(IndexFields{ii}) = iteration.(IndexFields{ii})(Best_uniqueComb(ii));
    end
end

end