function testCluster
% Test script for cluster

runName = 'test1';
nCores = 3;

% cluster = 'thor';
cluster = 'vali';
fun = 'testSession';
inputs = cell(1, nCores);
for i = 1:nCores
    inputs{i} = {i}; % remember to give it a cell array of cells
end
nOut = 1;
additionalFun = {};
name = ['test_cassandra_' runName];
time = 1; % hr
proc = 1;
mem = 4; % GB
jvm = true;

submitCluster(cluster, fun, inputs, nOut, additionalFun, name, time, proc, mem, jvm);