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


classdef RadarTest < matlab.unittest.TestCase
    % RadarTest Unit tests for RadarSim.Radar.
    %
    % The constructor loads radarsimc and allocates a backend radar, so
    % these tests need the compiled library staged in src/+RadarSim. The
    % class skips itself when it is not, which keeps run_tests('unit')
    % working on a bare checkout.
    %
    % The focus is how a radar is assembled out of a transmitter and a
    % receiver: the geometry it reports back, the sample grid it derives,
    % and the timestamp array it builds. RadarSimulationTest covers what
    % happens when that radar is actually run.
    %
    % Every radar here has one Tx and one Rx channel, which is what an
    % unlicensed build allows, so the tests pass with or without a
    % license.
    %
    % radarsimc is never unloaded once a radar has loaded it: that tears
    % the OpenMP runtime out from under the library. See
    % RadarSim.Radar.delete.

    properties (Constant)
        F = [24.075e9, 24.175e9];   % Chirp start/stop frequency (Hz)
        T = 80e-6;                  % Chirp duration (s)
        Fs = 2e6;                   % Sampling frequency (Hz)
        Prp = 100e-6;               % Pulse repetition period (s)
        Pulses = 4;
        TimeTol = 1e-12;
    end

    methods (TestClassSetup)
        function requireCompiledLibrary(testCase)
            pkg_dir = testCase.packageDir();

            lib_files = dir(fullfile(pkg_dir, 'radarsimc.*'));
            lib_files = lib_files(~[lib_files.isdir]);
            testCase.assumeNotEmpty(lib_files, sprintf( ...
                ['No radarsimc shared library found in %s. These tests ' ...
                'build a real radar, so they need the compiled ' ...
                'backend.'], pkg_dir));

            testCase.assumeTrue(isfile(fullfile(pkg_dir, 'radarsim.h')), ...
                sprintf('radarsim.h is missing from %s.', pkg_dir));
        end
    end

    methods (Test)

        % ---------------------------------------------------------------
        % Geometry
        % ---------------------------------------------------------------

        function channelCountsComeFromTheBackend(testCase)
            % num_tx_ and num_rx_ are read back out of the transmitter and
            % receiver rather than counted in MATLAB, so they only agree
            % with the channels that were actually accepted.
            radar = testCase.buildRadar();

            testCase.verifyEqual(double(radar.num_tx_), 1);
            testCase.verifyEqual(double(radar.num_rx_), 1);
        end

        function aSingleFrameIsTheDefault(testCase)
            radar = testCase.buildRadar();

            testCase.verifyEqual(radar.num_frame_, 1);
            testCase.verifyEqual(radar.frame_start_time_, 0);
        end

        function everyFrameStartTimeIsCounted(testCase)
            radar = testCase.buildRadar('frame_time', [0, 1e-3, 2e-3]);

            testCase.verifyEqual(radar.num_frame_, 3);
        end

        function transmitterAndReceiverAreHeldOnTo(testCase)
            [radar, tx, rx] = testCase.buildRadar();

            testCase.verifySameHandle(radar.tx_, tx);
            testCase.verifySameHandle(radar.rx_, rx);
        end

        function versionAgreesWithTheTransmitterAndReceiver(testCase)
            [radar, tx, rx] = testCase.buildRadar();

            testCase.verifyMatches(radar.version_, '^\d+\.\d+\.\d+$');
            testCase.verifyEqual(radar.version_, tx.version_);
            testCase.verifyEqual(radar.version_, rx.version_);
        end

        % ---------------------------------------------------------------
        % Sample grid
        % ---------------------------------------------------------------

        function samplesPerPulseFollowThePulseAndSamplingRate(testCase)
            radar = testCase.buildRadar();

            testCase.verifyEqual(radar.samples_per_pulse_, ...
                floor(testCase.T * testCase.Fs));
        end

        function partialSamplesAreTruncated(testCase)
            % 80.4 us at 2 MHz is 160.8 sampling intervals. The trailing
            % fraction is dropped, not rounded up, so a sample is never
            % reported that the chirp does not fully cover.
            radar = testCase.buildRadarOn([0, 80.4e-6]);

            testCase.verifyEqual(radar.samples_per_pulse_, 160);
        end

        % ---------------------------------------------------------------
        % Timestamps
        % ---------------------------------------------------------------

        function timestampCoversEverySampleAndPulse(testCase)
            radar = testCase.buildRadar();

            testCase.verifySize(radar.timestamp_, ...
                [radar.samples_per_pulse_, testCase.Pulses]);
        end

        function timestampStartsAtZero(testCase)
            radar = testCase.buildRadar();

            testCase.verifyEqual(radar.timestamp_(1, 1), 0, ...
                'AbsTol', testCase.TimeTol);
        end

        function samplesAreSpacedBySamplingInterval(testCase)
            radar = testCase.buildRadar();

            step = diff(radar.timestamp_(:, 1));

            testCase.verifyEqual(step, ...
                repmat(1 / testCase.Fs, radar.samples_per_pulse_ - 1, 1), ...
                'AbsTol', testCase.TimeTol);
        end

        function pulsesAreSpacedByThePrp(testCase)
            radar = testCase.buildRadar();

            step = diff(radar.timestamp_(1, :));

            testCase.verifyEqual(step, ...
                repmat(testCase.Prp, 1, testCase.Pulses - 1), ...
                'AbsTol', testCase.TimeTol);
        end

        function everyFrameGetsItsOwnTimestampPage(testCase)
            % The third dimension runs over num_tx * num_rx * num_frame.
            radar = testCase.buildRadar('frame_time', [0, 1e-3, 2e-3]);

            testCase.verifySize(radar.timestamp_, ...
                [radar.samples_per_pulse_, testCase.Pulses, 3]);
        end

        function channelDelayShiftsTheTimestamps(testCase)
            % A transmit channel delay pushes the whole sample grid out by
            % the same amount.
            delay = 1e-6;
            plain = testCase.buildRadar();
            delayed = testCase.buildRadar('tx_delay', delay);

            testCase.verifyEqual(delayed.timestamp_, plain.timestamp_ + delay, ...
                'AbsTol', testCase.TimeTol);
        end

        % ---------------------------------------------------------------
        % Backend handle
        % ---------------------------------------------------------------

        function constructorAllocatesABackendRadar(testCase)
            radar = testCase.buildRadar();

            testCase.verifyNotEqual(radar.radar_ptr, 0, ...
                'Create_Radar should return a non-null handle.');
        end

        function resetReleasesTheBackendRadar(testCase)
            radar = testCase.buildRadar();

            radar.reset();

            testCase.verifyEqual(radar.radar_ptr, 0);
        end

        function resetIsIdempotent(testCase)
            % Teardown resets every radar these tests build, so a second
            % reset has to be harmless.
            radar = testCase.buildRadar();

            radar.reset();

            testCase.verifyWarningFree(@() radar.reset());
            testCase.verifyEqual(radar.radar_ptr, 0);
        end

        % ---------------------------------------------------------------
        % Argument validation
        % ---------------------------------------------------------------

        function transmitterAndReceiverCannotBeSwapped(testCase)
            [~, tx, rx] = testCase.buildRadar();

            testCase.verifyError(@() RadarSim.Radar(rx, tx), ?MException);
        end

        function badRotationSizeIsRejected(testCase)
            [~, tx, rx] = testCase.buildRadar();

            testCase.verifyError( ...
                @() RadarSim.Radar(tx, rx, 'rotation', [0, 0]), ?MException);
        end

    end

    methods (Access = private)

        % Builds a single-channel FMCW radar and registers the teardown
        % that frees the backend resources in the reverse order. The
        % transmitter and receiver are returned as well for the tests that
        % need to reach them.
        function [radar, tx, rx] = buildRadar(testCase, varargin)
            [radar, tx, rx] = testCase.buildRadarOn( ...
                [0, RadarTest.T], varargin{:});
        end

        % Builds the same radar on an explicit chirp, for the tests that
        % are about how the sample grid is derived from it.
        function [radar, tx, rx] = buildRadarOn(testCase, t, kwargs)
            arguments
                testCase
                t
                kwargs.frame_time = 0
                kwargs.tx_delay (1,1) = 0
            end

            tx = RadarSim.Transmitter(RadarTest.F, t, ...
                'tx_power', 15, ...
                'prp', RadarTest.Prp, ...
                'pulses', RadarTest.Pulses, ...
                'channels', {RadarSim.TxChannel([0, 0, 0], ...
                'delay', kwargs.tx_delay)});

            rx = RadarSim.Receiver(RadarTest.Fs, 20, 500, 30, ...
                'noise_figure', 12, ...
                'channels', {RadarSim.RxChannel([0, 0, 0])});

            radar = RadarSim.Radar(tx, rx, 'frame_time', kwargs.frame_time);

            % Teardown runs last-in-first-out, so the radar is released
            % before the transmitter and receiver it was built from.
            testCase.addTeardown(@() tx.reset());
            testCase.addTeardown(@() rx.reset());
            testCase.addTeardown(@() radar.reset());
        end

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

    end
end
