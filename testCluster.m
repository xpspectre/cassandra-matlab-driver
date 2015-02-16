function testCluster
% Test script for cluster

runName = 'test1';
nCores = 1;

fun = 'testSession';
inputs = cell(1, nCores);
for i = 1:nCores
    inputs{i} = i;
end
nOut = 1;
additionalFun = {};
name = ['test_cassandra_' runName];
time = 1; % hr
proc = 1;
mem = 8; % GB, allocate 4 GB extra if using JVM
jvm = true;

submitthor(fun, inputs, nOut, additionalFun, name, time, proc, mem, jvm);
