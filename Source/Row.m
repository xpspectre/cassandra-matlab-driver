classdef Row
    %
    % colTypes contains CQL types. Functions that create Rows from Matlab
    % objects need to handle type conversion.
    %
    % TODO: Should cols be allowed to be arbitrary datatypes (e.g., arrays for particular efficient uses)? or must
    % they be cell arrays (general mixed use)?
    %
    % Note: % 0-indexing in col def Java object
    % Note: may conflict with Row from Matlab tables
    
    properties
        size
        cols
        colTypes
        colNames
    end
    
    methods
        
        function obj = Row(row)
            
            % Default constructor makes empty Row
            if nargin < 1
                row = [];
            end
            if isempty(row)
                obj.size = 0;
                obj.cols = {};
                obj.colTypes = {};
                obj.colNames = {};
                return
            end
            
            % Get number of columns
            cd = row.getColumnDefinitions;
            obj.size = cd.size;
            
            % Get column types
            obj.colTypes = cell(1, obj.size);
            for i = 1:obj.size
                obj.colTypes{i} = char(cd.getType(i-1)); 
            end
            
            % Get column names
            obj.colNames = cell(1, obj.size);
            for i = 1:obj.size
                obj.colNames{i} = char(cd.getName(i-1));
            end
            
            % Get actual column data, converting to Matlab types
            obj.cols = cell(1, obj.size);
            for i = 1:obj.size
                
                % Convert CQL types -> Matlab types
                type = obj.colTypes{i};
                switch type
                    case 'int'
                        data = int32(row.getInt(i-1));
                    case 'long'
                        data = int64(row.getLong(i-1));
                    case 'float'
                        data = single(double(row.getFloat(i-1))); % check this; no direct java.lang.Float -> Matlab single
                    case 'double'
                        data = double(row.getDouble(i-1));
                    case 'text'
                        data = char(row.getString(i-1));
                    case 'varchar'
                        data = char(row.getString(i-1));
                    case 'boolean'
                        data = row.getBool(i-1);
                    case 'timestamp'
                        data = row.getDate(i-1); % returns java.util.Date object
                    case 'uuid'
                        data = row.getDate(i-1); % returns java.util.UUID object
                    otherwise
                        % Collection types or not recognized
                        if strncmpi(type, 'list', 4)
                            subParts = strsplit(type, {'<','>'});
                            subType = subParts{2};
                            if strcmpi(subType, 'double')
                               data = cell2mat(cell(row.getList(i-1, java.lang.Double(1).getClass).toArray))';
                            else
                                error('Error: list element type %s not recognized.', type)
                            end
                        else
                            error('Error: type %s not recognized.', type)
                        end
                end
                
                obj.cols{i} = data;
            end
            
            
        end
        
    end
    
end

%% Helper functions

function matlabVal = extractMatlabValFromRow(row, i)

end