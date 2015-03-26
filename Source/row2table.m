function t = row2table(r)
% Convert CQL returned Row object to Matlab table.

t = struct2table(row2struct(r));