classdef Results < handle
% Returns results one-by-one from query
% Functions as an iterator; call next() to get next item
% Note: handle class because next()/one() are stateful

    properties
        exhausted
        results
    end
    
    methods
        
        function obj = Results(result)
            obj.results = result;
            obj.exhausted = obj.results.isExhausted;
        end
        
        function row = next(obj)
            % Iterates thru results object
            if ~obj.exhausted
                row = Row(obj.results.one());
                obj.exhausted = obj.results.isExhausted;
            else
                row = [];
            end
        end
        
    end
    
end