function submitCluster(cluster, fun, inputs, nOut, additionalFun, name, time, proc, mem, jvm)
%submitCluster(cluster, fun, inputs, nOut, additionalFun, name, time, proc, mem, jvm)
% Uses general submit script submit.maui.general
%SUBMITCLUSTER Submit Matlab jobs to Tidor clusters
%
%   submitCluster(cluster, fun, inputs, nOut, additionalFun, name, time, proc, mem, jvm)
%
%   Inputs:
%       cluster - A string containing name of cluster: 'thor' or 'vali'
%       fun - A string containing the name of the function you want to call
%       inputs - A cell vector of cell vectors. Each entry in the uppermost
%                cell array contains the complete set of entries for a
%                single call to the function. Each entry in the
%                second-highest level cell array is one input to the
%                function.
%       nOut   - The number of outputs that the fucntion will be call with
%       additionalFun - A cell vector of strings. Any files that are accessed by their string name,
%                       rather than in the code must named here as their
%                       string name. This includes any files that are
%                       called by load and any files are accessed by
%                       function handles saved in mat files or in any
%                       inputs. Already considers postProcessModel,
%                       symbolic2Kronecker, which are function handles that
%                       can be saved by Kronecker Bio models.
%       name - A string name to give this job. Default = fun
%       time - A scalar numeric telling the expected amount of time this job will take. If the job
%              takes longer than this, it will be killed.
%       proc - A scalar integer indicating the number of processors this
%              job requires. Default = 1
%       mem - A scalar double indicating the amount of RAM in GB. Default 3.75
%             GB/proc.
%       jvm - A boolean specifying whether to use Java-based Cassandra
%             driver. Default = false
%
%   Outputs:
%       The output from each job is saved as a cell vector called out in a
%       file outputi.mat, with i being the index in inputs that was used to
%       generate it. The compiled files and all outputs are saved in the
%       folder: "/data/{username}/{date-time}_name"
%
%   How to specify inputs:
%       Essentially, submitCluster does this for all i:
%       
%       [out{1} ... out{nOut}] = fun(inputs{i}{1}, ..., inputs{i}{end})
%
%       And saves the out matrix in outputi.mat

% (c) 2015 Kevin Shi, David R Hagen, and Bruce Tidor
% This work is released under the MIT license.

% Clean up inputs
if nargin < 10
    jvm = [];
    if nargin < 9
        mem = [];
        if nargin < 8
            proc = [];
            if nargin < 7
                time = [];
                if nargin < 6
                    name = [];
                    if nargin < 5
                        additionalFun = [];
                    end
                end
            end
        end
    end
end

% Make sure cluster is valid
assert(strcmpi(cluster, 'thor') || strcmpi(cluster, 'vali'), 'submitCluster:InvalidCluster', '%s is not a valid cluster', cluster)

% Resolve empty inputs
if isempty(additionalFun)
    additionalFun = {};
elseif ischar(additionalFun)
    additionalFun = {additionalFun};
end
assert(iscell(additionalFun), 'additionalFun is not a cell')

if isempty(name)
    name = fun;
end

if isempty(time)
    error('submitCluster:ExpectedTime', 'You must specify a maximum time.');
end

if isempty(proc)
    proc = 1;
end

if isempty(mem)
    mem = proc*3.75;
end

if isempty(jvm)
    jvm = false;
end

% Check if input is cell array of cells
assert(iscell(inputs), 'input is a not a cell array')
isCellArrayOfCells = true;
for i = 1:numel(inputs)
    if ~iscell(inputs{i})
        isCellArrayOfCells = false;
        break
    end
end

% Standardize additionalFun as a horizontal vector
additionalFun = additionalFun(:)';

% Add common additional functions to additionalFun
if exist('postProcessModel', 'file')
    additionalFun = [additionalFun, {'postProcessModel'}];
end
if exist('symbolic2Kronecker', 'file')
    additionalFun = [additionalFun, {'symbolic2Kronecker'}];
end
if exist('piecewiselinear', 'file')
    additionalFun = [additionalFun, {'piecewiselinear'}];
end
if exist('piecewisestep', 'file')
    additionalFun = [additionalFun, {'piecewisestep'}];
end
if exist('FinalizeModel', 'file')
    additionalFun = [additionalFun, {'FinalizeModel'}];
end
if exist('symbolic2PseudoKronecker', 'file')
    additionalFun = [additionalFun, {'symbolic2PseudoKronecker'}];
end
if exist('Experiment', 'file')
    additionalFun = [additionalFun, {'Experiment'}];
