function s = row2struct(r)
% Convert CQL returned Row object to Matlab struct.

s = [];
for i = 1:r.size
    s.(r.colNames{i}) = r.cols{i};
end