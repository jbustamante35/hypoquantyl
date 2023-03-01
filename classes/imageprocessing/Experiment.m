%% Experiment: class for image stacks stored as separate Genotype objects
% Class description
%
% Usage:
%   ex = Experiment(varargin)
%
% Input:
%   edir: path to sub-directories of time-lapse images
%   varargin: various inputs [see below]
%       
%
% Output:
%   ex: Experiment object
%
% Example:
%   enm  = 'experiment_name';
%   edir = '/home/user/path/to/subdirectores/';
%   ex   = Experiment('ExperimentName', enm, 'ExperimentPath', edir)
%

classdef Experiment < handle
    properties (Access = public)
        %% Experiment properties
        ExperimentName
        ExperimentPath
        Genotypes
        NumberOfGenotypes
        GenotypeSets
        CurvesTraced
    end

    properties (Access = private)
        %% Private data properties
        ExperimentDate  = tdate('l')
        HYPOCOTYLLENGTH = 250   % Distance to set cutoff for upper hypocotyl
        SEEDLINGSIZE    = [5000 , 50000] % Cut-off pixel area for a Seedling
    end

    %% ------------------------- Primary Methods --------------------------- %%
    methods (Access = public)
        %% Constructor and main methods
        function obj = Experiment(varargin)
            %% Constructor method for Experiment
            if ~isempty(varargin)
                % Parse inputs to set properties
                vargs = varargin;
            else
                % Set default properties for empty object
                vargs = {};
            end

            prps   = properties(class(obj));
            deflts = { ...
                'ExperimentPath'   , pwd   ; ...
                'NumberOfGenotypes', 0   } ;
            obj    = classInputParser(obj, prps, deflts, vargs);

            [obj.ExperimentName, ~] = getDirName(obj.ExperimentPath);
        end

        function AddGenotypes(obj, ext)
            %% Add Genotype to Experiment
            if nargin < 2; ext = '.TIF'; end

            % Get all directories (exclude . and ..)
            fld   = dir(obj.ExperimentPath);
            fld   = fld(3:end);
            fldrs = fld(cat(1, fld.isdir));

            %% Create Genotype child objects
            if isempty(obj.Genotypes); obj.Genotypes = Genotype; end

            try
                G = arrayfun(@(f) initializeGenotype(f.name, 'Parent', obj, ...
                    'image_extension', ext), fldrs, 'UniformOutput', 0);
                G = cat(1, G{:});

                obj.Genotypes         = G;
                obj.NumberOfGenotypes = numel(G);
            catch
                fprintf(2, '\nError adding Genotype %d\n', ...
                    obj.NumberOfGenotypes);
            end
        end

        function FindSeedlingAllGenotypes(obj, v, mth)
            %% Extract Seedling from every frame of each Genotype
            if nargin < 2; v   = 0;     end % Verbosity
            if nargin < 3; mth = 'new'; end % Old method or with collision detection

            try
                if v
                    t = tic;
                    [~ , sprA , sprB] = jprintf(' ', 0, 0, 80);
                    fprintf('\n%s\nExtracting Seedlings from Experiment %s [%d Genotypes]\n%s', ...
                        sprA, obj.ExperimentName, obj.NumberOfGenotypes, sprA);
                end

                % Find and Sort Seedlings
                G      = obj.combineGenotypes(1);
                sdlsz  = obj.SEEDLINGSIZE;
                hypLen = obj.HYPOCOTYLLENGTH;

                % Set RawSeedlings to empty cell array
                frms = cellfun(@(g) (1 : g.TotalImages)', ...
                    G, 'UniformOutput', 0);
                rs   = cellfun(@(g,f) cell(numel(f),1), ...
                    G, frms, 'UniformOutput', 0);
                cellfun(@(g,f,r) g.setRawSeedlings(f,1,r), ...
                    G, frms, rs, 'UniformOutput', 0);

                cellfun(@(g) g.FindSeedlings( ...
                    1 : g.TotalImages, sdlsz, hypLen, v), G, 'UniformOutput', 0);

                % Filter and Sort
                cellfun(@(x) x.SortSeedlings(v, mth), G, 'UniformOutput', 0);

                if v
                    nsdls = numel(obj.combineSeedlings);
                    fprintf('\n%s\nExtracted %d Seedlings from %s [%.02f sec]\n%s\n', ...
                        sprB, nsdls, obj.ExperimentName, toc(t), sprA);
                end
            catch e
                %% Error
                fprintf(2, 'Error extracting Seedlings from %s\n%s', ...
                    obj.ExperimentName, e.getReport);

                if v; fprintf(2, '[%.02f sec]\n', toc(t)); end
            end
        end

        function FindHypocotylAllGenotypes(obj, v)
            %% Extract Hypocotyl from every frame of each Seedling from
            % all Genotypes from this Experiment object
            if nargin < 2; v = 0; end % Verbosity

            try
                if v
                    t = tic;
                    [~ , sprA , sprB] = jprintf(' ', 0, 0, 80);
                    fprintf('\n%s\nExtracting Hypocotyls from %s [%d Genotypes]\n%s', ...
                        sprA, obj.ExperimentName, obj.NumberOfGenotypes, sprB);
                end

                gens = obj.Genotypes;
                arrayfun(@(x) x.FindHypocotylAllSeedlings(v), ...
                    gens, 'UniformOutput', 0);

                if v
                    nhyp = numel(obj.combineHypocotyls);
                    fprintf('\n%s\nFinished extracting %d hypocotyls from %s [%.02f sec]\n%s\n', ...
                        sprB, nhyp, obj.ExperimentName, toc(t), sprA);
                end
            catch
                [~ , sprA , sprB] = jprintf(' ', 0, 0, 80);
                fprintf(2, '\n%s\nError extracting Hypocotyls from %s ', ...
                    sprB, obj.ExperimentName);

                if v; fprintf('[%.02f sec]\n%s\n', toc(t), sprA); end
            end
        end

        function SaveExperiment(obj)
            %% Prune superfluous data, dereference parents, then save
            % Remove RawSeedlings and PreHypocotyls
            tPrune = tic;
            g      = obj.combineGenotypes;
            arrayfun(@(x) x.PruneSeedlings, g, 'UniformOutput', 0);
            fprintf('[%.02f sec] Pruned %d Genotypes\n', toc(tPrune), numel(g));

            tPrune = tic;
            s      = obj.combineSeedlings;
            arrayfun(@(x) x.PruneHypocotyls, s, 'UniformOutput', 0);
            fprintf('[%.02f sec] Pruned %d Seedlings\n', toc(tPrune), numel(s));

            % Save full Experiment object
            tSave = tic;
            nm = sprintf('%s_%s_%dGenotypes', ...
                tdate, obj.ExperimentName, obj.NumberOfGenotypes);
            ex = obj;
            save(nm, '-v7.3', 'ex');
            fprintf('[%.02f sec] Saved dataset %s\n', toc(tSave), nm);
        end

        function LoadExperiment(obj)
            %% Recursively set references back to Child objects
            g = obj.combineGenotypes;
            arrayfun(@(x) x.setParent(obj), g, 'UniformOutput', 0);

            s = obj.combineSeedlings;
            h = obj.combineHypocotyls;

            X = {g, s, h};
            ref = @(c) arrayfun(@(x) x.RefChild, c, 'UniformOutput', 0);
            cellfun(@(x) ref(x), X, 'UniformOutput', 0);
        end

        function ChangeBasePath(obj, p)
            %% Change base path to data
            % I'm an idiot and changed the directory to the base data, and it
            % messed up the entire dataset. This should allow flexibility in
            % the path to data.
            try
                % Set this object's new name and path
                obj.ExperimentPath = char(p);
                obj.ExperimentName = getDirName(p);

                % Iterate through each Genotype's ImageDataStore
                arrayfun(@(x) x.ChangeStorePaths(p), ...
                    obj.Genotypes, 'UniformOutput', 0);

            catch e
                fprintf(2, 'Error setting new path\n%s\n', e.message);
            end
        end

        function IMGS = PrepareHypocotylImages(obj, RESCALE)
            %% Prepare hypocotyl images for CNN
            if nargin < 2; RESCALE = 1; end % Rescale hypocotyl image size

            CRVS = obj.combineContours;

            % Resize hypocotyl images to isz x isz
            isz      = ceil(size(CRVS(1).getImage('gray')) * RESCALE);
            imgs_raw = arrayfun(@(x) x.getImage('gray'), CRVS, 'UniformOutput', 0);
            imgs_rsz = cellfun(@(x) imresize(x, isz), imgs_raw, 'UniformOutput', 0);
            imgs     = cat(3, imgs_rsz{:});
            imSize   = size(imgs);

            % Reshape image data as X values and use Midpoint PCA scores as Y values
            IMGS = double(reshape(imgs, [imSize(1:2), 1, imSize(3)]));
        end
    end

    %% ------------------------- Helper Methods ---------------------------- %%
    methods (Access = public)
        %% Various helper methods for other classes to use
        function g = getGenotype(obj, idx)
            %% Returns genotype at desired index
            try
                if nargin < 2; idx = ':'; end
                g = obj.Genotypes(idx);
            catch e
                fprintf(2, 'No Genotype at index %d\n', idx);
                fprintf(2, '%s \n', e.message);
            end
        end

        function G = combineGenotypes(obj, asCell)
            %% Combine all Genotypes into single object array
            if nargin < 2; asCell = 0; end % Default output as array

            if asCell
                G = arrayfun(@(x) obj.getGenotype(x), ...
                    (1 : obj.NumberOfGenotypes)', 'UniformOutput', 0);
            else
                G = obj.getGenotype;
            end
        end

        function [g, i] = search4Genotype(obj, nm)
            %% Return specific Genotype by GenotypeName
            gts  = obj.getGenotype;
            gnms = arrayfun(@(x) x.GenotypeName, gts, 'UniformOutput', 0)';
            mtc  = strmatch(nm, gnms, 'exact');
            if ~isempty(mtc)
                g = gts(mtc);
                i = mtc;
            else
                g = [];
                i = [];
            end
            
%             for i = 1 : numel(gts)
%                 mtc = gnms{i};                
%                 if isequal(nm, mtc)
%                     g = gts(i);
%                     return;
%                 end
%             end
        end

        function S = combineSeedlings(obj, asCell, getGood)
            %% Combine all Seedlings into single object array
            if nargin < 2; asCell  = 0; end % Output as array (0) or cell (1)
            if nargin < 3; getGood = 0; end

            G = obj.combineGenotypes(asCell);
            if asCell
                % Split into cell array by Genotype
                S = cellfun(@(x) x.getSeedling(':', getGood), ...
                    G, 'UniformOutput', 0);
            else
                % Combine as one array
                S = arrayfun(@(x) x.getSeedling(':', getGood), ...
                    G, 'UniformOutput', 0);
                S = cat(1, S{:});
            end
        end

        function H = combineHypocotyls(obj, req, asCell)
            %% Combine all Hypocotyls into single object array
            % CHANGE THIS WHEN I FIX HOW HYPOCOTYLS ARE STORED IN SEEDLINGS
            % Each Seedling will have a single Hypocotyl, derived from data
            % from the combination of good frames of each PreHypocotyl.
            if nargin < 2; req    = 'post'; end % Pre or Post sorting
            if nargin < 3; asCell = 0;      end % Array or Cell array

            S = obj.combineSeedlings(0);
            try
                switch req
                    case 'pre'
                        H = arrayfun(@(x) x.getAllPreHypocotyls, ...
                            S, 'UniformOutput', 0);
                        H = cat(2, H{:});
                    case 'post'
                        H = arrayfun(@(x) x.MyHypocotyl, S);
                    otherwise
                        H = arrayfun(@(x) x.MyHypocotyl, S);
                end
            catch
                fprintf(2, 'Error extracting Hypocotyls\n');
                H = [];
                return;
            end

            if asCell; H = arrayfun(@(x) x, H, 'UniformOutput', 0); end
        end

        function [D, org, flp] = combineContours(obj, getCrvs, ver)
            %% Return all Hypocotyls with manually-drawn CircuitJB objects
            % Returns both original and flipped versions of each. I'm not sure
            % if it would work if some don't have flipped versions.
            if nargin < 2; getCrvs = 1;      end
            if nargin < 3; ver     = 'Full'; end

            H   = obj.combineHypocotyls;
            org = arrayfun(@(x) arrayfun(@(y) x.getCircuit(y, 'org', ver),  ...
                1:x.Lifetime, 'UniformOutput', 0), H, 'UniformOutput', 0);
            org = cat(2, org{:});
            org = cat(1, org{:});

            flp = arrayfun(@(x) arrayfun(@(y) x.getCircuit(y, 'flp', ver),  ...
                1:x.Lifetime, 'UniformOutput', 0), H, 'UniformOutput', 0);
            flp = cat(2, flp{:});
            flp = cat(1, flp{:});

            D = [org ; flp];

            obj.CurvesTraced = numel(D);

            % Return Curves only
            if getCrvs
                D  = arrayfun(@(x) x.Curves, D, 'UniformOutput', 0);
                D  = cat(1, D{:});
            end
        end

        function [noflp , hyp] = findMissingContours(obj)
            %% Find missing contours (accidentally cancelled when training)
            D = obj.combineContours;
%             C = obj.combineContours;
%             D = arrayfun(@(x) x.Curves, C, 'UniformOutput', 0);
%             D = cat(1, D{:});
            if mod(numel(D),2)
                nms   = arrayfun(@(x) x.Parent.Origin, D, 'UniformOutput', 0);
                hlfSz = ceil(length(nms) / 2);
                org   = nms(1       : hlfSz);
                flp   = nms(hlfSz+1 : end);
                flp{end+1} = '';
                flps  = cellfun(@(x) x(6:end), flp, 'UniformOutput', 0);
                mems  = cellfun(@(x) ismember(x, flps), org, 'UniformOutput', 0);
                mems  = cat(1, mems{:});
            else
                mems = [];
            end

            noflp = org{~mems};
            noflp = noflp{1};

            % Search for and Return Hypocotyl with missing contour
            [~, exIdx] = regexp(noflp, [ex.ExperimentName , '_']);
            sdIdx = regexp(noflp, '_Seedling');
            gname = noflp(exIdx+1 : sdIdx-1);
            gen   = ex.search4Genotype(gname);
            aa    = strfind(noflp, '{');
            bb    = strfind(noflp, '}');
            hyIdx = str2double(noflp(aa + 1 : bb - 1));
            sdl   = gen.getSeedling(hyIdx);
            hyp   = sdl.MyHypocotyl;
        end

        function P = combineParameters(obj)
            %% Return all Ppar (theta, dX, dY) from CircuitJB Routes
            C = obj.combineContours;
            P = arrayfun(@(x) x.ParameterRoutes, C, 'UniformOutput', 0);
            P = cat(3, P{:});
            P = permute(P, [3 2 1]);
        end

        function check_outOfFrame(obj, frm, s)
            %% Check if Seedling grows out of frame
            %
            % obj: this Experiment
            % frm: frame of time-lapse
            % s  : Seedling to check
        end

        function setProperty(obj, req, val)
            %% Returns a property of this Genotype object
            try
                obj.(req) = val;
            catch e
                fprintf(2, 'Property %s does not exist\n%s\n', ...
                    req, e.message);
            end
        end

        function prp = getProperty(obj, req)
            %% Return a property from this object
            try
                prp = obj.(req);
            catch
                fprintf(2, 'Error retrieving %s property\n', req);
                prp = [];
            end
        end
    end

    %% ------------------------- Private Methods --------------------------- %%
    methods (Access = private)
        %% Private helper methods for this class
    end
end