end
if exist('Uzero', 'file')
    additionalFun = [additionalFun, {'Uzero'}];
end
if exist('Gzero', 'file')
    additionalFun = [additionalFun, {'Gzero'}];
end
if exist('nan2zero', 'file')
    additionalFun = [additionalFun, {'nan2zero'}];
end
if exist('inf2big', 'file')
    additionalFun = [additionalFun, {'inf2big'}];
end

% Use general maui submit script
script = '/bt/programs/noarch/bin/submit.maui.general';

% Number processors
if proc > 12
    error('submitCluster:ProcessorNumber', 'Too many processors desired.')
end
script = [script ' -c ' num2str(proc)];

% Amount RAM
script = [script ' -m ' num2str(mem)];

% Max wall time
script = [script ' -t ' num2str(time)];

% Job name
script = [script ' -n ' 'run'];

% Create the target directory: /data/<username>/yyyy.mm.dd-HH.MM_name/
clusterDir = ['/data/' getenv('USER') '/'];
name = [datestr(now, 'yyyy.mm.dd-HH.MM_') name];
mkdir(clusterDir, name)
dir = [clusterDir name '/'];

% Save inputs as separate files
if isCellArrayOfCells
    % We have a lot of inputs to handle
    N = numel(inputs);
    for i = 1:N
        input = inputs{i};
        save([dir 'input' num2str(i) '.mat'], 'input')
    end
else
    % There is only one input
    N = 1;
    input = inputs;
    save([dir 'input1.mat'], 'input')
end

% Write submitfile
fid = fopen([dir 'submitfile.m'], 'w');
fprintf(fid, 'function submitfile(iTask)\n');
fprintf(fid, 'load([''./input'' iTask ''.mat''])\n');
fprintf(fid, ['[out{1:' num2str(nOut) '}] = ' fun '(input{:});\n']);
fprintf(fid, 'save([''./output'' iTask ''.mat''], ''out'')\n');
fprintf(fid, 'end\n');
fclose(fid);

% Add -a option to the front of all additional functions
additionalFun = additionalFun(:).';
additionalFun = [cell(size(additionalFun)); additionalFun];
additionalFun(1,1:end) = deal({'-a'});

% Compile submitfile
%   Distinguish between JVM-required and excluded usage
fprintf('Compiling...\n')
if jvm
    mcc('-R', '-nosplash', '-R', '-nodisplay', '-R', '-singleCompThread', ...
        '-a', 'cassandra-java-driver-2.0.2/cassandra-driver-core-2.0.2.jar', ...
        '-a', 'cassandra-java-driver-2.0.2/cassandra-driver-dse-2.0.2.jar', ...
        '-a', 'cassandra-java-driver-2.0.2/lib/*', ...
        '-m', [dir 'submitfile.m'], '-d', dir, additionalFun{:})
else
    mcc('-R', '-nosplash', '-R', '-nodisplay', '-R', '-singleCompThread', ...
        '-R','-nojvm', '-m', [dir 'submitfile.m'], '-d', dir, additionalFun{:})
end
fprintf('done.\n')

%Modify MCR_CACHR_ROOT to point locally on machine
fid = fopen([dir 'run_submitfile.sh'], 'r'); % Open file
file = fscanf(fid, '%c'); % Extract contents
fclose(fid);
fid = fopen([dir 'run_submitfile.sh'], 'w'); % Open and erase file
matchline = '  echo LD_LIBRARY_PATH is \${LD_LIBRARY_PATH};\n'; % The line after which the MCR_CACHE_ROOT will be set
addline = '  mcr_root=/tmp/\${USER}\$\$/ ;\n  MCR_CACHE_ROOT=$mcr_root ;\n  export MCR_CACHE_ROOT;\n  trap ''rm -rf "$mcr_root"'' EXIT ;\n';
file = regexprep(file, matchline, [matchline addline]);
fwrite(fid, file);
fclose(fid);

% Parse matlab version to get appropriate directory
versionMatch = regexp(version, '\(R\d+.*\)', 'match');
versionMatch = versionMatch{1}(3:end-1);
matlabDir = ['/programs/x86_64/lib/matlab' versionMatch '/'];

% Call ssh script
jobNames = cell(1,N);
for i = 1:N
    status = 'N'; % Catch if qsub errors out with "No permission..." or "Error communicating..." and try again
    while strcmp(status(1), 'N') || strcmp(status(1), 'E')
        [result status] = system(['ssh ' cluster ' "cd ' dir ' && ' script ' -r "' dir 'run_submitfile.sh ' matlabDir ' ' num2str(i) '""']);
        fprintf(status)
    end
    jobNames{i} = regexp(status, ['\d{1,}\.' cluster], 'match', 'once');
