function points = filterPoints(origPoints)

[origM, origDim] = size(origPoints);
threshold = 0.05;

% dim selection
dim_select = [5:7 11:13];  % [5:7 11:13];

% Filter, keeping samples with large deltas only
points = zeros(1, numel(dim_select));
points(1,:) = origPoints(1,dim_select);
m = 1;
for k=2:origM
  pt1 = origPoints(k,dim_select);
  % pt2 = origPoints(k - 1,dim_select);
  pt2 = origPoints(m,dim_select);
  distSq = dot(pt2 - pt1, pt2 - pt1);
  if distSq > threshold
     points = [points; origPoints(k,dim_select)];
     m = m + 1;
  end
end


pn = [];
for i = 1:size(points,1)
    pn(i) = norm(points(i,:), 2);
end
points = points / mean(pn);
disp(['norm factor: ' num2str(mean(pn))]);


%keyboard;



