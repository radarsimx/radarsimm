% ----------
% RadarSimM - Radar Simulator for MATLAB
% Copyright (C) 2023 - PRESENT  RadarSimX LLC
% E-mail: info@radarsimx.com
% Website: https://radarsimx.com
%
% ██████╗  █████╗ ██████╗  █████╗ ██████╗ ███████╗██╗███╗   ███╗██╗  ██╗
% ██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔════╝██║████╗ ████║╚██╗██╔╝
% ██████╔╝███████║██║  ██║███████║██████╔╝███████╗██║██╔████╔██║ ╚███╔╝
% ██╔══██╗██╔══██║██║  ██║██╔══██║██╔══██╗╚════██║██║██║╚██╔╝██║ ██╔██╗
% ██║  ██║██║  ██║██████╔╝██║  ██║██║  ██║███████║██║██║ ╚═╝ ██║██╔╝ ██╗
% ╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝╚═╝     ╚═╝╚═╝  ╚═╝


classdef CodeAnalyzerTest < matlab.unittest.TestCase
    % CodeAnalyzerTest Static checks over every MATLAB file in the project.
    %
    % The example scripts need the radarsimc shared library to run, so CI
    % cannot execute them. Parsing them with the MATLAB Code Analyzer still
    % catches syntax errors before they reach a release.

    methods (Test)

        function everyFileParses(testCase)
            files = testCase.projectFiles();
            testCase.assertNotEmpty(files, 'No MATLAB files were found.');

            problems = {};
            for k = 1:numel(files)
                messages = checkcode(files{k}, '-struct');
                for m = 1:numel(messages)
                    if CodeAnalyzerTest.isSyntaxError(messages(m))
                        problems{end+1} = sprintf('%s (line %d): %s', ...
                            files{k}, messages(m).line, messages(m).message); %#ok<AGROW>
                    end
                end
            end

            testCase.verifyEmpty(problems, ...
                sprintf('Syntax errors reported by the Code Analyzer:\n%s', ...
                strjoin(problems, newline)));
        end

        function everyPackageClassIsNamedAfterItsFile(testCase)
            package_dir = fullfile(testCase.repoRoot(), 'src', '+RadarSim');
            listing = dir(fullfile(package_dir, '*.m'));

            testCase.assertNotEmpty(listing, ...
                'No class files were found in src/+RadarSim.');

            for k = 1:numel(listing)
                [~, name] = fileparts(listing(k).name);
                mc = meta.class.fromName(['RadarSim.', name]);
                testCase.verifyNotEmpty(mc, sprintf( ...
                    'src/+RadarSim/%s does not define class RadarSim.%s.', ...
                    listing(k).name, name));
            end
        end

        function noFileUsesTabsForIndentation(testCase)
            % The project is indented with spaces; tabs render differently
            % in the published documentation.
            files = testCase.projectFiles();

            offenders = {};
            for k = 1:numel(files)
                if contains(fileread(files{k}), sprintf('\t'))
                    offenders{end+1} = files{k}; %#ok<AGROW>
                end
            end

            testCase.verifyEmpty(offenders, ...
                sprintf('Files containing tab characters:\n%s', ...
                strjoin(offenders, newline)));
        end

    end

    methods (Access = private)

        % Walks up from this file until it finds the folder holding the
        % RadarSim package, so the tests do not depend on how deeply they
        % are nested under tests/.
        function root = repoRoot(testCase)
            root = fileparts(mfilename('fullpath'));
            while ~isfolder(fullfile(root, 'src', '+RadarSim'))
                parent = fileparts(root);
                testCase.assertNotEqual(parent, root, ...
                    'Could not locate the repository root from the test file.');
                root = parent;
            end
        end

        % Collects every MATLAB file that ships with the project.
        function files = projectFiles(testCase)
            root = testCase.repoRoot();

            folders = {root, fullfile(root, 'src'), ...
                fullfile(root, 'src', '+RadarSim'), ...
                fullfile(root, 'tests', 'unit'), ...
                fullfile(root, 'tests', 'integration')};

            files = {};
            for k = 1:numel(folders)
                listing = dir(fullfile(folders{k}, '*.m'));
                for m = 1:numel(listing)
                    files{end+1} = fullfile(listing(m).folder, listing(m).name); %#ok<AGROW>
                end
            end
        end

    end

    methods (Static, Access = private)

        % Decides whether a Code Analyzer message reports a parse error
        % rather than a style warning. Releases differ in what checkcode
        % returns, so both the severity field (when present) and the
        % message text are inspected.
        function tf = isSyntaxError(message)
            tf = false;

            if isfield(message, 'severity')
                severity = message.severity;
                if (ischar(severity) || isstring(severity)) && ...
                        strcmpi(string(severity), "error")
                    tf = true;
                    return
                end
            end

            text = string(message.message);
            patterns = ["Parse error", "Invalid syntax", "Invalid use of", ...
                "Unbalanced or unexpected", "might be missing"];
            tf = any(contains(text, patterns, 'IgnoreCase', true));
        end

    end
end
