function r = struct2row(s)
% Convert struct with fieldnames as keys to Row object for Cassandra db.
%   Guesses the appropriate type

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
    
    % Select type
    %   Note: default Matlab types are a subset of CQL and Java types
    %   E.g., floating point numbers -> doubles
    if isjava(val)
        if strcmpi(class(val), 'java.util.Date')
            type = 'timestamp';
        else
            error('Error: Java type %s in Matlab not recognized.', class(val))
        end
    elseif isinteger(val)
        if isa(val, 'int32')
            type = 'int';
        elseif isa(val, 'int64')
            type = 'long';
        else
            type = 'int';
        end % default
    elseif isfloat(val)
        if isa(val, 'double')
            type = 'double';
        elseif isa(val, 'single')
            type = 'float';
        else % default
            type = 'double';
        end
    elseif ischar(val)
        type = 'varchar';
    elseif islogical(val)
        type = 'boolean';
    end
    
    % Assign type
    colTypes{i} = type;
    
    % Assign field name
    colNames{i} = fields{i};
end

r.cols = cols;
r.colTypes = colTypes;
r.colNames = colNames;