
num_clusters =  28;     % number of clusters in our emission alphabet
num_states = 8;         % number of states in hmm
hmm_width = 3;          % numbef of next states to distribute the initial transition probability over

[data, total_samples] = readTrainingExamplesAll({'triangles', 'circles', 'bowling','upflips','rightflips'});
% training and testing are each cell arrays containing a cell array for
% each gesture. Each of these gesture cell arrays contains a matrix of
% accel data.


% num_folds = total_samples;
% fold_labels = crossvalind('Kfold', total_samples, num_folds);
% kfold_ind = cell(1,numel(data));
% segment_index = 0;
% for g = 1:numel(data)
%     kfold_ind{g} = fold_labels(segment_index+1:numel(data{g}));
%     segment_index = segment_index + numel(data{g});
% end


% scramble data
% for scrams = 1:(numel(data{1})+numel(data{2}))
%     ind1 = Sample(1:numel(data{1}));
%     ind2 = Sample(1:numel(data{2}));
%     temp = data{1}(ind1);
%     data{1}(ind1) = data{2}(ind2);
%     data{2}(ind2) = temp;
% end


num_folds = 10;
kfold_ind = cell(1,numel(data));
for g = 1:numel(data)
    kfold_ind{g} = crossvalind('Kfold', numel(data{g}), num_folds);
end

accuracy = zeros(1,num_folds);
for fold = 1:num_folds
    
    % split the data into these vars for this fold
    training = cell(1,numel(data));
    testing = cell(1,numel(data));
    for g = 1:numel(data)
        training{g} = data{g}(kfold_ind{g} ~= fold);
        testing{g} = data{g}(kfold_ind{g} == fold);
    end
    
    % collect all training data samples together for clustering
    allData = zeros(0, size(training{1}{1},2));
    for k=1:numel(training)
        exampleData = vertcat(training{k}{:});
        allData = [allData ; exampleData];
    end
    
    % computer cluster centroids
    
    clust = computeClusters(allData, num_clusters);
    % computer delauny simplices from cluster centroids
    T = delaunayn(clust);
    
    
    prior_init = 1/num_states * ones(num_states,1);
    emission_init = 1/num_clusters * ones(num_states, num_clusters); % init emission matrix with first guess
%     trans_init = ...                % init transistion matrix with first guess
%         [ 1/3 1/3 1/3 0 0 0 0 0; ...
%         0 1/3 1/3 1/3 0 0 0 0; ...
%         0 0 1/3 1/3 1/3 0 0 0; ...
%         0 0 0 1/3 1/3 1/3 0 0; ...
%         0 0 0 0 1/3 1/3 1/3 0; ...
%         0 0 0 0 0 1/3 1/3 1/3; ...
%         0 0 0 0 0 0 1/2 1/2; ...
%         0 0 0 0 0 0 0 1 ...
%         ];

    trans_init = zeros(num_states);
    for st=1:hmm_width
       trans_init = trans_init + diag(ones(num_states - st + 1, 1), st - 1);  
    end
    
    Z = sum(trans_init,2); 
    S = Z + (Z==0);
    norm = repmat(S, 1, size(trans_init,2));
    trans_init = trans_init ./ norm;
    
    % prior_init = normalise(rand(8,1));
    % trans_init = mk_stochastic(rand(8,8));
    % emission_init = mk_stochastic(rand(8, num_clusters));
    
    
    transmats = cell(size(training));   % holds the learned transistion matrix for each gesture HMM
    obsmats = cell(size(training));     % holds the learned emission matrix for each geture HMM
    
    for k=1:numel(training)
        gestureExamples = training{k};
        numExamples = numel(gestureExamples);
        
        % convert training samples into symbol sequences
        seq = cell(1, numExamples);
        for l=1:numExamples
            seq{l} = dsearchn(clust, T, gestureExamples{l})';
        end
        
        % train and save the HMM
        [transmat, obsmat] = hmmtrain(seq, trans_init, emission_init, 'maxiterations', 15, 'verbose', false);
        transmats{k} = transmat;
        obsmats{k} = obsmat;
    end
    
    
    % test classifier
    num_gestures = numel(testing);
    num_correct = 0;
    num_total = 0;
    for g = 1:num_gestures
        for k = 1:numel(testing{g})
            % discretize
            seq = dsearchn(clust, T, testing{g}{k})';
            %seq = seq(randperm(numel(seq)));
            
            % try all HMMs
            loglik = zeros(1, num_gestures);
            for l = 1:num_gestures
                [PSTATES loglik(l)] = hmmdecode(seq, transmats{l}, obsmats{l});
            end
            [val, ind] = max(loglik);   % find max loglik gesture model
            if ind == g
                num_correct = num_correct + 1;
            end
            num_total = num_total + 1;
        end
    end
    disp(['Accuracy of ' num2str(num_correct / num_total) ' on ' num2str(num_total) ' test samples']);
    accuracy(fold) = num_correct / num_total;
end
disp(['Overall accuracy of ' num2str(mean(accuracy)) ' on ' num2str(num_folds) '-fold cross validation']);


% allData = readAccelData('../data/circles/xbowSensorLog.txt');
%
% origPoints = allData(:,5:7);
%
% hold on
% scatter3(origPoints(:,1), origPoints(:,2), origPoints(:,3), 2, 'k')
%
% [IDX, C] = computeClusters(origPoints);
%
% IDX
% C
% clustSizes = zeros(dictSize, 1);
% for k=1:m
%   clustSizes(IDX(k)) = clustSizes(IDX(k)) + 1;
% end
%
% maxSize = max(clustSizes);
% clustSizes = clustSizes ./ (maxSize / 10);
%
% scatter3(C(:,1), C(:,2), C(:,3), clustSizes * 5, 'b')

