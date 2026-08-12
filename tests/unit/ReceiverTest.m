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


classdef ReceiverTest < matlab.unittest.TestCase
    % ReceiverTest Unit tests for RadarSim.Receiver.
    %
    % The constructor loads radarsimc and allocates a backend receiver, so
    % these tests need the compiled library staged in src/+RadarSim. The
    % class skips itself when it is not, which keeps run_tests('unit')
    % working on a bare checkout.
    %
    % Scope is one receiver at a time: the parameters it stores, the noise
    % bandwidth it derives, the channels it registers and the backend
    % handle it owns. Simulation belongs to RadarSimulationTest.
    %
    % Only one Rx channel is ever added, which is what an unlicensed build
    % allows, so the tests pass with or without a license.
    %
    % radarsimc is never unloaded once a receiver has loaded it: that
    % tears the OpenMP runtime out from under the library. See
    % RadarSim.Radar.delete.

    properties (Constant)
        Fs = 2e6;               % Sampling frequency (Hz)
        RfGain = 20;            % RF gain (dB)
        LoadResistor = 500;     % Load resistor (Ohm)
        BasebandGain = 30;      % Baseband gain (dB)
    end

    methods (TestClassSetup)
        function requireCompiledLibrary(testCase)
            pkg_dir = testCase.packageDir();

            lib_files = dir(fullfile(pkg_dir, 'radarsimc.*'));
            lib_files = lib_files(~[lib_files.isdir]);
            testCase.assumeNotEmpty(lib_files, sprintf( ...
                ['No radarsimc shared library found in %s. These tests ' ...
                'build a real receiver, so they need the compiled ' ...
                'backend.'], pkg_dir));

            testCase.assumeTrue(isfile(fullfile(pkg_dir, 'radarsim.h')), ...
                sprintf('radarsim.h is missing from %s.', pkg_dir));
        end
    end

    methods (Test)

        % ---------------------------------------------------------------
        % Parameters
        % ---------------------------------------------------------------

        function constructorStoresItsParameters(testCase)
            rx = testCase.buildReceiver();

            testCase.verifyEqual(rx.fs_, testCase.Fs);
            testCase.verifyEqual(rx.rf_gain_, testCase.RfGain);
            testCase.verifyEqual(rx.load_resistor_, testCase.LoadResistor);
            testCase.verifyEqual(rx.baseband_gain_, testCase.BasebandGain);
        end

        function noiseFigureDefaultsToZero(testCase)
            rx = testCase.buildReceiver();

            testCase.verifyEqual(rx.noise_figure_, 0);
        end

        function noiseFigureIsPreserved(testCase)
            rx = testCase.buildReceiver('noise_figure', 12);

            testCase.verifyEqual(rx.noise_figure_, 12);
        end

        function versionIsReportedAsSemanticVersion(testCase)
            rx = testCase.buildReceiver();

            testCase.verifyMatches(rx.version_, '^\d+\.\d+\.\d+$');
        end

        % ---------------------------------------------------------------
        % Baseband type and noise bandwidth
        % ---------------------------------------------------------------

        function complexBasebandIsTheDefault(testCase)
            rx = testCase.buildReceiver();

            testCase.verifyEqual(rx.bb_type_, "complex");
        end

        function complexBasebandUsesTheFullSamplingRate(testCase)
            % A complex receiver keeps both sidebands, so its noise
            % bandwidth is the whole sampling rate.
            rx = testCase.buildReceiver();

            testCase.verifyEqual(rx.noise_bandwidth_, testCase.Fs);
        end

        function realBasebandHalvesTheNoiseBandwidth(testCase)
            rx = testCase.buildReceiver('bb_type', 'real');

            testCase.verifyEqual(rx.noise_bandwidth_, testCase.Fs / 2);
        end

        % ---------------------------------------------------------------
        % Range gate
        % ---------------------------------------------------------------

        function gateDelayDefaultsToZeroDelayDeramp(testCase)
            rx = testCase.buildReceiver();

            testCase.verifyEqual(rx.gate_delay_, 0);
        end

        function gateDelayIsPreserved(testCase)
            rx = testCase.buildReceiver('gate_delay', 4e-7);

            testCase.verifyEqual(rx.gate_delay_, 4e-7);
        end

        function negativeGateDelayIsRejected(testCase)
            % gate_delay opens the receive window after the chirp starts,
            % so a negative value has no meaning.
            testCase.verifyError(@() RadarSim.Receiver(testCase.Fs, ...
                testCase.RfGain, testCase.LoadResistor, ...
                testCase.BasebandGain, 'gate_delay', -1e-7), ?MException);
        end

        function nonScalarGateDelayIsRejected(testCase)
            testCase.verifyError(@() RadarSim.Receiver(testCase.Fs, ...
                testCase.RfGain, testCase.LoadResistor, ...
                testCase.BasebandGain, 'gate_delay', [0, 1e-7]), ?MException);
        end

        % ---------------------------------------------------------------
        % Channels
        % ---------------------------------------------------------------

        function receiverStartsWithoutChannels(testCase)
            rx = testCase.buildReceiver();

            testCase.verifyEmpty(rx.channels_);
        end

        function constructorRegistersTheChannelsItIsGiven(testCase)
            rx = testCase.buildReceiver('channels', {RadarSim.RxChannel([0, 0, 0])});

            testCase.verifyNumElements(rx.channels_, 1);
        end

        function addRxchannelAppendsToTheChannelList(testCase)
            rx = testCase.buildReceiver();

            rx.add_rxchannel(RadarSim.RxChannel([0, 0, 0]));

            testCase.verifyNumElements(rx.channels_, 1);
        end

        function addRxchannelRejectsABareNumber(testCase)
            % add_rxchannel declares its argument as RadarSim.RxChannel,
            % and an arguments block converts what it can, so this only
            % holds because RxChannel refuses to read a scalar as a
            % location. The identifier is whatever the conversion failure
            % is wrapped in, so only the failure itself is asserted.
            rx = testCase.buildReceiver();

            testCase.verifyError(@() rx.add_rxchannel(42), ?MException);
        end

        % ---------------------------------------------------------------
        % Backend handle
        % ---------------------------------------------------------------

        function constructorAllocatesABackendReceiver(testCase)
            rx = testCase.buildReceiver();

            testCase.verifyNotEqual(rx.rx_ptr, 0, ...
                'Create_Receiver should return a non-null handle.');
        end

        function resetReleasesTheBackendReceiver(testCase)
            rx = testCase.buildReceiver('channels', {RadarSim.RxChannel([0, 0, 0])});

            rx.reset();

            testCase.verifyEqual(rx.rx_ptr, 0);
            testCase.verifyEmpty(rx.channels_);
        end

        function resetIsIdempotent(testCase)
            % Teardown resets every receiver these tests build, so a
            % second reset has to be harmless.
            rx = testCase.buildReceiver();

            rx.reset();

            testCase.verifyWarningFree(@() rx.reset());
            testCase.verifyEqual(rx.rx_ptr, 0);
        end

    end

    methods (Access = private)

        % Builds a receiver with the shared parameters and registers the
        % teardown that frees its backend resources.
        function rx = buildReceiver(testCase, varargin)
            rx = RadarSim.Receiver(testCase.Fs, testCase.RfGain, ...
                testCase.LoadResistor, testCase.BasebandGain, varargin{:});
            testCase.addTeardown(@() rx.reset());
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
