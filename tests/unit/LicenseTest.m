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
    % These cover the argument validation that runs before any call into
    % the radarsimc shared library, so they hold whether or not the
    % library happens to be loaded and do not depend on the order the
    % tier runs in.
    %
    % What the license manager reports once the library is loaded is
    % covered by RadarSimulationTest.

    methods (Test)

        function setRejectsMissingFile(testCase)
            missing = fullfile(tempdir, 'license_RadarSimM_does_not_exist.lic');
            testCase.assumeFalse(isfile(missing), ...
                'The placeholder license file must not exist.');

            testCase.verifyError(@() RadarSim.License.set(missing), ?MException);
        end

        function setRejectsANonTextProductName(testCase)
            lic_file = testCase.createLicenseFile();

            testCase.verifyError(@() RadarSim.License.set(lic_file, 42), ...
                ?MException);
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
