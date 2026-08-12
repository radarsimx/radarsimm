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


classdef TransmitterTest < matlab.unittest.TestCase
    % TransmitterTest Unit tests for RadarSim.Transmitter.
    %
    % The constructor loads radarsimc and allocates a backend transmitter,
    % so these tests need the compiled library staged in src/+RadarSim.
    % The class skips itself when it is not, which keeps
    % run_tests('unit') working on a bare checkout.
    %
    % Most of what is checked here is the waveform bookkeeping the
    % constructor does before it reaches the backend: expanding scalar
    % arguments, deriving the pulse repetition period and pulse start
    % times, and rejecting inconsistent inputs. Those are pure MATLAB and
    % never covered by a simulation assertion, which only sees the result.
    %
    % Only one Tx channel is ever added, which is what an unlicensed build
    % allows, so the tests pass with or without a license.
    %
    % radarsimc is never unloaded once a transmitter has loaded it: that
    % tears the OpenMP runtime out from under the library. See
    % RadarSim.Radar.delete.

    properties (Constant)
        F = [24.075e9, 24.175e9];   % Chirp start/stop frequency (Hz)
        T = 80e-6;                  % Chirp duration (s)
        Prp = 100e-6;               % Pulse repetition period (s)
        Pulses = 4;
        TimeTol = 1e-15;
    end

    methods (TestClassSetup)
        function requireCompiledLibrary(testCase)
            pkg_dir = testCase.packageDir();

            lib_files = dir(fullfile(pkg_dir, 'radarsimc.*'));
            lib_files = lib_files(~[lib_files.isdir]);
            testCase.assumeNotEmpty(lib_files, sprintf( ...
                ['No radarsimc shared library found in %s. These tests ' ...
                'build a real transmitter, so they need the compiled ' ...
                'backend.'], pkg_dir));

            testCase.assumeTrue(isfile(fullfile(pkg_dir, 'radarsim.h')), ...
                sprintf('radarsim.h is missing from %s.', pkg_dir));
        end
    end

    methods (Test)

        % ---------------------------------------------------------------
        % Waveform
        % ---------------------------------------------------------------

        function frequencyAndTimeArePreserved(testCase)
            tx = testCase.buildTransmitter();

            testCase.verifyEqual(tx.f_, testCase.F);
            testCase.verifyEqual(tx.t_, [0, testCase.T]);
        end

        function scalarFrequencyBecomesAConstantTone(testCase)
            % A single frequency is expanded into a start/stop pair, which
            % is how a CW pulse is described to the backend.
            tx = testCase.buildWaveform(24.125e9, [0, testCase.T]);

            testCase.verifyEqual(tx.f_, [24.125e9, 24.125e9]);
        end

        function scalarDurationIsMeasuredFromZero(testCase)
            tx = testCase.buildWaveform(testCase.F, testCase.T);

            testCase.verifyEqual(tx.t_, [0, testCase.T]);
        end

        function pulseDurationIsTheSpanOfTheTimeVector(testCase)
            tx = testCase.buildWaveform(testCase.F, [10e-6, 90e-6]);

            testCase.verifyEqual(tx.pulse_duration_, 80e-6, ...
                'AbsTol', testCase.TimeTol);
        end

        function transmitPowerDefaultsToZeroDbm(testCase)
            tx = testCase.buildTransmitter();

            testCase.verifyEqual(tx.power_, 0);
        end

        function mismatchedFrequencyAndTimeAreRejected(testCase)
            fcn = @() testCase.buildWaveform( ...
                [24e9, 24.1e9, 24.2e9], [0, testCase.T]);

            testCase.verifyError(fcn, ?MException);
            testCase.verifySubstring(testCase.errorMessage(fcn), ...
                'f and t must have the same length');
        end

        % ---------------------------------------------------------------
        % Pulse timing
        % ---------------------------------------------------------------

        function pulsesDefaultToOne(testCase)
            tx = testCase.buildTransmitter();

            testCase.verifyEqual(double(tx.pulses_), 1);
        end

        function defaultPrpIsBackToBackPulses(testCase)
            % With no prp given, each pulse starts as the previous one
            % ends, so the prp is the pulse duration.
            tx = testCase.buildTransmitter('pulses', testCase.Pulses);

            testCase.verifyEqual(tx.prp_, ...
                testCase.T + zeros(1, testCase.Pulses), ...
                'AbsTol', testCase.TimeTol);
        end

        function scalarPrpIsBroadcastAcrossThePulses(testCase)
            tx = testCase.buildTransmitter( ...
                'pulses', testCase.Pulses, 'prp', testCase.Prp);

            testCase.verifyEqual(tx.prp_, ...
                testCase.Prp + zeros(1, testCase.Pulses), ...
                'AbsTol', testCase.TimeTol);
        end

        function perPulsePrpIsPreserved(testCase)
            prp = [100e-6, 120e-6, 140e-6, 160e-6];
            tx = testCase.buildTransmitter('pulses', testCase.Pulses, 'prp', prp);

            testCase.verifyEqual(tx.prp_, prp);
        end

        function pulseStartTimesAccumulateThePrp(testCase)
            % The first pulse starts at zero and every later one is offset
            % by the periods before it.
            prp = [100e-6, 120e-6, 140e-6, 160e-6];
            tx = testCase.buildTransmitter('pulses', testCase.Pulses, 'prp', prp);

            testCase.verifyEqual(tx.pulse_start_time_, ...
                [0, 120e-6, 260e-6, 420e-6], 'AbsTol', testCase.TimeTol);
        end

        function prpShorterThanThePulseIsRejected(testCase)
            fcn = @() testCase.buildTransmitter('prp', testCase.T / 2);

            testCase.verifyError(fcn, ?MException);
            testCase.verifySubstring(testCase.errorMessage(fcn), ...
                "prp can't be smaller than the pulse length");
        end

        function tooFewPrpEntriesAreRejected(testCase)
            fcn = @() testCase.buildTransmitter( ...
                'pulses', testCase.Pulses, 'prp', [testCase.Prp, testCase.Prp]);

            testCase.verifyError(fcn, ?MException);
            testCase.verifySubstring(testCase.errorMessage(fcn), ...
                'length of prp must be the same of pulses');
        end

        % ---------------------------------------------------------------
        % Frequency offset
        % ---------------------------------------------------------------

        function frequencyOffsetDefaultsToZeroPerPulse(testCase)
            tx = testCase.buildTransmitter('pulses', testCase.Pulses, ...
                'prp', testCase.Prp);

            testCase.verifyEqual(tx.f_offset_, zeros(1, testCase.Pulses));
        end

        function frequencyOffsetIsPreserved(testCase)
            f_offset = [0, 1e6, 2e6, 3e6];
            tx = testCase.buildTransmitter('pulses', testCase.Pulses, ...
                'prp', testCase.Prp, 'f_offset', f_offset);

            testCase.verifyEqual(tx.f_offset_, f_offset);
        end

        function frequencyOffsetLengthMustMatchThePulseCount(testCase)
            fcn = @() testCase.buildTransmitter('pulses', testCase.Pulses, ...
                'prp', testCase.Prp, 'f_offset', [0, 1e6]);

            testCase.verifyError(fcn, ?MException);
            testCase.verifySubstring(testCase.errorMessage(fcn), ...
                'length of f_offset must be the same as pulses');
        end

        % ---------------------------------------------------------------
        % SSB phase noise
        % ---------------------------------------------------------------

        function phaseNoiseNeedsMatchingFrequencyAndPowerVectors(testCase)
            fcn = @() testCase.buildTransmitter( ...
                'pn_f', [1e3, 1e4, 1e5], 'pn_power', [-100, -110], ...
                'pn_fs', 10e6, 'pn_num_samples', 1024);

            testCase.verifyError(fcn, ?MException);
            testCase.verifySubstring(testCase.errorMessage(fcn), ...
                'pn_f and pn_power must have the same length');
        end

        function phaseNoiseNeedsASamplingRateAndLength(testCase)
            fcn = @() testCase.buildTransmitter( ...
                'pn_f', [1e3, 1e4], 'pn_power', [-100, -110]);

            testCase.verifyError(fcn, ?MException);
            testCase.verifySubstring(testCase.errorMessage(fcn), ...
                'pn_fs and pn_num_samples are required');
        end

        % ---------------------------------------------------------------
        % Channels
        % ---------------------------------------------------------------

        function transmitterStartsWithoutChannels(testCase)
            tx = testCase.buildTransmitter();

            testCase.verifyEmpty(tx.channels_);
            testCase.verifyEmpty(tx.delay_);
        end

        function constructorRegistersTheChannelsItIsGiven(testCase)
            tx = testCase.buildTransmitter( ...
                'channels', {RadarSim.TxChannel([0, 0, 0])});

            testCase.verifyNumElements(tx.channels_, 1);
        end

        function channelDelayIsCollected(testCase)
            tx = testCase.buildTransmitter( ...
                'channels', {RadarSim.TxChannel([0, 0, 0], 'delay', 1e-6)});

            testCase.verifyEqual(tx.delay_, 1e-6, 'AbsTol', testCase.TimeTol);
        end

        % ---------------------------------------------------------------
        % Backend handle
        % ---------------------------------------------------------------

        function constructorAllocatesABackendTransmitter(testCase)
            tx = testCase.buildTransmitter();

            testCase.verifyNotEqual(tx.tx_ptr, 0, ...
                'Create_Transmitter should return a non-null handle.');
        end

        function versionIsReportedAsSemanticVersion(testCase)
            tx = testCase.buildTransmitter();

            testCase.verifyMatches(tx.version_, '^\d+\.\d+\.\d+$');
        end

        function resetReleasesTheBackendTransmitter(testCase)
            tx = testCase.buildTransmitter( ...
                'channels', {RadarSim.TxChannel([0, 0, 0])});

            tx.reset();

            testCase.verifyEqual(tx.tx_ptr, 0);
            testCase.verifyEmpty(tx.channels_);
            testCase.verifyEmpty(tx.delay_);
        end

        function resetIsIdempotent(testCase)
            % Teardown resets every transmitter these tests build, so a
            % second reset has to be harmless.
            tx = testCase.buildTransmitter();

            tx.reset();

            testCase.verifyWarningFree(@() tx.reset());
            testCase.verifyEqual(tx.tx_ptr, 0);
        end

    end

    methods (Access = private)

        % Builds a transmitter on the shared chirp and registers the
        % teardown that frees its backend resources.
        function tx = buildTransmitter(testCase, varargin)
            tx = testCase.buildWaveform(TransmitterTest.F, ...
                [0, TransmitterTest.T], varargin{:});
        end

        % Builds a transmitter on an explicit waveform, for the tests that
        % are about how f and t themselves are interpreted.
        function tx = buildWaveform(testCase, f, t, varargin)
            tx = RadarSim.Transmitter(f, t, varargin{:});
            testCase.addTeardown(@() tx.reset());
        end

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
