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


classdef RxChannelTest < matlab.unittest.TestCase
    % RxChannelTest Unit tests for RadarSim.RxChannel.

    properties (Constant)
        AngleTol = 1e-12;
    end

    methods (Test)

        function defaultsAreApplied(testCase)
            ch = RadarSim.RxChannel([0.1, 0.2, 0.3]);

            testCase.verifyEqual(ch.location_, [0.1, 0.2, 0.3]);
            testCase.verifyEqual(ch.polarization_, [0, 0, 1]);
            testCase.verifyEqual(ch.antenna_gain_, 0);
        end

        function defaultAnglesAreConvertedToRadians(testCase)
            ch = RadarSim.RxChannel([0, 0, 0]);

            testCase.verifyEqual(ch.phi_, [-pi/2, pi/2], 'AbsTol', testCase.AngleTol);
            testCase.verifyEqual(ch.phi_ptn_, [0, 0]);
            testCase.verifyEqual(ch.theta_, [0, pi], 'AbsTol', testCase.AngleTol);
            testCase.verifyEqual(ch.theta_ptn_, [0, 0]);
        end

        function customPolarizationIsPreserved(testCase)
            ch = RadarSim.RxChannel([0, 0, 0], 'polarization', [1, 0, 0]);

            testCase.verifyEqual(ch.polarization_, [1, 0, 0]);
        end

        function azimuthPatternIsNormalizedToItsPeak(testCase)
            az = [-90, -45, 0, 45, 90];
            ptn = [0, 3, 9, 3, 0];

            ch = RadarSim.RxChannel([0, 0, 0], ...
                'azimuth_angle', az, 'azimuth_pattern', ptn);

            testCase.verifyEqual(ch.phi_, az / 180 * pi, 'AbsTol', testCase.AngleTol);
            testCase.verifyEqual(ch.phi_ptn_, ptn - 9);
            testCase.verifyEqual(ch.antenna_gain_, 9);
        end

        function elevationPatternIsFlippedAndNormalized(testCase)
            ch = RadarSim.RxChannel([0, 0, 0], ...
                'elevation_angle', [-90, 0, 90], 'elevation_pattern', [0, 4, 8]);

            testCase.verifyEqual(ch.theta_, [0, 90, 180] / 180 * pi, ...
                'AbsTol', testCase.AngleTol);
            testCase.verifyEqual(ch.theta_ptn_, [8, 4, 0] - 8);
        end

        function elevationAnglesMapToThetaConvention(testCase)
            % theta is measured from +z, so an elevation range of
            % [-45, 60] degrees becomes theta = [30, 135] degrees.
            ch = RadarSim.RxChannel([0, 0, 0], ...
                'elevation_angle', [-45, 60], 'elevation_pattern', [0, 0]);

            testCase.verifyEqual(ch.theta_, [30, 135] / 180 * pi, ...
                'AbsTol', testCase.AngleTol);
        end

        function mismatchedAzimuthPatternIsRejected(testCase)
            fcn = @() RadarSim.RxChannel([0, 0, 0], ...
                'azimuth_angle', [-90, 0, 90], 'azimuth_pattern', [0, 0]);

            testCase.verifyError(fcn, ?MException);
            testCase.verifySubstring(testCase.errorMessage(fcn), ...
                'azimuth_angle and azimuth_pattern');
        end

        function mismatchedElevationPatternIsRejected(testCase)
            fcn = @() RadarSim.RxChannel([0, 0, 0], ...
                'elevation_angle', [-90, 0, 90], 'elevation_pattern', [0, 0]);

            testCase.verifyError(fcn, ?MException);
            testCase.verifySubstring(testCase.errorMessage(fcn), ...
                'elevation_angle and elevation_pattern');
        end

        function badLocationSizeIsRejected(testCase)
            testCase.verifyError(@() RadarSim.RxChannel([0, 0]), ?MException);
        end

        function badPolarizationSizeIsRejected(testCase)
            testCase.verifyError( ...
                @() RadarSim.RxChannel([0, 0, 0], 'polarization', [0, 1]), ?MException);
        end

        function missingLocationIsRejected(testCase)
            testCase.verifyError(@() RadarSim.RxChannel(), 'MATLAB:minrhs');
        end

    end

    methods (Access = private)
        % Runs fcn and returns the message of the error it raises.
        function msg = errorMessage(testCase, fcn)
            msg = '';
            try
                fcn();
                testCase.verifyFail('Expected the call to raise an error.');
            catch exception
                msg = exception.message;
            end
        end
    end
end
