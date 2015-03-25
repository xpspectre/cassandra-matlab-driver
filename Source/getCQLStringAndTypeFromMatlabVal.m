function [string, type] = getCQLStringAndTypeFromMatlabVal(value)
% Get CQL value string representation and type string from Matlab value.
% For converting Matlab types -> CQL types
%   Note: default Matlab types are a subset of CQL and Java types
%   E.g., floating point numbers -> doubles
% Note: only list collection types are supported now.

%% Check if this is a collection
isCollection = false;

valueDims = size(value);
maxDim = max(valueDims);

% Only allow vectors, not matrices
if sum(valueDims > 1) > 1
    error('Error: Matlab matrix input not allowed.')
end

if ~ischar(value) && any(valueDims > 1) % matrix/regular array
    isCollection = true;
    val = value(1);
elseif iscell(value) && any(valueDims) > 1 % cell array
    isCollection = true;
    val = value{1};
else % not a collection
    val = value;
end

% Force row vectors only
%   Easier to deal with in table form
if isCollection && valueDims(1) > 1
    warning('List is a Matlab column vector input; transposing into row vector.')
end

%% Process base types
[string, type] = getBaseCQLStringAndTypeFromMatlabVal(val);

%% Additional modifications for collections
if isCollection
    % Modify type
    type = ['list<', type, '>'];
    
    % Build entire collection string
    string = ['[', string];
    for i = 1:maxDim
        if iscell(value)
            val = value{i};
        else
            val = value(i);
        end
        string = [string, ', ', getBaseCQLStringAndTypeFromMatlabVal(val)];
    end
    string = [string, ']'];
end


%% Helper functions
function [string, type] = getBaseCQLStringAndTypeFromMatlabVal(value)

if isjava(value)
    if strcmpi(class(value), 'java.util.Date')
        type = 'timestamp';
        string = num2str(int64(value.getTime));
    elseif strcmpi(class(value), 'java.util.UUID')
        type = 'uuid';
        string = char(value);
    else
        error('Error: Java type %s in Matlab not recognized.', class(value))
    end
elseif isinteger(value)
    if isa(value, 'int64')
        type = 'long';
    else % default, int32
        type = 'int';
    end
    string = int2str(value);
elseif isfloat(value)
    if isa(value, 'single')
        type = 'float';
        string = num2str(value, 10);
    else % default, double
        type = 'double';
        string = num2str(value, 16);
    end
elseif ischar(value)
    type = 'varchar';
    string = ['''',  value, ''''];
elseif islogical(value)
    type = 'boolean';
    if value
        string = 'true';
    else
        string = 'false';
    end
else
    error('Error: Type for command parsing not recognized.')
end
