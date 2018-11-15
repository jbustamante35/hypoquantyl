function main = class_hierarchy_test(nChildren, nSubs, sv)
%% class_hierarchy_test: tests to assess Parent-Child object hierarchy
% I am trying to implement a class organization for HypoQuantyl that uses a
% Parent-Child structure in which each object has a property that references 
% it's own Parent object and Child array. But for some reason, saving these
% structures creates massive data files (in .mat format) that make it 
% inefficient with disk space. 
%
% This neat script creates a simplified version of the Parent-Child heiarchy
% where I can adjust the number of objects saved in the outputted .mat file and
% assess how much disk space they take up.  
%
% Usage:
%   main = class_heiarchy_test(nChildren, nSubs, sv)
%
% Input:
%   nChildren: number of Child objects to create in the Main object
%   nSubs: number of Subchild objects to create in each Child object
%   sv: boolean to not save (0) or save (1) data in .mat format
%
% Output:
%   main: structure array containing results of each test
%
% Examples:
% This script iteratively creates class structures, where the runTest() function
% is called once per Child and Subchild value. So a value of nChildren = 3 and
% nSubs = 1 will actually run the test with nChildren = 1, nChildren = 2, and 
% nChildren = 3 times, keeping nSubs = 1 constant. (see below for examples)
% 
% Runs test that creates 1 Main, 1 Child, and 1 Subchild objects
%   M = class_heiarchy_test(1, 1, 1); 
%
% Runs test that creates 10 Main, 10 Child, and 100 Subchild objects
%   M = class_heiarchy_test(1, 1, 10); 
%
% Runs test that creates 10 Main, 100 Child, and 100 Subchild objects
%   M = class_heiarchy_test(1, 10, 1);
%
% Runs test that creates 100 Main, 100 Child, and 1000 Subchild objects
%   M = class_heiarchy_test(1, 10, 10);
%

%% Set up number of tests
if numel(nChildren) > 1
    child_range = nChildren;
else
    child_range = 1 : nChildren;    
end

if numel(nSubs) > 1
    subs_range = nSubs;    
else
    subs_range  = 1 : nSubs;
end
numtests = numel(child_range) * numel(subs_range);

%% Run test iteratively through Children and Grandchildren
t = 1;
for child = child_range
    for sub = subs_range
        main_name = sprintf('Head%d', t);
        main(t)   = runTest(main_name, child, sub);        
        
        %% Save multiple .mat files in new directory
        if sv
            currDir = pwd;
            dataDir = sprintf('classtest%d_%dChildren_%dGrandchildren', ...
                numtests, numel(child_range), numel(subs_range));
            
            if ~exist(dataDir, 'dir')
                mkdir(dataDir);
            end            
            cd(dataDir);
            
            var = main(t);
            nm  = sprintf('Test%d_%dChildren_%dGrandchildren', ...
                t, var.m.m.TotalChildren, var.m.m.TotalGrandchildren);
            save(nm, '-v7.3', 'var');
            cd(currDir);
            
            fprintf('Directory: %s | Filename: %s\n\n', dataDir, nm);
        end
        
        t = t + 1;
    end
end

fprintf('Full Size: %.06f Mb\n', calculateSize(main, 'main'));
if sv
    nmfinal = sprintf('Final_%dTests_%dChildren_%dGrandchildren', ...
        numtests, numel(child_range), numel(subs_range));
    save(nmfinal, '-v7.3', 'main');
end

end


function M = runTest(nMain, nChildren, nSubs)
%% Create Main object with Children and Grandchildren objects
m = Main(nMain);

for i = 1 : nChildren
    c(i) = Child(sprintf('Body%d', i));
    for ii = 1 : nSubs
        s(i,ii) = Subchild(sprintf('Legs%d-%d', i, ii));
        c(i).AddSub(s(i,ii));
    end
    m.AddChild(c(i));
end

%% Save Main object in structure containing objects and size of each object
M.m.m = m;
M.c.c = m.getChildren;
M.s.s = m.getGrandchildren;

try
    fprintf('%d Children | %d Grandchildren\n', ...
        M.m.m.TotalChildren, M.m.m.TotalGrandchildren);
    M.m.sz = calculateSize(m, 'Main');
    M.c.sz = calculateSize(c, 'Child');
    M.s.sz = calculateSize(s, 'SubChild');
    
    sz = M.m.sz + M.c.sz + M.s.sz;
    fprintf('Total Size: %.06f Mb\n', sz);
catch e
    e.getReport;
end

end

function sz = calculateSize(obj, str)
%% Calculate number of bytes in inputted object
var = whos('obj');
sz  = var.bytes * 9.53674e-7;

fprintf('Size of %s: [ %.06f Mb ]\n', str, sz);
end

