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


function results = run_tests(suite)
    % run_tests Runs the RadarSimM test suite.
    %
    % Parameters:
    %   suite (char): Which tests to run (default: 'all').
    %     'unit'        - tests/unit. Runs without the compiled backend;
    %                     the classes that need radarsimc skip their
    %                     tests when it is not staged.
    %     'integration' - tests/integration, needs radarsimc and
    %                     radarsim.h in src/+RadarSim.
    %     'all'         - both.
    %
    % Examples:
    %   results = run_tests();
    %   results = run_tests('unit');
    %
    % The function errors if any test fails, which makes it usable as a
    % batch entry point:
    %   matlab -batch "run_tests"
    %   matlab -batch "run_tests('unit')"

    arguments
        suite {mustBeMember(suite, {'all', 'unit', 'integration'})} = 'all'
    end

    repo_root = fileparts(mfilename('fullpath'));

    original_path = path();
    cleanup = onCleanup(@() path(original_path)); %#ok<NASGU>
    addpath(fullfile(repo_root, 'src'));

    switch suite
        case 'unit'
            folders = {fullfile(repo_root, 'tests', 'unit')};
        case 'integration'
            folders = {fullfile(repo_root, 'tests', 'integration')};
        otherwise
            folders = {fullfile(repo_root, 'tests', 'unit'), ...
                fullfile(repo_root, 'tests', 'integration')};
    end

    results = matlab.unittest.TestResult.empty(1, 0);
    for k = 1:numel(folders)
        results = [results, runtests(folders{k})]; %#ok<AGROW>
    end
    disp(results);

    failed = sum([results.Failed]);
    if failed > 0
        error('RadarSim:Tests:Failed', '%d of %d test(s) failed.', ...
            failed, numel(results));
    end
end
