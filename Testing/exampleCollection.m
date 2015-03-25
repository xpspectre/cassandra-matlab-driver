% Run example collections ops
clear; close all; clc

%% Make new table with collection
% col = [];
% col.id = 'int';
% col.val = 'double';
% col.data = 'list<double>';
% 
% m = MatlabDriver;
% 
% m.createTable('testcol', col, 'id');
% 
% m.close;

%% Add entries to table
% m = MatlabDriver;
% 
% nDatapoints = 3;
% for i = 1:nDatapoints
%     
%     s = [];
%     s.id = int32(randi([0,1e6]));
%     s.val = rand;
%     s.data = rand(1,5);
%     
%     r = struct2row(s);
%     
%     m.insert('testcol', r);
% 
% end
% 
% m.close;

%% Retrieve entries from table
m = MatlabDriver;

r = m.select('testcol');

xs = {};
while ~r.exhausted
    x = row2struct(r.next);
    xs = [xs; x];
end

m.close;