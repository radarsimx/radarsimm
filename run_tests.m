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


function results = run_tests()
    % run_tests Runs the RadarSimM unit test suite in tests/.
    %
    % The suite covers the parts of the package that are implemented in
    % pure MATLAB, so it runs without the compiled radarsimc library.
    %
    % Example:
    %   results = run_tests();
    %
    % The function errors if any test fails, which makes it usable as a
    % batch entry point:
    %   matlab -batch "run_tests"

    repo_root = fileparts(mfilename('fullpath'));

    original_path = path();
    cleanup = onCleanup(@() path(original_path)); %#ok<NASGU>
    addpath(fullfile(repo_root, 'src'));

    results = runtests(fullfile(repo_root, 'tests'));
    disp(results);

    failed = sum([results.Failed]);
    if failed > 0
        error('RadarSim:Tests:Failed', '%d of %d test(s) failed.', ...
            failed, numel(results));
    end
end
