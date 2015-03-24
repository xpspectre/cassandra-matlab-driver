function setup
% Setup MATLAB Cassandra driver

% Get full path to this file
driverPath = fileparts(mfilename('fullpath'));

% Add Matlab driver object and supporting sources to Matlab path
addpath(driverPath);
addpath([driverPath, '/Source']);

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

% Add driver path to environment variables
setenv('CASSANDRA_MATLAB_DRIVER_PATH', driverPath)

disp('Matlab Cassandra driver')