end
fprintf('Submitted %d jobs.\n', N)

% Save job names in a file
jobNames = [jobNames; cell(1,N)];
jobNames(2,1:end) = deal({'\n'}); % a new line to the end
fid = fopen([dir 'jobnames.txt'], 'w');
fprintf(fid, strcat(jobNames{:}));
fclose(fid);

% Script for killing all the jobs
fid = fopen([dir 'qkill.all.here'], 'w');
fprintf(fid, '#!/usr/bin/perl -w\n\n');
fprintf(fid, 'open("jobnames", "jobnames.txt");\n');
fprintf(fid, '@list = <jobnames>;\n');
fprintf(fid, 'close("jobnames");\n');
fprintf(fid, 'for ($i=0; $i<=$#list; $i++) {\n');
fprintf(fid, '    $line = $list[$i];\n');
fprintf(fid, '    system("ssh %s qdel $line");\n', cluster);
fprintf(fid, '}\n');
fclose(fid);

system(['chmod 744 "' dir 'qkill.all.here"']);

% Script for resubmitting lost jobs
fid = fopen([dir 'resubmit.' cluster '.here'], 'w');
fprintf(fid, '#!/bin/bash\n');
fprintf(fid, '\n');
fprintf(fid, '# Get the names of the current jobs\n');
fprintf(fid, 'i=0\n');
fprintf(fid, 'while read line\n');
fprintf(fid, 'do\n');
fprintf(fid, '    (( i++ ))\n');
fprintf(fid, '    jobnames[$i]=$line\n');
fprintf(fid, 'done < jobnames.txt\n');
fprintf(fid, '\n');
fprintf(fid, 'N=$i # Number of jobs\n');
fprintf(fid, '\n');
fprintf(fid, '# See what jobs are queued\n');
fprintf(fid, 'queueout=`qsum-%s.pl -J`\n', cluster);
fprintf(fid, '\n');
fprintf(fid, 'for i in $(seq 1 1 $N)\n');
fprintf(fid, 'do\n');
fprintf(fid, '    if [[ $queueout =~ ${jobnames[$i]} ]]\n');
fprintf(fid, '    then\n');
fprintf(fid, '        queued[$i]=1\n');
fprintf(fid, '    else\n');
fprintf(fid, '        queued[$i]=0\n');
fprintf(fid, '    fi\n');
fprintf(fid, 'done\n');
fprintf(fid, '\n');
fprintf(fid, '# See what jobs have finished\n');
fprintf(fid, 'for i in $(seq 1 1 $N)\n');
fprintf(fid, 'do\n');
fprintf(fid, '    if [ -e "output${i}.mat" ]\n');
fprintf(fid, '    then\n');
fprintf(fid, '        finished[$i]=1\n');
fprintf(fid, '    else\n');
fprintf(fid, '        finished[$i]=0\n');
fprintf(fid, '    fi\n');
fprintf(fid, 'done\n\n');
fprintf(fid, '\n');
fprintf(fid, '# Resubmit jobs that are neither queued nor are finished\n');
fprintf(fid, 'for i in $(seq 1 1 $N)\n');
fprintf(fid, 'do\n');
fprintf(fid, '    if [ ${queued[$i]} -ne 1 ] && [ ${finished[$i]} -ne 1 ] || [ -z ${jobnames[$i]} ]\n');
fprintf(fid, '    then\n');
fprintf(fid, ['        commandstring="ssh ' cluster ' cd ${PWD} && ' script ' ${PWD}/run_submitfile.sh ' matlabDir ' $i"\n']);
fprintf(fid, '        output=`$commandstring`\n');
fprintf(fid, '        jobnames[$i]=`echo $output | tr -d ''\\n''`\n');
fprintf(fid, '        echo $output\n');
fprintf(fid, '    fi\n');
fprintf(fid, 'done\n');
fprintf(fid, '\n');
fprintf(fid, '# Update jobnames.txt\n');
fprintf(fid, 'for i in $(seq 1 1 $N)\n');
fprintf(fid, 'do\n');
fprintf(fid, '    echo ${jobnames[$i]}\n');
fprintf(fid, 'done > jobnames.txt\n');
fprintf(fid, '\n');
fprintf(fid, 'exit 0\n');
fclose(fid);

system(['chmod 744 "' dir 'resubmit.' cluster '.here"']);

end
