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


classdef RadarsimcBackendTest < matlab.unittest.TestCase
    % RadarsimcBackendTest Unit-level checks against the compiled backend.
    %
    % These tests load radarsimc out of src/+RadarSim and inspect it. They
    % cover the seam between the MATLAB wrappers and the library, which the
    % integration tier cannot report on by itself:
    %
    %   - loadlibrary can parse radarsim.h and build its thunk. CI runs this
    %     tier on every supported MATLAB release, so a header change that
    %     only the oldest release chokes on shows up here rather than in a
    %     user's install.
    %   - radarsim.h and radarsimc agree with each other, and with every
    %     function name the +RadarSim classes pass to calllib. A wrapper
    %     that calls a renamed or removed export fails at run time with a
    %     bare "no method with matching signature", usually deep inside a
    %     simulation.
    %
    % No simulation is run here; RadarSimulationTest owns that.
    %
    % The class skips itself when the backend has not been staged, so
    % run_tests('unit') still passes on a bare checkout.
    %
    % Two ordering notes:
    %
    %   - Loading radarsimc is irreversible for the rest of the MATLAB
    %     session. Unloading it tears the OpenMP runtime out from under the
    %     library's parked worker threads (see RadarSim.Radar.delete), so
    %     these tests never call unloadlibrary.
    %   - LicenseTest describes how the package behaves while radarsimc is
    %     *not* loaded and skips itself once it is. runtests walks
    %     tests/unit in alphabetical order, so this file is named to sort
    %     after LicenseTest.m. CodeAnalyzerTest enforces that for every
    %     file in the tier.

    properties (Access = private)
        % Functions radarsim.h declares that radarsimc does not export, as
        % reported by loadlibrary. Only meaningful when loaded_here_ is
        % true, since loadlibrary reports it once, at load time.
        not_found_ = {}

        % Whether this class is the one that loaded radarsimc.
        loaded_here_ = false
    end

    methods (TestClassSetup)

        function loadTheStagedBackend(testCase)
            pkg_dir = testCase.packageDir();

            lib_files = dir(fullfile(pkg_dir, 'radarsimc.*'));
            lib_files = lib_files(~[lib_files.isdir]);
            testCase.assumeNotEmpty(lib_files, sprintf( ...
                ['No radarsimc shared library found in %s. These tests ' ...
                'need the compiled backend staged in the package ' ...
                'directory.'], pkg_dir));

            testCase.assumeTrue(isfile(fullfile(pkg_dir, 'radarsim.h')), ...
                sprintf('radarsim.h is missing from %s.', pkg_dir));

            if libisloaded('radarsimc')
                return
            end

            testCase.not_found_ = loadlibrary( ...
                fullfile(pkg_dir, 'radarsimc'), fullfile(pkg_dir, 'radarsim.h'));
            testCase.loaded_here_ = true;
        end

    end

    methods (Test)

        function libraryLoadsFromThePackageDirectory(testCase)
            testCase.verifyTrue(libisloaded('radarsimc'), ...
                'radarsimc should be loaded once the package directory is complete.');
        end

        function headerMatchesTheBuiltLibrary(testCase)
            testCase.assumeTrue(testCase.loaded_here_, ...
                'radarsimc was already loaded when this class started.');

            testCase.verifyEmpty(testCase.not_found_, sprintf( ...
                ['radarsim.h declares functions that radarsimc does not ' ...
                'export:\n%s'], strjoin(testCase.not_found_, newline)));
        end

        function everyFunctionTheWrappersCallIsExported(testCase)
            called = testCase.backendFunctionsCalledByThePackage();
            testCase.assertNotEmpty(called, ...
                'No calllib call sites were found in src/+RadarSim.');

            missing = setdiff(called, libfunctions('radarsimc'));

            testCase.verifyEmpty(missing, sprintf( ...
                ['The +RadarSim classes call functions radarsimc does not ' ...
                'export:\n%s\nThe wrappers and radarsim.h have drifted ' ...
                'apart.'], strjoin(missing, newline)));
        end

        function backendReportsASemanticVersion(testCase)
            version_ptr = libpointer("int32Ptr", zeros(1, 3));

            calllib('radarsimc', 'Get_Version', version_ptr);
            numbers = double(version_ptr.Value);

            testCase.verifySize(numbers, [1, 3]);
            testCase.verifyTrue(all(numbers >= 0), ...
                'Version numbers must not be negative.');
            testCase.verifyGreaterThan(sum(numbers), 0, ...
                'The backend reported version 0.0.0.');
        end

        function licenseInfoIsReadableOnceTheLibraryIsLoaded(testCase)
            info = RadarSim.License.get_info();

            % Assert on the shape rather than the text so license details
            % never reach the build log.
            testCase.verifyTrue(isstring(info) && isscalar(info), ...
                'get_info must return a string scalar.');
        end

        function installedLicenseFilesActivateCleanly(testCase)
            % set_license() with no argument is what every wrapper calls
            % right after loading the library, and it warns instead of
            % erroring when it finds nothing to activate.
            pkg_dir = testCase.packageDir();
            testCase.assumeNotEmpty(dir(fullfile(pkg_dir, 'license_RadarSimM_*.lic')), ...
                sprintf('No license file is installed in %s.', pkg_dir));

            testCase.verifyWarningFree(@() RadarSim.License.set_license());
        end

    end

    methods (Access = private)

        % Walks up from this file until it finds the folder holding the
        % RadarSim package, so the tests do not depend on how deeply they
        % are nested under tests/.
        function pkg_dir = packageDir(testCase)
            root = fileparts(mfilename('fullpath'));
            while ~isfolder(fullfile(root, 'src', '+RadarSim'))
                parent = fileparts(root);
                testCase.assertNotEqual(parent, root, ...
                    'Could not locate the repository root from the test file.');
                root = parent;
            end
            pkg_dir = fullfile(root, 'src', '+RadarSim');
        end

        % Collects every backend function name the package hands to
        % calllib. All call sites spell the name out as a literal, so the
        % list can be read straight off the source.
        function names = backendFunctionsCalledByThePackage(testCase)
            listing = dir(fullfile(testCase.packageDir(), '*.m'));

            names = {};
            for k = 1:numel(listing)
                source = fileread(fullfile(listing(k).folder, listing(k).name));
                tokens = regexp(source, ...
                    "calllib\s*\(\s*'radarsimc'\s*,\s*'(\w+)'", 'tokens');
                for m = 1:numel(tokens)
                    names{end+1} = char(tokens{m}{1}); %#ok<AGROW>
                end
            end

            names = unique(names);
        end

    end
end
