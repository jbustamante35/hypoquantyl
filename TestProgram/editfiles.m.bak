function editfiles(pc, project)
% editfiles: Opens all .m files for editing desired project

switch pc
    case 'wr' 
    % Winry-Rockbell Linux
        pth = '/home/jbustamante/Dropbox/';
        
    case 'wp'
    % Winry-Rockbell Windows
        pth = 'C:\Users\Julian Bustamante\Dropbox\';
        
    case 'rd'
    % Edgar Lab Remote Desktop
        pth = '/home/jbustamante/';
        
    case 'rt'
    % Rin-Tohsaka Linux
        pth = '/home/yan-yan11/Dropbox/';
        
    case 'mc'
    % Unnamed MacOSX
        pth = '';
        
    otherwise
        fprintf(2, 'Devices not found\n');
        return;
end

switch project
    case 'qd'
    % QuantDRaCALA_v2
        prjDir = 'EdSpalding_Lab/Software/QD2/QuantDRaCALA_v2/';
        
    case 'sz'
    % Sphinctolyzer
        prjDir = 'KevinBill_Lab/Sphinctalyzer/sphinctolyzer/';
        
    case 'hq'
    % HypoQuantyl
        prjDir = 'EdSpalding_Lab/Software/HypoQuantyl';
        
    case 'rd'
    % Edgar Lab Remote Desktop: just get into HypoQuantyl
        prjDir = 'Software/HypoQuantyl';
    
    otherwise
        fprintf(2, 'Project not found\n');
        return;
end

fullDir = [pth prjDir];
currDir = pwd;

%% Initial Run
cd(fullDir);
d = runProgram(fullDir);
s = cellfun(@(x) go2Dir(x), d.path, 'UniformOutput', 0);

%% Recursive Runs 
% j = 1;
% while ~isempty(s)
%     m = cellfun(@(x) go2Dir(x), s{j}.path, 'UniformOutput', 0);
%     
%     j = j + 1;
% end


cd(currDir);

end

function d = runProgram(din)
    cd(din);
    a      = dir('*');
    [d, f] = sortFiles(a);
    cellfun(@(x) openAllFiles(x), f.name, 'UniformOutput', 0);    
end

function [dirs, fils] = sortFiles(ain)
    ain(1:2) = [];
    dIdx = cat(1, ain.isdir) == 1;
    dirs = ain(dIdx);
    fils = ain(~dIdx);
    
    try
        dirs = struct2table(dirs);
        fils = struct2table(fils);
        if isunix
            dirs.path = strcat(dirs.folder, '/', dirs.name);
        else
            dirs.path = strcat(dirs.folder, '\', dirs.name);
        end        
    catch e
        fprintf(2, 'Directory empty(@sortFiles): %s \n', ain);
        return;
    end
end

function openAllFiles(fin)
    idx = strfind(fin, '.');
    ext = fin(idx+1 : end);

    if ext == 'm'
        open(fin);
    end
end

function subd = go2Dir(din)        
    try
        subd = runProgram(din);
    catch e
        fprintf(2, 'Directory empty(@go2Dir): %s \n', din);
        subd = [];
        return;
    end
end
