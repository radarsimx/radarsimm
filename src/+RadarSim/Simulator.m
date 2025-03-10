% ----------
% RadarSimM - Radar Simulator for MATLAB
% Copyright (C) 2023 - PRESENT  radarsimx.com
% E-mail: info@radarsimx.com
% Website: https://radarsimx.com
%
% ██████╗  █████╗ ██████╗  █████╗ ██████╗ ███████╗██╗███╗   ███╗██╗  ██╗
% ██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔════╝██║████╗ ████║╚██╗██╔╝
% ██████╔╝███████║██║  ██║███████║██████╔╝███████╗██║██╔████╔██║ ╚███╔╝
% ██╔══██╗██╔══██║██║  ██║██╔══██║██╔══██╗╚════██║██║██║╚██╔╝██║ ██╔██╗
% ██║  ██║██║  ██║██████╔╝██║  ██║██║  ██║███████║██║██║ ╚═╝ ██║██╔╝ ██╗
% ╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝╚═╝     ╚═╝╚═╝  ╚═╝


classdef Simulator < handle
    properties (Access = public)
        version_ = '';
        baseband_;
        noise_;
        timestamp_;
        interference_;

        targets_ptr=0;
    end

    methods (Access = public)
        % Constructor for the Simulator class.
        % Loads the 'radarsimc' library if not already loaded and retrieves the version.
        function obj = Simulator()
            if ~libisloaded('radarsimc')
                loadlibrary('radarsimc','radarsim.h');
                version_ptr = libpointer("int32Ptr", zeros(1, 2));

                calllib('radarsimc', 'Get_Version', version_ptr);
                obj.version_ = [num2str(version_ptr.Value(1)), '.', num2str(version_ptr.Value(2))];

                % error("ERROR! radarsimc library has already loaded into the memory.")
            else
                version_ptr = libpointer("int32Ptr", zeros(1, 2));

                calllib('radarsimc', 'Get_Version', version_ptr);
                obj.version_ = [num2str(version_ptr.Value(1)), '.', num2str(version_ptr.Value(2))];
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

            calllib('radarsimc','Run_Simulator',radar.radar_ptr, obj.targets_ptr, level, kwargs.density, ray_filter, bb_real, bb_imag);
            obj.baseband_=reshape(bb_real.Value+1i*bb_imag.Value, radar.samples_per_pulse_, radar.tx_.pulses_, radar.num_tx_*radar.num_rx_*radar.num_frame_);

            obj.timestamp_ = radar.timestamp_;

            if kwargs.noise
                obj.noise_ = obj.generate_noise(radar);
            end

            if ~isempty(kwargs.interf)
                interf_real = libpointer("doublePtr",zeros(radar.samples_per_pulse_, radar.tx_.pulses_, radar.num_tx_*radar.num_rx_*radar.num_frame_));
                interf_imag = libpointer("doublePtr",zeros(radar.samples_per_pulse_, radar.tx_.pulses_, radar.num_tx_*radar.num_rx_*radar.num_frame_));
                
                calllib('radarsimc','Run_Interference',radar.radar_ptr, kwargs.interf.radar_ptr, interf_real, interf_imag);

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
                error("RadarSim:FreeTier", "Error: \nYou're currently using RadarSimM's FreeTier, " + ...
                    "which imposes a restriction on the maximum number of point targets to 1. " + ...
                    "Please consider supporting my work by upgrading to the standard version. Just choose " + ...
                    "any amount greater than zero on https://radarsimx.com/product/radarsimm/ to access the " + ...
                    "standard version download links. Your support will help improve the software. " + ...
                    "Thank you for considering it.");
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
                target.is_ground_, ...
                obj.targets_ptr);

            if status
                error("RadarSim:FreeTier", "Error: \nYou're currently using RadarSimM's FreeTier, " + ...
                    "which imposes a restriction on the maximum number of mesh targets to 1 and the maximum number " + ...
                    "of meshes to 32. Please consider supporting my work by upgrading to the standard version. " + ...
                    "Just choose any amount greater than zero on https://radarsimx.com/product/radarsimm/ to access the " + ...
                    "standard version download links. Your support will help improve the software. " + ...
                    "Thank you for considering it.");
            end

        end

        % Generates noise for the radar simulation.
        %
        % Parameters:
        %   radar (RadarSim.Radar): The radar object.
        %
        % Returns:
        %   noise_mat (double): The generated noise matrix.
        function noise_mat = generate_noise(obj, radar)
            boltzmann_const = 1.38064852e-23;
            Ts = 290;
            input_noise_dbm = 10 * log10(boltzmann_const * Ts * 1000);  % dBm/Hz
            receiver_noise_dbm = (input_noise_dbm+ ...
                radar.rx_.rf_gain_+ ...
                radar.rx_.noise_figure_+ ...
                10 * log10(radar.rx_.noise_bandwidth_)+ ...
                radar.rx_.baseband_gain_);  % dBm/Hz
            receiver_noise_watts = 1e-3 * 10^(receiver_noise_dbm / 10);  % Watts/sqrt(hz)
            noise_amplitude_mixer = sqrt(receiver_noise_watts * radar.rx_.load_resistor_);
            % noise_amplitude_peak = noise_amplitude_mixer;

            min_time = min(obj.timestamp_,[],"all");
            num_noise_samples = ceil((max(obj.timestamp_,[],"all")-min_time)*radar.rx_.fs_)+1;
            noise_mat = zeros(size(obj.baseband_));

            [s1, s2, s3] = size(obj.baseband_);

            
            if strcmp(radar.rx_.bb_type_, "real")
                noise_per_rx = noise_amplitude_mixer*(randn(radar.num_rx_, num_noise_samples));
                
            else
                noise_per_rx = noise_amplitude_mixer/sqrt(2)*(randn(radar.num_rx_, num_noise_samples));

            end

            for ch_idx=1:s3
                for ps_idx=1:s2
                    t0=floor((obj.timestamp_(1,ps_idx,ch_idx)-min_time)*radar.rx_.fs_)+1;
                    rx_ch = mod(ch_idx-1, radar.num_rx_)+1;
                    noise_mat(:, ps_idx, ch_idx) = noise_per_rx(rx_ch, t0:(t0+s1-1));
                end
            end

        end

        % Resets the simulation by freeing targets.
        function reset(obj)
            if obj.targets_ptr~=0
                calllib('radarsimc','Free_Targets',obj.targets_ptr);
            end
            obj.targets_ptr=0;
        end

        % Destructor for the Simulator class.
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