function setup
% Setup MATLAB Cassandra driver
%clear; close all; clc

driverPath = fileparts(mfilename('fullpath'));

% System call to compile driver classes
%system('javac -classpath cassandra-java-driver-2.0.2/cassandra-driver-core-2.0.2.jar:. MatlabDriverJava.java')

% Add Matlab driver object to Matlab path
addpath(driverPath);

% Add driver jars in current directory to classpath
javaaddpath(driverPath);

% Add library jars to classpath
mainJarsListing = dir('cassandra-java-driver-2.0.2/*.jar');
mainJarsListing = {mainJarsListing.name};
for i = 1:length(mainJarsListing)
    mainJarsListing{i} = [driverPath, '/cassandra-java-driver-2.0.2/', mainJarsListing{i}];
end
javaaddpath(mainJarsListing)

libJarsListing = dir('cassandra-java-driver-2.0.2/lib/*.jar');
libJarsListing = {libJarsListing.name};
for i = 1:length(libJarsListing)
    libJarsListing{i} = [driverPath, '/cassandra-java-driver-2.0.2/lib/', libJarsListing{i}];
end
javaaddpath(libJarsListing)

disp('Matlab Cassandra driver')