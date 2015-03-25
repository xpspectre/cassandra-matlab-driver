% Run example boolean
clear; close all; clc

%% Make new table with collection
% col = [];
% col.id = 'int';
% col.val = 'boolean';
% 
% m = MatlabDriver;
% 
% m.createTable('testbool', col, 'id');
% 
% m.close;

%% Add entries to table
% m = MatlabDriver;
% 
% nDatapoints = 4;
% for i = 1:nDatapoints
%     
%     s = [];
%     s.id = int32(randi([0,1e6]));
%     s.val = rand < 0.5;
%     
%     r = struct2row(s);
%     
%     m.insert('testbool', r);
%     
% end
% 
% m.close;

%% Retrieve entries from table
m = MatlabDriver;

r = m.select('testbool');

xs = {};
while ~r.exhausted
    x = row2struct(r.next);
    xs = [xs; x];
end

m.close;