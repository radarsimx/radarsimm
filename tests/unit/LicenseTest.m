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


classdef LicenseTest < matlab.unittest.TestCase
    % LicenseTest Unit tests for RadarSim.License.
    %
    % These tests cover the guard clauses that run before any call into the
    % radarsimc shared library, so they do not need the library to be
    % installed. They are skipped if the library happens to be loaded,
    % which is the only honest thing to do: the branch they describe is
    % unreachable once radarsimc is in the process, and nothing unloads it
    % again (see RadarSim.Radar.delete).
    %
    % That makes them order-sensitive. TransmitterTest, ReceiverTest and
    % RadarTest all build real backend objects, whose constructors load
    % the library, and runtests walks tests/unit alphabetically, so this
    % file has to sort before every file that does. CodeAnalyzerTest
    % checks that, so a future test file cannot silently switch these
    % off.

    methods (TestMethodSetup)
        function skipWhenLibraryIsLoaded(testCase)
            testCase.assumeFalse(libisloaded('radarsimc'), ...
                'These tests describe the behavior when radarsimc is not loaded.');
        end
    end

    methods (Test)

        function setLicenseRequiresLoadedLibrary(testCase)
            testCase.verifyError(@() RadarSim.License.set_license(), ...
                'RadarSim:License:LibraryNotLoaded');
        end

        function setLicenseWithPathRequiresLoadedLibrary(testCase)
            lic_file = testCase.createLicenseFile();

            testCase.verifyError(@() RadarSim.License.set_license(lic_file), ...
                'RadarSim:License:LibraryNotLoaded');
        end

        function getInfoRequiresLoadedLibrary(testCase)
            testCase.verifyError(@() RadarSim.License.get_info(), ...
                'RadarSim:License:LibraryNotLoaded');
        end

        function setRequiresLoadedLibrary(testCase)
            lic_file = testCase.createLicenseFile();

            testCase.verifyError(@() RadarSim.License.set(lic_file), ...
                'RadarSim:License:LibraryNotLoaded');
        end

        function setRequiresLoadedLibraryWithExplicitProduct(testCase)
            lic_file = testCase.createLicenseFile();

            testCase.verifyError(@() RadarSim.License.set(lic_file, 'RadarSimM'), ...
                'RadarSim:License:LibraryNotLoaded');
        end

        function setRejectsMissingFile(testCase)
            missing = fullfile(tempdir, 'license_RadarSimM_does_not_exist.lic');
            testCase.assumeFalse(isfile(missing), ...
                'The placeholder license file must not exist.');

            testCase.verifyError(@() RadarSim.License.set(missing), ?MException);
        end

        function setLicenseRejectsNonTextInput(testCase)
            testCase.verifyError(@() RadarSim.License.set_license(42), ?MException);
        end

        function licenseHelpersAreStatic(testCase)
            % License is a utility class: every public method must be
            % callable without constructing an object.
            mc = meta.class.fromName('RadarSim.License');
            testCase.assertNotEmpty(mc, 'RadarSim.License was not found.');

            method_names = {mc.MethodList.Name};
            for name = ["set_license", "get_info", "set"]
                idx = strcmp(method_names, char(name));
                testCase.assertTrue(any(idx), ...
                    sprintf('RadarSim.License.%s is missing.', name));
                testCase.verifyTrue(mc.MethodList(idx).Static, ...
                    sprintf('RadarSim.License.%s must be static.', name));
            end
        end

    end

    methods (Access = private)
        % Creates an empty placeholder license file in a temporary folder
        % that is removed when the test finishes.
        function lic_file = createLicenseFile(testCase)
            import matlab.unittest.fixtures.TemporaryFolderFixture

            fixture = testCase.applyFixture(TemporaryFolderFixture);
            lic_file = fullfile(fixture.Folder, 'license_RadarSimM_TEST.lic');

            fid = fopen(lic_file, 'w');
            testCase.assertNotEqual(fid, -1, ...
                'Could not create a temporary license file.');
            fprintf(fid, 'placeholder');
            fclose(fid);
        end
    end
end
