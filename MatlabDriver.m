classdef MatlabDriver
    % Matlab Cassandra driver that uses Java Cassandra driver
    % Single cluster, single keyspace for now
    
    properties
        cluster
        session
    end
    
    methods
        
        function obj = MatlabDriver(varargin)
            % Class constructor initiates stateful db connection
            % Inputs:
            %   clusterName: string with one of the cluster nodes
            %   sessionName: keyspace to connect to
            
            % Fill in missing inputs
            if nargin < 2
                sessionName = [];
                if nargin < 1
                    clusterName = [];
                end
            end
            
            % Set default inputs
            if isempty(clusterName)
                clusterName = 'bt2000q-02';
            end
            if isempty(sessionName)
                sessionName = 'demo';
            end
            
            % Call Java Cassandra driver to initialize db connection
            obj.cluster = com.datastax.driver.core.Cluster.builder().addContactPoint(clusterName).build();
            obj.session = obj.cluster.connect(sessionName);
            
        end
        
        function delete(obj)
            % Class destructor closes connection
            obj.close;
        end
        
        function close(obj)
            % Close db connection
            obj.cluster.close();
        end
        
        function results = execute(obj, command)
            % Execute raw CQL statement
            %   Note: need to escape single quotes "'" with another single quote
            results = Results(obj.session.execute(command));
        end
        
        % General db commands that generate corresponding CQL strings
        
        function insert(obj, table, row)
            %
            % Inputs:
            %   table: string
            %   row: Row
            
            % Make CQL statement
            keys = strjoin(row.colNames, ', ');
            vals = strjoin(cellfun(@cqlClean, row.cols, 'UniformOutput', false), ', ');
            
            cql = ['INSERT INTO ', table, ' (', keys, ') VALUES (', vals, ')'];
            fprintf([cql, '\n']) % DEBUG
            obj.execute(cql);
        end
        
        function results = select(obj, table, key, val, order, limit)
            %
            % Note: nargin includes first obj arg in methods
            %
            % Inputs:
            %   table: string
            %   key: string or cell array of strings
            %   val: string or cell array of strings
            %   order: string or cell array of strings, column (ASC default) or {column,
            %       'ASC'/'DESC'}
            %   limit: integer, max number of entries to return
            % Outputs:
            %   results: Results object
            
            
            % Clean up inputs
            if nargin < 6
                limit = [];
                if nargin < 5
                    order = [];
                    if nargin < 4
                        val = [];
                        if nargin < 3
                            key = [];
                        end
                    end
                end
            end
            
            % Make CQL statement
            selections = [];
            filtering = [];
            
            % Selection
            if ~isempty(key) && ~isempty(val)
                selections = cqlRowSpec(key, val);
                if iscell(key) && iscell(val) && length(key) > 1
                    filtering = ' ALLOW FILTERING'; % assume you want this
                end
            end
            
            % Ordering
            if ~isempty(order)
                if iscell(order) && length(order) == 2
                    orderKey = order{1};
                    orderOp = order{2};
                    assert(strcmpi(orderOp, 'ASC') || strcmpi(orderOp, 'DESC'), 'Error: ordering operation %s not recognized.', orderOp)
                elseif ischar(order)
                    orderKey = order;
                    orderOp = 'ASC';
                else
                    error('Error: ordering format not recognized.')
                end
                ordering = [' ORDER BY ', orderKey, ' ', orderOp];
            else
                ordering = [];
            end
            
            % Returned entries limit
            if ~isempty(limit)
                intLimit = int32(limit);
                assert(intLimit > 0, 'Error: limit must be a positive integer.')
                limiting = [' LIMIT ', int2str(intLimit)];
            else
                limiting = [];
            end
            
            cql = ['SELECT * FROM ', table, selections, filtering, ordering, limiting];
            fprintf([cql, '\n']) % DEBUG
            results = obj.execute(cql);
            
        end
        
        function update(obj, table, key, val, assignment)
            %
            % Inputs:
            %   table: string
            %   key: string or cell array of strings, specifies row
            %   val: string or cell array of strings, specifies row
            %   assignment: struct with fieldnames as keys and vals as vals to modify
            
            % Make CQL statement
            fields = fieldnames(assignment);
            
            % First update
            updates = [fields{1}, ' = ', cqlClean(assignment.(fields{1}))];
            
            % More updates
            if length(fields) > 1
                for i = 2:length(fields)
                    updates = [updates, ', ', fields{i}, ' = ', cqlClean(assignment.(fields{i}))];
                end
            end
            
            % Primary keys to select row to update
            selections = cqlRowSpec(key, val);
            
            cql = ['UPDATE ', table, ' SET ', updates, selections];
            fprintf([cql, '\n']) % DEBUG
            obj.execute(cql);
            
        end
        
        function remove(obj, table, key, val)
            %
            % Inputs:
            %   table: string
            %   key: string or cell array of strings, specifies row
            %   val: string or cell array of strings, specifies row
            % Note: should be called 'delete', but that's reserved for destructor
            % TODO: make this also delete selected columns
            
            % Make CQL statement
            selections = cqlRowSpec(key, val);
            
            cql = ['DELETE FROM ', table, selections];
            fprintf([cql, '\n']) % DEBUG
            obj.execute(cql);
            
        end
        
        function createTable(obj, name, schema, primaryKey, properties)
            %
            % Inputs:
            %   name: string, table name
            %   schema: struct, key(string).type(string)
            %   primaryKey: string or cell array of strings, primary key(s) with
            %       1st as partition key
            %   properties: cell array of strings, literal property specs
            
            if nargin < 5
                properties = [];
            end
            
            % Make CQL statement
            % Add schema
            keys = fieldnames(schema);
            schemaList = [];
            for i = 1:length(keys);
                schemaList = [schemaList, keys{i}, ' ', schema.(keys{i}), ', '];
            end
            
            % Add primary keys
            primaryKeyList = 'PRIMARY KEY (';
            if ischar(primaryKey) % single primary key
                primaryKeyList = [primaryKeyList, primaryKey];
            else % compound primary key
                primaryKeyList = [primaryKeyList, primaryKey{1}];
                for i = 2:length(primaryKey)
                    primaryKeyList = [primaryKeyList, ', ', primaryKey{i}];
                end
            end
            primaryKeyList = [primaryKeyList, ')'];
            
            % Add optional properties
            propertiesList = [];
            if ~isempty(properties)
                assert(iscell(properties), 'Error: properties list must be a cell array.')
                propertiesList = [' WITH ' properties{1}];
                for i = 2:length(properties)
                    propertiesList = [propertiesList, ' AND ', properties{i}];
                end
            end
            
            cql = ['CREATE TABLE ', name, '(', schemaList, primaryKeyList ')', propertiesList];
            fprintf([cql, '\n']) % DEBUG
            obj.execute(cql);
            
        end
        
        function createIndex(obj, table, key, index)
            %
            % Inputs:
            %   table: string
            %   key: string
            %   index: string, alias to index on key
            
            if nargin < 4
                index = [];
            end
            
            if ~isempty(index)
                indexAlias = [index, ' '];
            else
                indexAlias = [];
            end
            
            cql = ['CREATE INDEX ', indexAlias, 'ON', table, ' (', key, ')'];
            fprintf([cql, '\n']) % DEBUG
            obj.execute(cql);
            
        end
        
    end
    
