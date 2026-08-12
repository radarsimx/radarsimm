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


classdef PointTargetTest < matlab.unittest.TestCase
    % PointTargetTest Unit tests for RadarSim.PointTarget.

    methods (Test)

        function propertiesArePreserved(testCase)
            target = RadarSim.PointTarget([200, 0, 0], [-5, 0, 0], 20);

            testCase.verifyEqual(target.location_, [200, 0, 0]);
            testCase.verifyEqual(target.speed_, [-5, 0, 0]);
            testCase.verifyEqual(target.rcs_, 20);
        end

        function typeIsPoint(testCase)
            target = RadarSim.PointTarget([0, 0, 0], [0, 0, 0], 0);

            testCase.verifyEqual(target.type_, "point");
        end

        function phaseDefaultsToZero(testCase)
            target = RadarSim.PointTarget([10, 0, 0], [0, 0, 0], 10);

            testCase.verifyEqual(target.phase_, 0);
        end

        function phaseIsConvertedToRadians(testCase)
            testCase.verifyEqual( ...
                testCase.phaseOf(90), pi/2, 'AbsTol', 1e-12);
            testCase.verifyEqual( ...
                testCase.phaseOf(180), pi, 'AbsTol', 1e-12);
            testCase.verifyEqual( ...
                testCase.phaseOf(-45), -pi/4, 'AbsTol', 1e-12);
        end

        function negativeAndFractionalRcsAreAccepted(testCase)
            target = RadarSim.PointTarget([10, 0, 0], [0, 0, 0], -12.5);

            testCase.verifyEqual(target.rcs_, -12.5);
        end

        function targetsAreIndependentHandles(testCase)
            first = RadarSim.PointTarget([10, 0, 0], [0, 0, 0], 10);
            second = RadarSim.PointTarget([20, 0, 0], [0, 0, 0], 20);

            first.rcs_ = 30;

            testCase.verifyEqual(first.rcs_, 30);
            testCase.verifyEqual(second.rcs_, 20);
            testCase.verifyTrue(isa(first, 'handle'));
        end

        function badLocationSizeIsRejected(testCase)
            testCase.verifyError( ...
                @() RadarSim.PointTarget([0, 0], [0, 0, 0], 10), ?MException);
        end

        function badSpeedSizeIsRejected(testCase)
            testCase.verifyError( ...
                @() RadarSim.PointTarget([0, 0, 0], [0, 0], 10), ?MException);
        end

        function missingRcsIsRejected(testCase)
            testCase.verifyError( ...
                @() RadarSim.PointTarget([0, 0, 0], [0, 0, 0]), 'MATLAB:minrhs');
        end

    end

    methods (Access = private)
        function phase = phaseOf(~, phase_deg)
            target = RadarSim.PointTarget([10, 0, 0], [0, 0, 0], 10, ...
                'phase', phase_deg);
            phase = target.phase_;
        end
    end
end
