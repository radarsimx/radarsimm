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


classdef MeshTargetTest < matlab.unittest.TestCase
    % MeshTargetTest Unit tests for RadarSim.MeshTarget.

    properties (Constant)
        % A single triangle in the x-y plane.
        Points = [0, 0, 0; 1, 0, 0; 0, 1, 0];
        Connectivity = int32([1, 2, 3]);
    end

    methods (Test)

        function meshGeometryIsPreserved(testCase)
            target = testCase.makeTarget();

            testCase.verifyEqual(target.points_, testCase.Points);
            testCase.verifyEqual(target.connectivity_list_, testCase.Connectivity);
        end

        function typeIsMesh(testCase)
            target = testCase.makeTarget();

            testCase.verifyEqual(target.type_, "mesh");
        end

        function motionPropertiesArePreserved(testCase)
            target = RadarSim.MeshTarget(testCase.Points, testCase.Connectivity, ...
                [10, -2, 0.5], [-3, 0, 1], [0, 0, 0], [0, 0, 0]);

            testCase.verifyEqual(target.location_, [10, -2, 0.5]);
            testCase.verifyEqual(target.speed_, [-3, 0, 1]);
        end

        function rotationIsConvertedToRadians(testCase)
            target = RadarSim.MeshTarget(testCase.Points, testCase.Connectivity, ...
                [0, 0, 0], [0, 0, 0], [180, 90, -45], [0, 0, 0]);

            testCase.verifyEqual(target.rotation_, [pi, pi/2, -pi/4], 'AbsTol', 1e-12);
        end

        function rotationRateIsConvertedToRadians(testCase)
            target = RadarSim.MeshTarget(testCase.Points, testCase.Connectivity, ...
                [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 360, 90]);

            testCase.verifyEqual(target.rotation_rate_, [0, 2*pi, pi/2], 'AbsTol', 1e-12);
        end

        function optionalDefaultsAreApplied(testCase)
            target = testCase.makeTarget();

            testCase.verifyEqual(target.origin_, [0, 0, 0]);
            testCase.verifyEqual(target.permittivity_, 'PEC');
            testCase.verifyFalse(logical(target.skip_diffusion_));
            testCase.verifyEqual(target.density_, 0);
            testCase.verifyFalse(logical(target.environment_));
        end

        function optionalArgumentsArePreserved(testCase)
            target = RadarSim.MeshTarget(testCase.Points, testCase.Connectivity, ...
                [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], ...
                'origin', [1, 2, 3], ...
                'permittivity', 3.2 - 0.5i, ...
                'skip_diffusion', true, ...
                'density', 2.5, ...
                'environment', true);

            testCase.verifyEqual(target.origin_, [1, 2, 3]);
            testCase.verifyEqual(target.permittivity_, 3.2 - 0.5i);
            testCase.verifyTrue(logical(target.skip_diffusion_));
            testCase.verifyEqual(target.density_, 2.5);
            testCase.verifyTrue(logical(target.environment_));
        end

        function multiTriangleMeshIsAccepted(testCase)
            points = [0, 0, 0; 1, 0, 0; 0, 1, 0; 1, 1, 0];
            connectivity = int32([1, 2, 3; 2, 4, 3]);

            target = RadarSim.MeshTarget(points, connectivity, ...
                [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0]);

            testCase.verifySize(target.points_, [4, 3]);
            testCase.verifySize(target.connectivity_list_, [2, 3]);
        end

        function badLocationSizeIsRejected(testCase)
            testCase.verifyError(@() RadarSim.MeshTarget( ...
                testCase.Points, testCase.Connectivity, ...
                [0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0]), ?MException);
        end

        function badRotationSizeIsRejected(testCase)
            testCase.verifyError(@() RadarSim.MeshTarget( ...
                testCase.Points, testCase.Connectivity, ...
                [0, 0, 0], [0, 0, 0], [0, 0], [0, 0, 0]), ?MException);
        end

        function badOriginSizeIsRejected(testCase)
            testCase.verifyError(@() RadarSim.MeshTarget( ...
                testCase.Points, testCase.Connectivity, ...
                [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], ...
                'origin', [0, 0]), ?MException);
        end

        function missingMotionArgumentsAreRejected(testCase)
            testCase.verifyError(@() RadarSim.MeshTarget( ...
                testCase.Points, testCase.Connectivity, ...
                [0, 0, 0], [0, 0, 0], [0, 0, 0]), 'MATLAB:minrhs');
        end

    end

    methods (Access = private)
        function target = makeTarget(testCase)
            target = RadarSim.MeshTarget(testCase.Points, testCase.Connectivity, ...
                [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0]);
        end
    end
end
