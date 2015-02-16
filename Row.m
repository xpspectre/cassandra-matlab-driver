classdef Row
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
                
                % Current supported CQL types -> Matlab types:
                switch obj.colTypes{i}
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
                    otherwise
                        error('Error: type %s not recognized.', obj.colTypes{i})
                end
                
                obj.cols{i} = data;
            end
            
            
            

        end
        
    end
    
end