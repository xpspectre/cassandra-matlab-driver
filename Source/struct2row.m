function r = struct2row(s)
% Convert struct with fieldnames as keys to Row object for Cassandra db.

fields = fieldnames(s);
nFields = length(fields);

r = Row;
r.size = nFields;

cols = cell(1, r.size);
colTypes = cell(1, r.size);
colNames = cell(1, r.size);

for i = 1:length(fields)
    
    val = s.(fields{i});
    
    % Assign value directly
    cols{i} = val;
    
    % Assign type
    [~, colTypes{i}] = getCQLStringAndTypeFromMatlabVal(val);
    
    % Assign field name
    colNames{i} = fields{i};
end

r.cols = cols;
r.colTypes = colTypes;
r.colNames = colNames;