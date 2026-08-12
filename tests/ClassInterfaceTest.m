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


classdef ClassInterfaceTest < matlab.unittest.TestCase
    % ClassInterfaceTest Public API checks for the RadarSim package.
    %
    % Transmitter, Receiver, Radar and RadarSimulator load the radarsimc
    % shared library in their constructors, so they cannot be instantiated
    % without the compiled backend. These tests inspect their class
    % metadata instead, which still catches syntax errors, renamed or
    % removed properties, and accidentally hidden methods.

    methods (Test)

        function allPackageClassesResolve(testCase)
            for name = testCase.classNames()
                mc = meta.class.fromName(char(name));
                testCase.verifyNotEmpty(mc, ...
                    sprintf('%s could not be resolved. Is src on the path?', name));
            end
        end

        function transmitterExposesItsApi(testCase)
            testCase.verifyClassApi('RadarSim.Transmitter', ...
                {'version_', 'f_', 't_', 'power_', 'pulses_', 'pulse_duration_', ...
                'prp_', 'pulse_start_time_', 'f_offset_', 'tx_ptr', 'channels_', ...
                'delay_'}, ...
                {'Transmitter', 'add_txchannel', 'reset', 'delete'});
        end

        function receiverExposesItsApi(testCase)
            testCase.verifyClassApi('RadarSim.Receiver', ...
                {'version_', 'fs_', 'noise_figure_', 'rf_gain_', 'baseband_gain_', ...
                'load_resistor_', 'noise_bandwidth_', 'bb_type_', 'channels_', ...
                'rx_ptr'}, ...
                {'Receiver', 'add_rxchannel', 'reset', 'delete'});
        end

        function radarExposesItsApi(testCase)
            testCase.verifyClassApi('RadarSim.Radar', ...
                {'version_', 'tx_', 'rx_', 'num_tx_', 'num_rx_', 'num_frame_', ...
                'frame_start_time_', 'samples_per_pulse_', 'timestamp_', 'radar_ptr'}, ...
                {'Radar', 'get_radar_state', 'reset', 'delete'});
        end

        function radarSimulatorExposesItsApi(testCase)
            testCase.verifyClassApi('RadarSim.RadarSimulator', ...
                {'version_', 'baseband_', 'noise_', 'timestamp_', 'interference_', ...
                'targets_ptr'}, ...
                {'RadarSimulator', 'Run', 'add_point_target', 'add_mesh_target', ...
                'get_num_mesh_targets', 'get_target_mesh_size', ...
                'get_target_mesh_state', 'generate_noise', 'reset', 'delete'});
        end

        function txChannelExposesItsApi(testCase)
            testCase.verifyClassApi('RadarSim.TxChannel', ...
                {'location_', 'polarization_', 'delay_', 'phi_', 'phi_ptn_', ...
                'theta_', 'theta_ptn_', 'antenna_gain_', 'pulse_mod_', 'mod_t_', ...
                'mod_var_'}, ...
                {'TxChannel'});
        end

        function rxChannelExposesItsApi(testCase)
            testCase.verifyClassApi('RadarSim.RxChannel', ...
                {'location_', 'polarization_', 'phi_', 'phi_ptn_', 'theta_', ...
                'theta_ptn_', 'antenna_gain_'}, ...
                {'RxChannel'});
        end

        function pointTargetExposesItsApi(testCase)
            testCase.verifyClassApi('RadarSim.PointTarget', ...
                {'type_', 'location_', 'rcs_', 'speed_', 'phase_'}, ...
                {'PointTarget'});
        end

        function meshTargetExposesItsApi(testCase)
            testCase.verifyClassApi('RadarSim.MeshTarget', ...
                {'type_', 'points_', 'connectivity_list_', 'location_', 'speed_', ...
                'rotation_', 'rotation_rate_', 'origin_', 'permittivity_', ...
                'skip_diffusion_', 'density_', 'environment_'}, ...
                {'MeshTarget'});
        end

        function simulationClassesAreHandles(testCase)
            handle_classes = ["RadarSim.Transmitter", "RadarSim.Receiver", ...
                "RadarSim.Radar", "RadarSim.RadarSimulator", ...
                "RadarSim.TxChannel", "RadarSim.RxChannel", ...
                "RadarSim.PointTarget", "RadarSim.MeshTarget"];

            for name = handle_classes
                mc = meta.class.fromName(char(name));
                testCase.assertNotEmpty(mc, sprintf('%s was not found.', name));
                testCase.verifyTrue(mc.HandleCompatible, ...
                    sprintf('%s is expected to be a handle class.', name));
            end
        end

        function packageContainsOnlyDocumentedClasses(testCase)
            % Every class shipped in +RadarSim should have a matching page
            % under docs/ so the published API reference stays complete.
            repo_root = fileparts(fileparts(mfilename('fullpath')));

            for name = testCase.classNames()
                short_name = extractAfter(name, "RadarSim.");
                doc_file = fullfile(repo_root, 'docs', sprintf('%s.md', short_name));
                testCase.verifyTrue(isfile(doc_file), ...
                    sprintf('Missing documentation page docs/%s.md', short_name));
            end
        end

    end

    methods (Access = private)

        function names = classNames(~)
            names = ["RadarSim.Transmitter", "RadarSim.Receiver", ...
                "RadarSim.Radar", "RadarSim.RadarSimulator", ...
                "RadarSim.TxChannel", "RadarSim.RxChannel", ...
                "RadarSim.PointTarget", "RadarSim.MeshTarget", ...
                "RadarSim.License"];
        end

        % Verifies that a class exists and publicly exposes the given
        % properties and methods.
        function verifyClassApi(testCase, class_name, expected_properties, expected_methods)
            mc = meta.class.fromName(class_name);
            testCase.assertNotEmpty(mc, sprintf('%s was not found.', class_name));

            public_properties = {mc.PropertyList( ...
                strcmp({mc.PropertyList.GetAccess}, 'public')).Name};
            for k = 1:numel(expected_properties)
                testCase.verifyTrue( ...
                    any(strcmp(public_properties, expected_properties{k})), ...
                    sprintf('%s.%s is missing or not public.', ...
                    class_name, expected_properties{k}));
            end

            public_methods = {mc.MethodList( ...
                strcmp({mc.MethodList.Access}, 'public')).Name};
            for k = 1:numel(expected_methods)
                testCase.verifyTrue( ...
                    any(strcmp(public_methods, expected_methods{k})), ...
                    sprintf('%s.%s is missing or not public.', ...
                    class_name, expected_methods{k}));
            end
        end

    end
end
