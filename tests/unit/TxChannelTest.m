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


classdef TxChannelTest < matlab.unittest.TestCase
    % TxChannelTest Unit tests for RadarSim.TxChannel.
    %
    % TxChannel is pure MATLAB, so every code path can be exercised without
    % the radarsimc shared library.

    properties (Constant)
        AngleTol = 1e-12;
    end

    methods (Test)

        % ---------------------------------------------------------------
        % Construction and defaults
        % ---------------------------------------------------------------

        function defaultsAreApplied(testCase)
            ch = RadarSim.TxChannel([1, 2, 3]);

            testCase.verifyEqual(ch.location_, [1, 2, 3]);
            testCase.verifyEqual(ch.polarization_, [0, 0, 1]);
            testCase.verifyEqual(ch.delay_, 0);
            testCase.verifyEqual(ch.antenna_gain_, 0);
            testCase.verifyEmpty(ch.pulse_mod_);
            testCase.verifyEmpty(ch.mod_var_);
            testCase.verifyEmpty(ch.mod_t_);
        end

        function defaultAnglesAreConvertedToRadians(testCase)
            ch = RadarSim.TxChannel([0, 0, 0]);

            % Azimuth: [-90, 90] degrees -> [-pi/2, pi/2] radians
            testCase.verifyEqual(ch.phi_, [-pi/2, pi/2], 'AbsTol', testCase.AngleTol);
            testCase.verifyEqual(ch.phi_ptn_, [0, 0]);

            % Elevation: [-90, 90] degrees -> theta = flip(90 - el) = [0, pi]
            testCase.verifyEqual(ch.theta_, [0, pi], 'AbsTol', testCase.AngleTol);
            testCase.verifyEqual(ch.theta_ptn_, [0, 0]);
        end

        function customLocationPolarizationAndDelayArePreserved(testCase)
            ch = RadarSim.TxChannel([-0.1, 0.2, 0.3], ...
                'polarization', [0, 1, 0], ...
                'delay', 1e-6);

            testCase.verifyEqual(ch.location_, [-0.1, 0.2, 0.3]);
            testCase.verifyEqual(ch.polarization_, [0, 1, 0]);
            testCase.verifyEqual(ch.delay_, 1e-6);
        end

        % ---------------------------------------------------------------
        % Antenna patterns
        % ---------------------------------------------------------------

        function azimuthPatternIsNormalizedToItsPeak(testCase)
            az = [-90, -45, 0, 45, 90];
            ptn = [0, 6, 12, 6, 0];

            ch = RadarSim.TxChannel([0, 0, 0], ...
                'azimuth_angle', az, 'azimuth_pattern', ptn);

            testCase.verifyEqual(ch.phi_, az / 180 * pi, 'AbsTol', testCase.AngleTol);
            testCase.verifyEqual(ch.phi_ptn_, ptn - 12);
            testCase.verifyEqual(ch.antenna_gain_, 12, ...
                'antenna_gain_ must be the peak of the azimuth pattern.');
        end

        function elevationPatternIsFlippedAndNormalized(testCase)
            el = [-90, 0, 90];
            ptn = [0, 4, 8];

            ch = RadarSim.TxChannel([0, 0, 0], ...
                'elevation_angle', el, 'elevation_pattern', ptn);

            % theta = flip(90 - elevation_angle), i.e. [0, 90, 180] degrees
            testCase.verifyEqual(ch.theta_, [0, 90, 180] / 180 * pi, ...
                'AbsTol', testCase.AngleTol);
            testCase.verifyEqual(ch.theta_ptn_, [8, 4, 0] - 8);
        end

        function negativeGainPatternIsShiftedToZeroPeak(testCase)
            ch = RadarSim.TxChannel([0, 0, 0], ...
                'azimuth_angle', [-60, 0, 60], 'azimuth_pattern', [-20, -3, -10]);

            testCase.verifyEqual(ch.phi_ptn_, [-17, 0, -7]);
            testCase.verifyEqual(ch.antenna_gain_, -3);
        end

        % ---------------------------------------------------------------
        % Pulse (slow-time) modulation
        % ---------------------------------------------------------------

        function pulseModulationCombinesAmplitudeAndPhase(testCase)
            ch = RadarSim.TxChannel([0, 0, 0], ...
                'pulse_amp', [1, 2, 3], 'pulse_phs', [0, 90, 180]);

            testCase.verifyEqual(ch.pulse_mod_, [1, 2i, -3], 'AbsTol', 1e-12);
        end

        function pulseModulationWithAmplitudeOnly(testCase)
            ch = RadarSim.TxChannel([0, 0, 0], 'pulse_amp', [1, 0.5, 0.25]);

            testCase.verifyEqual(ch.pulse_mod_, [1, 0.5, 0.25]);
        end

        function pulseModulationWithPhaseOnly(testCase)
            ch = RadarSim.TxChannel([0, 0, 0], 'pulse_phs', [0, 90, 180, 270]);

            testCase.verifyEqual(ch.pulse_mod_, [1, 1i, -1, -1i], 'AbsTol', 1e-12);
        end

        function pulseModulationIsEmptyWhenNotRequested(testCase)
            ch = RadarSim.TxChannel([0, 0, 0]);

            testCase.verifyEmpty(ch.pulse_mod_);
        end

        % ---------------------------------------------------------------
        % Fast-time modulation
        % ---------------------------------------------------------------

        function fastTimeModulationCombinesAmplitudeAndPhase(testCase)
            mod_t = [0, 1e-6, 2e-6];

            ch = RadarSim.TxChannel([0, 0, 0], ...
                'mod_t', mod_t, 'amp', [1, 2, 1], 'phs', [0, 180, 90]);

            testCase.verifyEqual(ch.mod_t_, mod_t);
            testCase.verifyEqual(ch.mod_var_, [1, -2, 1i], 'AbsTol', 1e-12);
        end

        function fastTimeModulationDefaultsAmplitudeToOne(testCase)
            ch = RadarSim.TxChannel([0, 0, 0], ...
                'mod_t', [0, 1e-6], 'phs', [0, 180]);

            testCase.verifyEqual(ch.mod_var_, [1, -1], 'AbsTol', 1e-12);
        end

        function fastTimeModulationDefaultsPhaseToZero(testCase)
            ch = RadarSim.TxChannel([0, 0, 0], ...
                'mod_t', [0, 1e-6], 'amp', [1, 3]);

            testCase.verifyEqual(ch.mod_var_, [1, 3], 'AbsTol', 1e-12);
        end

        function fastTimeModulationIsEmptyWhenNotRequested(testCase)
            ch = RadarSim.TxChannel([0, 0, 0]);

            testCase.verifyEmpty(ch.mod_var_);
            testCase.verifyEmpty(ch.mod_t_);
        end

        % ---------------------------------------------------------------
        % Input validation
        % ---------------------------------------------------------------

        function mismatchedAzimuthPatternIsRejected(testCase)
            fcn = @() RadarSim.TxChannel([0, 0, 0], ...
                'azimuth_angle', [-90, 0, 90], 'azimuth_pattern', [0, 0]);

            testCase.verifyError(fcn, ?MException);
            testCase.verifySubstring(testCase.errorMessage(fcn), ...
                'azimuth_angle and azimuth_pattern');
        end

        function mismatchedElevationPatternIsRejected(testCase)
            fcn = @() RadarSim.TxChannel([0, 0, 0], ...
                'elevation_angle', [-90, 0, 90], 'elevation_pattern', [0, 0]);

            testCase.verifyError(fcn, ?MException);
            testCase.verifySubstring(testCase.errorMessage(fcn), ...
                'elevation_angle and elevation_pattern');
        end

        function badLocationSizeIsRejected(testCase)
            testCase.verifyError(@() RadarSim.TxChannel([0, 0]), ...
                'RadarSim:TxChannel:InvalidLocation');
            testCase.verifyError(@() RadarSim.TxChannel([0, 0, 0, 0]), ...
                'RadarSim:TxChannel:InvalidLocation');
        end

        function scalarLocationIsRejected(testCase)
            % A (1,3) size in the arguments block would expand a scalar
            % into [42, 42, 42] and build a channel out there without
            % complaint.
            testCase.verifyError(@() RadarSim.TxChannel(42), ...
                'RadarSim:TxChannel:InvalidLocation');
        end

        function columnLocationIsRejected(testCase)
            testCase.verifyError(@() RadarSim.TxChannel([0; 0; 0]), ...
                'RadarSim:TxChannel:InvalidLocation');
        end

        function badPolarizationSizeIsRejected(testCase)
            testCase.verifyError( ...
                @() RadarSim.TxChannel([0, 0, 0], 'polarization', [0, 1]), ?MException);
        end

        function missingLocationIsRejected(testCase)
            testCase.verifyError(@() RadarSim.TxChannel(), 'MATLAB:minrhs');
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