end

%% Helper functions

function output = cqlClean(input)
% Cleans up input vals for CQL statement strings
%   Converts java.util.Date/CQL timestamps into integer format
%   Escapes/quotes string-like vals
%   Converts numbers to strings
if strcmpi(class(input), 'java.util.Date')
    output = num2str(int64(input.getTime));
elseif strcmpi(class(input), 'java.util.UUID')
    output = char(input);
elseif isinteger(input)
    output = int2str(input);
elseif isfloat(input)
    output = num2str(input, 16);
elseif ischar(input)
    output = ['''',  input, ''''];
else
    error('Error: Type for command parsing not recognized.')
end
end

function selections = cqlRowSpec(key, val)
% Row specification string for select(), update(), and remove()
% Be sure to specify all primary keys for compound keys
%   key: string or cell array of strings
%   val: string or cell array of strings

% First selection
if iscell(key) && iscell(val) % filter on multiple keys
    firstKey = key{1};
    firstVal = cqlClean(val{1});
else
    firstKey = key;
    firstVal = cqlClean(val);
end
selections = [' WHERE ', firstKey, ' = ', firstVal];

% Remaining selections
if iscell(key) && iscell(val) && length(key) > 1
    for i = 2:length(key)
        nextKey = key{i};
        nextVal = cqlClean(val{i});
        selections = [selections, ' AND ', nextKey, ' = ', nextVal];
    end
end
end
