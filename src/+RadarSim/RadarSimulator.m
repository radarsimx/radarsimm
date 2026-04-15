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


classdef RadarSimulator < handle
    properties (Access = public)
        version_ = '';
        baseband_;
        noise_;
        timestamp_;
        interference_;

        targets_ptr=0;
    end

    methods (Access = public)
        % Constructor for the RadarSimulator class.
        % Loads the 'radarsimc' library if not already loaded and retrieves the version.
        function obj = RadarSimulator()
            if ~libisloaded('radarsimc')
                pkg_dir = fileparts(mfilename('fullpath'));
                loadlibrary(fullfile(pkg_dir, 'radarsimc'), fullfile(pkg_dir, 'radarsim.h'));

                % Activate license using License class
                RadarSim.License.set_license();

                version_ptr = libpointer("int32Ptr", zeros(1, 3));

                calllib('radarsimc', 'Get_Version', version_ptr);
                obj.version_ = [num2str(version_ptr.Value(1)), '.', num2str(version_ptr.Value(2)), '.', num2str(version_ptr.Value(3))];
            else
                version_ptr = libpointer("int32Ptr", zeros(1, 3));

                calllib('radarsimc', 'Get_Version', version_ptr);
                obj.version_ = [num2str(version_ptr.Value(1)), '.', num2str(version_ptr.Value(2)), '.', num2str(version_ptr.Value(3))];
            end
        end

        % Runs the radar simulation.
        % 
        % Parameters:
        %   radar (RadarSim.Radar): The radar object.
        %   targets (cell): List of target objects.
        %   kwargs.density (double): Density (default: 1).
        %   kwargs.level (char): Level ('frame', 'pulse', 'sample') (default: 'frame').
        %   kwargs.noise (logical): Noise flag (default: true).
        %   kwargs.ray_filter (1,2 double): Ray filter (default: [0, 10]).
        %   kwargs.interf (struct): Interference (default: []).
        function Run(obj, radar, targets, kwargs)
            arguments
                obj
                radar RadarSim.Radar
                targets
                kwargs.density=1
                kwargs.level='frame' % 'frame', 'pulse', 'sample'
                kwargs.noise=true
                kwargs.ray_filter=[0, 10]
                kwargs.interf=[]
                kwargs.noise_seed uint64 = 0
            end

            obj.targets_ptr = calllib('radarsimc', 'Init_Targets');
            for t_idx=1:length(targets)
                if strcmp(targets{t_idx}.type_, 'point')
                    obj.add_point_target(targets{t_idx});
                elseif strcmp(targets{t_idx}.type_, 'mesh')
                    obj.add_mesh_target(targets{t_idx});
                end
            end

            ray_filter = libpointer("int32Ptr",kwargs.ray_filter);

            bb_real = libpointer("doublePtr",zeros(radar.samples_per_pulse_, radar.tx_.pulses_, radar.num_tx_*radar.num_rx_*radar.num_frame_));
            bb_imag = libpointer("doublePtr",zeros(radar.samples_per_pulse_, radar.tx_.pulses_, radar.num_tx_*radar.num_rx_*radar.num_frame_));

            if strcmp(kwargs.level, 'frame')
                level = 0;
            elseif strcmp(kwargs.level, 'pulse')
                level = 1;
            elseif strcmp(kwargs.level, 'sample')
                level = 2;
            else
                error("ERROR! Unknow level.");
            end

            calllib('radarsimc','Run_RadarSimulator',radar.radar_ptr, obj.targets_ptr, level, kwargs.density, ray_filter, bb_real, bb_imag);
            obj.baseband_=reshape(bb_real.Value+1i*bb_imag.Value, radar.samples_per_pulse_, radar.tx_.pulses_, radar.num_tx_*radar.num_rx_*radar.num_frame_);

            obj.timestamp_ = radar.timestamp_;

            if kwargs.noise
                obj.noise_ = obj.generate_noise(radar, kwargs.noise_seed);
            end

            if ~isempty(kwargs.interf)
                interf_real = libpointer("doublePtr",zeros(radar.samples_per_pulse_, radar.tx_.pulses_, radar.num_tx_*radar.num_rx_*radar.num_frame_));
                interf_imag = libpointer("doublePtr",zeros(radar.samples_per_pulse_, radar.tx_.pulses_, radar.num_tx_*radar.num_rx_*radar.num_frame_));
                
                status = calllib('radarsimc','Run_InterferenceSimulator',radar.radar_ptr, kwargs.interf.radar_ptr, interf_real, interf_imag);
                if status ~= 0
                    error('RadarSim:InterferenceSimulator', 'Interference simulation failed with error code %d', status);
                end

                obj.interference_=reshape(interf_real.Value+1i*interf_imag.Value, radar.samples_per_pulse_, radar.tx_.pulses_, radar.num_tx_*radar.num_rx_*radar.num_frame_);
            end

            if strcmp(radar.rx_.bb_type_, "real")
                obj.baseband_ = real(obj.baseband_);
                % obj.noise_ = real(obj.noise_);
                obj.interference_ = real(obj.interference_);
            end
        end

        % Adds a point target to the simulation.
        %
        % Parameters:
        %   target (RadarSim.PointTarget): The point target object.
        function add_point_target(obj, target)
            arguments
                obj
                target RadarSim.PointTarget
            end

            location_ptr = libpointer("singlePtr",target.location_);
            speed_ptr = libpointer("singlePtr",target.speed_);
            status = calllib('radarsimc', 'Add_Point_Target', location_ptr, speed_ptr, target.rcs_, target.phase_, obj.targets_ptr);

            if status
                error("RadarSim:Unlicensed", "Error: \nYou're currently using RadarSimM's unlicensed version, " + ...
                    "which limits the maximum number of point targets to 2. " + ...
                    "Please consider upgrading to the licensed version at https://radarsimx.com/product/radarsimm/.");
            end
        end

        % Adds a mesh target to the simulation.
        %
        % Parameters:
        %   target (RadarSim.MeshTarget): The mesh target object.
        function add_mesh_target(obj, target)
            arguments
                obj
                target RadarSim.MeshTarget
            end

            points_ptr = libpointer("singlePtr", target.points_.');
            connectivity_list_ptr = libpointer("int32Ptr", (target.connectivity_list_.'-1));
            [row,~] = size(target.connectivity_list_);

            origin_ptr = libpointer("singlePtr", target.origin_);
            location_ptr = libpointer("singlePtr", target.location_);
            speed_ptr = libpointer("singlePtr", target.speed_);
            rotation_ptr = libpointer("singlePtr", target.rotation_);
            rotation_rate_ptr = libpointer("singlePtr", target.rotation_rate_);

            if strcmp(target.permittivity_, 'PEC')
                ep_real = -1;
                ep_imag = 0;
                mu_real = 1;
                mu_imag = 0;
            else
                ep_real = real(target.permittivity_);
                ep_imag = imag(target.permittivity_);
                mu_real = 1;
                mu_imag = 0;
            end

            status = calllib('radarsimc', 'Add_Mesh_Target', ...
                points_ptr, ...
                connectivity_list_ptr, ...
                row, ...
                origin_ptr, ...
                location_ptr, ...
                speed_ptr, ...
                rotation_ptr, ...
                rotation_rate_ptr, ...
                ep_real, ...
                ep_imag, ...
                mu_real, ...
                mu_imag, ...
                target.skip_diffusion_, ...
                target.density_, ...
                target.environment_, ...
                obj.targets_ptr);

            if status
                error("RadarSim:Unlicensed", "Error: \nYou're currently using RadarSimM's unlicensed version, " + ...
                    "which limits the maximum number of mesh targets to 2 and the maximum number " + ...
                    "of triangles per mesh to 8. " + ...
                    "Please consider upgrading to the licensed version at https://radarsimx.com/product/radarsimm/.");
            end

        end

        % Generates noise for the radar simulation.
        %
        % Parameters:
        %   radar (RadarSim.Radar): The radar object.
        %
        % Returns:
        %   noise_mat (double): The generated noise matrix.
        function noise_mat = generate_noise(obj, radar, seed)
            arguments
                obj
                radar RadarSim.Radar
                seed uint64 = 0
            end

            boltzmann_const = 1.38064852e-23;
            Ts = 290;
            input_noise_dbm = 10 * log10(boltzmann_const * Ts * 1000);  % dBm/Hz
            receiver_noise_dbm = (input_noise_dbm + ...
                radar.rx_.rf_gain_ + ...
                radar.rx_.noise_figure_ + ...
                10 * log10(radar.rx_.noise_bandwidth_) + ...
                radar.rx_.baseband_gain_);  % dBm/Hz
            receiver_noise_watts = 1e-3 * 10^(receiver_noise_dbm / 10);
            noise_amplitude_mixer = sqrt(receiver_noise_watts * radar.rx_.load_resistor_);

            is_complex = strcmp(radar.rx_.bb_type_, "complex");

            ts_channel_size = int32(radar.num_tx_ * radar.num_rx_);
            ts_pulse_size = int32(radar.tx_.pulses_);
            ts_sample_size = int32(radar.samples_per_pulse_);

            % Use only the first frame's timestamps
            ts = radar.timestamp_(:, :, 1:double(ts_channel_size));
            ts_ptr = libpointer("doublePtr", ts);

            total_size = radar.num_frame_ * double(ts_channel_size) * double(ts_pulse_size) * double(ts_sample_size);
            noise_real_ptr = libpointer("doublePtr", zeros(1, total_size));
            noise_imag_ptr = libpointer("doublePtr", zeros(1, total_size));

            status = calllib('radarsimc', 'Run_NoiseSimulator', ...
                radar.radar_ptr, noise_amplitude_mixer, is_complex, ...
                ts_ptr, ts_channel_size, ts_pulse_size, ts_sample_size, ...
                noise_real_ptr, noise_imag_ptr, seed);

            if status ~= 0
                error('RadarSim:NoiseSimulator', 'Noise simulation failed with error code %d', status);
            end

            if is_complex
                noise_mat = reshape(noise_real_ptr.Value + 1i * noise_imag_ptr.Value, ...
                    radar.samples_per_pulse_, radar.tx_.pulses_, ...
                    radar.num_tx_ * radar.num_rx_ * radar.num_frame_);
            else
                noise_mat = reshape(noise_real_ptr.Value, ...
                    radar.samples_per_pulse_, radar.tx_.pulses_, ...
                    radar.num_tx_ * radar.num_rx_ * radar.num_frame_);
            end
        end

        % Resets the simulation by freeing targets.
        function reset(obj)
            if obj.targets_ptr~=0
                calllib('radarsimc','Free_Targets',obj.targets_ptr);
            end
            obj.targets_ptr=0;
        end

        % Destructor for the RadarSimulator class.
        % Frees targets and unloads the 'radarsimc' library if loaded.
        function delete(obj)
            obj.reset();
            if libisloaded('radarsimc')
                try
                    unloadlibrary radarsimc;
                catch exception
                    msg = exception.message;
                    % disp(msg);
                end
            end
        end
    end
end