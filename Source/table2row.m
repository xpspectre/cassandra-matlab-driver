function r = table2row(tab)
% Convert Matlab table to Row object for Cassandra db.
% Note: Row is a single row, so take first row of table

if height(tab) > 1
    warning('Input table has multiple rows. Only taking first one.')
end
t = tab(1,:);

% Get table properties
p = t.Properties;

% Assign col names directly
colNames = p.VariableNames;

% Make new Row object
r = Row;
r.size = length(colNames);

% Assign values and types
cols = cell(1, r.size);
colTypes = cell(1, r.size);
for i = 1:r.size
    
    % Tables with column vectors store them in a cell array
    %   Unpack and transpose
    %   Note: Assumes this situation and not others.
    val = t{1,i};
    if iscell(val)
%         warning('Column vector detected. Unpacking and transposing for row conversion.')
        val = val{1}';
    end
    
    % Assign col val
    cols{i} = val;
    
    % Assign col type
    [~, colTypes{i}] = getCQLStringAndTypeFromMatlabVal(cols{i});
    
end

r.cols = cols;
r.colTypes = colTypes;
r.colNames = colNames;