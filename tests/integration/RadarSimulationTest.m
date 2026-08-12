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


classdef RadarSimulationTest < matlab.unittest.TestCase
    % RadarSimulationTest End-to-end tests against the compiled backend.
    %
    % These tests require radarsimc (radarsimc.so / radarsimc.dll) and
    % radarsim.h to be present in src/+RadarSim, which is what the build
    % step of the CI workflow produces. They fail loudly when the library
    % is missing rather than being silently skipped.
    %
    % The scenarios stay within the limits of an unlicensed build (one Tx
    % channel, one Rx channel, at most two point targets, and meshes of at
    % most eight triangles) so they pass against any build of the backend.

    properties (Constant)
        F = [24.075e9, 24.175e9];   % Chirp start/stop frequency (Hz)
        T = 80e-6;                  % Chirp duration (s)
        Fs = 2e6;                   % Sampling frequency (Hz)
        Prp = 100e-6;               % Pulse repetition period (s)
        Pulses = 4;
        C = 299792458;              % Speed of light (m/s)
    end

    methods (TestClassSetup)
        function requireCompiledLibrary(testCase)
            pkg_dir = testCase.packageDir();

            testCase.assertTrue(isfile(fullfile(pkg_dir, 'radarsim.h')), ...
                sprintf(['radarsim.h is missing from %s. Build the ' ...
                'radarsimc library before running the integration tests.'], ...
                pkg_dir));

            lib_files = dir(fullfile(pkg_dir, 'radarsimc.*'));
            lib_files = lib_files(~[lib_files.isdir]);
            testCase.assertNotEmpty(lib_files, ...
                sprintf(['No radarsimc shared library found in %s. Build ' ...
                'the radarsimc library before running the integration ' ...
                'tests.'], pkg_dir));
        end
    end

    methods (TestClassTeardown)
        function unloadCompiledLibrary(~)
            % Leave the process without the library loaded so unit tests
            % that describe the "library not loaded" behavior still apply,
            % whatever order the suite runs in.
            if libisloaded('radarsimc')
                try
                    unloadlibrary('radarsimc');
                catch
                end
            end
        end
    end

    methods (Test)

        % ---------------------------------------------------------------
        % Radar assembly
        % ---------------------------------------------------------------

        function radarReportsItsGeometry(testCase)
            radar = testCase.buildRadar();

            testCase.verifyEqual(double(radar.num_tx_), 1);
            testCase.verifyEqual(double(radar.num_rx_), 1);
            testCase.verifyEqual(radar.num_frame_, 1);
            testCase.verifyEqual(radar.samples_per_pulse_, ...
                floor(testCase.T * testCase.Fs));
        end

        function backendReportsAVersion(testCase)
            radar = testCase.buildRadar();

            testCase.verifyMatches(radar.version_, '^\d+\.\d+\.\d+$');
            testCase.verifyEqual(radar.tx_.version_, radar.version_);
            testCase.verifyEqual(radar.rx_.version_, radar.version_);
        end

        function timestampsFollowSamplingRateAndPrp(testCase)
            radar = testCase.buildRadar();
            timestamp = radar.timestamp_;

            testCase.verifySize(timestamp, ...
                [radar.samples_per_pulse_, double(testCase.Pulses)]);
            testCase.verifyEqual(timestamp(1, 1), 0, 'AbsTol', 1e-15);
            testCase.verifyEqual(timestamp(2, 1) - timestamp(1, 1), ...
                1 / testCase.Fs, 'AbsTol', 1e-15);
            testCase.verifyEqual(timestamp(1, 2) - timestamp(1, 1), ...
                testCase.Prp, 'AbsTol', 1e-12);
        end

        function radarStateReportsChannelPositions(testCase)
            radar = testCase.buildRadar();

            state = radar.get_radar_state(0);

            testCase.verifySize(state.tx_locations, [3, 1]);
            testCase.verifySize(state.rx_locations, [3, 1]);
            testCase.verifySize(state.radar_boresight, [3, 1]);
            testCase.verifyEqual(double(state.tx_locations(:)), [0; 0; 0], ...
                'AbsTol', 1e-5);
            testCase.verifyEqual(double(state.rx_locations(:)), [0; 0; 0], ...
                'AbsTol', 1e-5);
        end

        % ---------------------------------------------------------------
        % Point target simulation
        % ---------------------------------------------------------------

        function basebandHasExpectedShape(testCase)
            radar = testCase.buildRadar();
            targets = {RadarSim.PointTarget([60, 0, 0], [0, 0, 0], 20)};

            simc = testCase.runSimulation(radar, targets, 'noise', false);

            testCase.verifySize(simc.baseband_, ...
                [radar.samples_per_pulse_, double(testCase.Pulses)]);
            testCase.verifyTrue(all(isfinite(simc.baseband_(:))), ...
                'The baseband must not contain NaN or Inf samples.');
            testCase.verifyGreaterThan(max(abs(simc.baseband_(:))), 0, ...
                'The baseband of an illuminated target must not be all zeros.');
            testCase.verifyFalse(isreal(simc.baseband_), ...
                'A complex receiver must produce complex baseband data.');
        end

        function simulatorCopiesRadarTimestamps(testCase)
            radar = testCase.buildRadar();
            targets = {RadarSim.PointTarget([60, 0, 0], [0, 0, 0], 20)};

            simc = testCase.runSimulation(radar, targets, 'noise', false);

            testCase.verifyEqual(simc.timestamp_, radar.timestamp_);
        end

        function rangeProfilePeakMatchesTargetRange(testCase)
            target_range = 60;
            radar = testCase.buildRadar();
            targets = {RadarSim.PointTarget([target_range, 0, 0], [0, 0, 0], 20)};

            simc = testCase.runSimulation(radar, targets, 'noise', false);

            spectrum = abs(fft(simc.baseband_(:, 1)));
            [~, peak_bin] = max(spectrum);

            testCase.verifyEqual(peak_bin, testCase.rangeBin(target_range, radar), ...
                'AbsTol', 1, ...
                'The range FFT peak does not line up with the target range.');
        end

        function twoTargetsProduceTwoRangePeaks(testCase)
            near_range = 30;
            far_range = 90;
            radar = testCase.buildRadar();
            targets = { ...
                RadarSim.PointTarget([near_range, 0, 0], [0, 0, 0], 20), ...
                RadarSim.PointTarget([far_range, 0, 0], [0, 0, 0], 20)};

            simc = testCase.runSimulation(radar, targets, 'noise', false);

            % Window the pulse so the strong near-range return does not
            % leak over the weaker far-range one.
            window = testCase.hannWindow(radar.samples_per_pulse_);
            spectrum = abs(fft(simc.baseband_(:, 1) .* window));
            noise_floor = median(spectrum);

            for target_range = [near_range, far_range]
                bin = testCase.rangeBin(target_range, radar);
                peak = max(spectrum(bin - 1:bin + 1));
                testCase.verifyGreaterThan(peak, 10 * noise_floor, ...
                    sprintf('No range peak found for the target at %d m.', ...
                    target_range));
            end
        end

        function movingTargetChangesTheBasebandBetweenPulses(testCase)
            radar = testCase.buildRadar();
            targets = {RadarSim.PointTarget([60, 0, 0], [-50, 0, 0], 20)};

            simc = testCase.runSimulation(radar, targets, 'noise', false);

            first_pulse = simc.baseband_(:, 1);
            last_pulse = simc.baseband_(:, end);
            testCase.verifyGreaterThan(max(abs(first_pulse - last_pulse)), 0, ...
                'A moving target must produce pulse-to-pulse variation.');
        end

        % ---------------------------------------------------------------
        % Receiver options
        % ---------------------------------------------------------------

        function noiseIsGeneratedOnRequest(testCase)
            radar = testCase.buildRadar();
            targets = {RadarSim.PointTarget([60, 0, 0], [0, 0, 0], 20)};

            simc = testCase.runSimulation(radar, targets, 'noise', true);

            testCase.verifySize(simc.noise_, size(simc.baseband_));
            testCase.verifyTrue(all(isfinite(simc.noise_(:))));
            testCase.verifyGreaterThan(max(abs(simc.noise_(:))), 0, ...
                'Requesting noise must produce a non-zero noise matrix.');
        end

        function noiseIsSkippedWhenNotRequested(testCase)
            radar = testCase.buildRadar();
            targets = {RadarSim.PointTarget([60, 0, 0], [0, 0, 0], 20)};

            simc = testCase.runSimulation(radar, targets, 'noise', false);

            testCase.verifyEmpty(simc.noise_);
        end

        function realBasebandTypeProducesRealSamples(testCase)
            radar = testCase.buildRadar('real');
            targets = {RadarSim.PointTarget([60, 0, 0], [0, 0, 0], 20)};

            testCase.verifyEqual(radar.rx_.noise_bandwidth_, testCase.Fs / 2);

            simc = testCase.runSimulation(radar, targets, 'noise', false);

            testCase.verifyTrue(isreal(simc.baseband_), ...
                'A real receiver must produce real baseband data.');
        end

        % ---------------------------------------------------------------
        % Mesh target simulation
        % ---------------------------------------------------------------

        function meshTargetIsRegisteredWithTheSimulator(testCase)
            radar = testCase.buildRadar();
            [points, connectivity] = testCase.plateMesh();
            targets = {RadarSim.MeshTarget(points, connectivity, ...
                [40, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0])};

            simc = testCase.runSimulation(radar, targets, 'noise', false);

            testCase.verifyEqual(double(simc.get_num_mesh_targets()), 1);
            testCase.verifyEqual(double(simc.get_target_mesh_size(1)), 2, ...
                'The plate is made of two triangles.');
        end

        function meshStateIsTranslatedToTheTargetLocation(testCase)
            plate_range = 40;
            radar = testCase.buildRadar();
            [points, connectivity] = testCase.plateMesh();
            targets = {RadarSim.MeshTarget(points, connectivity, ...
                [plate_range, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0])};

            simc = testCase.runSimulation(radar, targets, 'noise', false);

            state = simc.get_target_mesh_state(1, 0);

            testCase.verifySize(state, [3, 3, 2]);
            % Six vertices (three per triangle) sit at x = plate_range; the
            % remaining coordinates stay within the plate's half-width.
            at_range = abs(state(:) - plate_range) < 1e-3;
            testCase.verifyEqual(sum(at_range), 6, ...
                'Every vertex should be translated to the target location.');
            testCase.verifyLessThanOrEqual(max(abs(state(~at_range))), 0.5 + 1e-3);
        end

        function meshTargetProducesABasebandEcho(testCase)
            radar = testCase.buildRadar();
            [points, connectivity] = testCase.plateMesh();
            targets = {RadarSim.MeshTarget(points, connectivity, ...
                [40, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0])};

            simc = testCase.runSimulation(radar, targets, 'noise', false);

            testCase.verifySize(simc.baseband_, ...
                [radar.samples_per_pulse_, double(testCase.Pulses)]);
            testCase.verifyTrue(all(isfinite(simc.baseband_(:))));
            testCase.verifyGreaterThan(max(abs(simc.baseband_(:))), 0, ...
                'A ray-traced plate must return a non-zero echo.');
        end

        function queryingMeshStateBeforeRunIsRejected(testCase)
            simc = RadarSim.RadarSimulator();
            testCase.addTeardown(@() simc.reset());

            testCase.verifyError(@() simc.get_num_mesh_targets(), ...
                'RadarSim:NoTargets');
            testCase.verifyError(@() simc.get_target_mesh_size(1), ...
                'RadarSim:NoTargets');
        end

        % ---------------------------------------------------------------
        % Interference
        % ---------------------------------------------------------------

        function interferingRadarProducesAnInterferenceMatrix(testCase)
            radar = testCase.buildRadar();
            interferer = testCase.buildRadar();
            targets = {RadarSim.PointTarget([60, 0, 0], [0, 0, 0], 20)};

            simc = testCase.runSimulation(radar, targets, ...
                'noise', false, 'interf', interferer);

            testCase.verifySize(simc.interference_, size(simc.baseband_));
            testCase.verifyTrue(all(isfinite(simc.interference_(:))));
        end

        % ---------------------------------------------------------------
        % License
        % ---------------------------------------------------------------

        function licenseInfoIsReadableOnceTheLibraryIsLoaded(testCase)
            testCase.buildRadar();

            info = RadarSim.License.get_info();

            testCase.verifyClass(info, 'string');
            testCase.verifySize(info, [1, 1]);
        end

    end

    methods (Access = private)

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

        % Builds a single-channel FMCW radar and registers the teardown
        % that frees the backend resources in the reverse order.
        function radar = buildRadar(testCase, bb_type)
            if nargin < 2
                bb_type = 'complex';
            end

            tx = RadarSim.Transmitter(testCase.F, testCase.T, ...
                'tx_power', 15, ...
                'prp', testCase.Prp, ...
                'pulses', testCase.Pulses, ...
                'channels', {RadarSim.TxChannel([0, 0, 0])});

            rx = RadarSim.Receiver(testCase.Fs, 20, 500, 30, ...
                'noise_figure', 12, ...
                'bb_type', bb_type, ...
                'channels', {RadarSim.RxChannel([0, 0, 0])});

            radar = RadarSim.Radar(tx, rx);

            % Teardown runs last-in-first-out, so the radar is released
            % before the transmitter and receiver it was built from.
            testCase.addTeardown(@() tx.reset());
            testCase.addTeardown(@() rx.reset());
            testCase.addTeardown(@() radar.reset());
        end

        function simc = runSimulation(testCase, radar, targets, varargin)
            simc = RadarSim.RadarSimulator();
            testCase.addTeardown(@() simc.reset());

            simc.Run(radar, targets, varargin{:});
        end

        % Returns the 1-based range FFT bin a stationary target at the
        % given range is expected to land in.
        function bin = rangeBin(testCase, target_range, radar)
            bandwidth = abs(testCase.F(2) - testCase.F(1));
            max_range = testCase.C * testCase.Fs * testCase.T / bandwidth / 2;
            bin_width = max_range / radar.samples_per_pulse_;

            bin = round(target_range / bin_width) + 1;
        end

        % A 1 m x 1 m plate in the y-z plane, made of two triangles whose
        % winding puts the surface normal along -x, facing a radar that
        % sits at the origin looking down +x.
        function [points, connectivity] = plateMesh(~)
            points = [0, -0.5, -0.5; ...
                0, 0.5, -0.5; ...
                0, 0.5, 0.5; ...
                0, -0.5, 0.5];
            connectivity = int32([1, 3, 2; 1, 4, 3]);
        end

        % Hann window, hand-rolled so the tests do not depend on the
        % Signal Processing Toolbox.
        function window = hannWindow(~, n)
            window = 0.5 - 0.5 * cos(2 * pi * (0:n - 1).' / (n - 1));
        end

    end
end
