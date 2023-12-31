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

classdef RadarSim < handle
    properties (Access = public)
        version_ = '';

        samples_;
        pulses_;

        baseband_;
        timestamp_;

        radar_loc=[0,0,0];
        radar_spd=[0,0,0];
        radar_rot=[0,0,0];
        radar_rrt=[0,0,0];
    end

    properties (Access = private)
        % c pointers
        tx_ptr=0;
        rx_ptr=0;
        radar_ptr=0;
        targets_ptr=0;

        % tx parameters
        tx_f_;
        tx_t_;
        tx_power_;
        tx_f_offset_;
        tx_delay_=[];
        tx_p_length_;
        tx_p_start_time_=0;
        tx_prp_;

        % rx parameters
        rx_rf_gain_=0;
        rx_noise_bandwidth_=0;
        rx_baseband_gain_=0;
        rx_load_resistor_=0;
        rx_noise_figure_;
        rx_fs_;        
        
    end

    methods (Access = public)

        % Construct app
        function obj = RadarSim()
            if ~libisloaded('radarsimc')
                loadlibrary('radarsimc','radarsim.h');
                version_ptr = libpointer("int32Ptr", zeros(1, 2));

                calllib('radarsimc', 'Get_Version', version_ptr);
                obj.version_ = [num2str(version_ptr.Value(1)), '.', num2str(version_ptr.Value(2))];

                % error("ERROR! radarsimc library has already loaded into the memory.")
            end
        end

        function init_transmitter(obj, f, t, kwargs)
            arguments
                obj
                f
                t
                kwargs.tx_power double = 0
                kwargs.pulses uint32 = 1
                kwargs.prp = NaN
                kwargs.f_offset = NaN
                kwargs.pn_f = NaN
                kwargs.pn_power = NaN
            end
            if obj.tx_ptr~=0
                error("ERROR! Transmitter has already been initialized.");
            end

            obj.tx_f_ = f;
            obj.tx_t_ = t;
            obj.tx_power_ = kwargs.tx_power;

            if length(obj.tx_f_) == 1
                obj.tx_f_ = [obj.tx_f_, obj.tx_f_];
            end

            if length(obj.tx_t_) == 1
                obj.tx_t_=[0, obj.tx_t_];
            end

            if length(obj.tx_t_)~=length(obj.tx_f_)
                error("ERROR! f and t must have the same length.");
            end

            f_ptr = libpointer("doublePtr",obj.tx_f_);
            t_ptr = libpointer("doublePtr",obj.tx_t_);

            obj.pulses_ = kwargs.pulses;
            obj.tx_p_length_ = obj.tx_t_(end)-obj.tx_t_(1);

            if isnan(kwargs.prp)
                obj.tx_prp_ = obj.tx_p_length_+zeros(1, obj.pulses_);
            elseif length(kwargs.prp)==1
                obj.tx_prp_ = kwargs.prp+zeros(1, obj.pulses_);
            else
                obj.tx_prp_ = kwargs.prp;
            end

            if length(obj.tx_prp_)<obj.pulses_
                error("ERROR! The length of prp must be the same of pulses.");
            end

            if any(obj.tx_prp_<obj.tx_p_length_)
                error("ERROR! prp can't be smaller than the pulse length.")
            end

            obj.tx_p_start_time_ = cumsum(obj.tx_prp_)-obj.tx_prp_(1);
            pulse_start_time_ptr = libpointer("doublePtr",obj.tx_p_start_time_);

            if isnan(kwargs.f_offset)
                obj.tx_f_offset_ = zeros(1, obj.pulses_);
            else
                obj.tx_f_offset_ = kwargs.f_offset;
            end

            if length(obj.tx_f_offset_) ~= obj.pulses_
                error("ERROR! The length of f_offset must be the same as pulses.");
            end

            f_offset_ptr = libpointer("doublePtr",obj.tx_f_offset_);

            frame_start_time_ptr = libpointer("doublePtr",0);

            obj.tx_ptr = calllib('radarsimc', 'Create_Transmitter', ...
                f_ptr, t_ptr, length(obj.tx_f_), ...
                f_offset_ptr, pulse_start_time_ptr, obj.pulses_, ...
                frame_start_time_ptr, 1, ...
                obj.tx_power_);

        end

        function add_txchannel(obj, location, kwargs)
            arguments
                obj
                location (1,3)
                kwargs.polarization (1,3) = [0,0,1]
                kwargs.delay = 0
                kwargs.azimuth_angle = [-90, 90]
                kwargs.azimuth_pattern = [0, 0]
                kwargs.elevation_angle = [-90, 90]
                kwargs.elevation_pattern = [0, 0]
                kwargs.pulse_amp = NaN
                kwargs.pulse_phs = NaN
                kwargs.mod_t = []
                kwargs.phs = []
                kwargs.amp = []
            end
            if obj.tx_ptr==0
                error("ERROR! Transmitter is not initialized.");
            end

            location_ptr=libpointer("singlePtr",location);
            polar_ptr=libpointer("singlePtr",kwargs.polarization);

            phi = kwargs.azimuth_angle/180*pi;
            phi_ptn = kwargs.azimuth_pattern-max(kwargs.azimuth_pattern);
            if length(phi)~=length(phi_ptn)
                error("ERROR! The length of azimuth_angle and azimuth_pattern must be the same.")
            end

            phi_ptr = libpointer("singlePtr",phi);
            phi_ptn_ptr = libpointer("singlePtr",phi_ptn);

            theta = flip(90-kwargs.elevation_angle)/180*pi;
            theta_ptn = flip(kwargs.elevation_pattern)-max(kwargs.elevation_pattern);
            if length(theta)~=length(theta)
                error("ERROR! The length of elevation_angle and elevation_pattern must be the same.")
            end

            theta_ptr = libpointer("singlePtr",theta);
            theta_ptn_ptr = libpointer("singlePtr",theta_ptn);

            antenna_gain = max(kwargs.azimuth_pattern);

            if isnan(kwargs.pulse_amp)
                pulse_amp=ones(1, obj.pulses_);
            else
                pulse_amp=kwargs.pulse_amp;
            end

            if isnan(kwargs.pulse_phs)
                pulse_phs=zeros(1, obj.pulses_);
            else
                pulse_phs=kwargs.pulse_phs/180*pi;
            end
            pulse_mod = pulse_amp .* exp(1i * pulse_phs);

            if length(pulse_mod)~= obj.pulses_
                error("ERROR! The length of pulse_phs and pulse_amp must be the same as the number of pulses.")
            end

            pulse_mod_real_ptr = libpointer("singlePtr",real(pulse_mod));
            pulse_mod_imag_ptr = libpointer("singlePtr",imag(pulse_mod));

            if ~isempty(kwargs.phs) || ~isempty(kwargs.amp)
                if isempty(kwargs.phs)
                    kwargs.phs=0;
                end

                if isempty(kwargs.amp)
                    kwargs.amp=1;
                end

                mod_var = kwargs.amp .* exp(1i * kwargs.phs/180*pi);

            else
                mod_var= [];
            end

            mod_t_ptr=libpointer("singlePtr",kwargs.mod_t);
            mod_var_real_ptr=libpointer("singlePtr",real(mod_var));
            mod_var_imag_ptr=libpointer("singlePtr",imag(mod_var));

            calllib('radarsimc', 'Add_Txchannel', location_ptr, polar_ptr, ...
                phi_ptr, phi_ptn_ptr, length(phi), ...
                theta_ptr, theta_ptn_ptr, length(theta), antenna_gain, ...
                mod_t_ptr, mod_var_real_ptr, mod_var_imag_ptr, length(kwargs.mod_t), ...
                pulse_mod_real_ptr, pulse_mod_imag_ptr, kwargs.delay, 1/180*pi, ...
                obj.tx_ptr);

            obj.tx_delay_ = [obj.tx_delay_, kwargs.delay];
        end

        function init_receiver(obj, fs, rf_gain, load_resistor, baseband_gain, kwargs)
            arguments
                obj
                fs
                rf_gain
                load_resistor
                baseband_gain
                kwargs.noise_figure = 0
            end
            if obj.rx_ptr~=0
                error("ERROR! Receiver has already been initialized.");
            end

            obj.rx_fs_ = fs;
            obj.rx_noise_figure_ = kwargs.noise_figure;
            obj.rx_rf_gain_ = rf_gain;
            obj.rx_baseband_gain_ = baseband_gain;
            obj.rx_load_resistor_ = load_resistor;
            obj.rx_noise_bandwidth_ = fs;

            obj.rx_ptr = calllib('radarsimc', 'Create_Receiver', fs, rf_gain, load_resistor, ...
                baseband_gain);
        end

        function add_rxchannel(obj, location, kwargs)
            arguments
                obj
                location (1,3)
                kwargs.polarization (1,3) = [0,0,1]
                kwargs.azimuth_angle = [-90, 90]
                kwargs.azimuth_pattern = [0, 0]
                kwargs.elevation_angle = [-90, 90]
                kwargs.elevation_pattern = [0, 0]
            end
            if obj.rx_ptr==0
                error("ERROR! Receiver is not initialized.");
            end

            location_ptr=libpointer("singlePtr",location);
            polar_ptr=libpointer("singlePtr",kwargs.polarization);

            phi = kwargs.azimuth_angle/180*pi;
            phi_ptn = kwargs.azimuth_pattern-max(kwargs.azimuth_pattern);
            if length(phi)~=length(phi_ptn)
                error("ERROR! The length of azimuth_angle and azimuth_pattern must be the same.")
            end

            phi_ptr = libpointer("singlePtr",phi);
            phi_ptn_ptr = libpointer("singlePtr",phi_ptn);

            theta = flip(90-kwargs.elevation_angle)/180*pi;
            theta_ptn = flip(kwargs.elevation_pattern)-max(kwargs.elevation_pattern);
            if length(theta)~=length(theta)
                error("ERROR! The length of elevation_angle and elevation_pattern must be the same.")
            end

            theta_ptr = libpointer("singlePtr",theta);
            theta_ptn_ptr = libpointer("singlePtr",theta_ptn);

            antenna_gain = max(kwargs.azimuth_pattern);

            calllib('radarsimc', 'Add_Rxchannel', location_ptr, polar_ptr, ...
                phi_ptr, phi_ptn_ptr, length(phi), ...
                theta_ptr, theta_ptn_ptr, length(theta), antenna_gain, ...
                obj.rx_ptr);
        end

        function add_point_target(obj, location, speed, rcs, phase)
            arguments
                obj
                location (1,3)
                speed (1,3)
                rcs
                phase = 0
            end

            if obj.targets_ptr ==0
                obj.targets_ptr = calllib('radarsimc', 'Init_Targets');
            end

            location_ptr = libpointer("singlePtr",location);
            speed_ptr = libpointer("singlePtr",speed);
            calllib('radarsimc', 'Add_Point_Target', location_ptr, speed_ptr, rcs, phase/180*pi, obj.targets_ptr);
        end

        function add_mesh_target(obj, points, connectivity_list, location, speed, rotation, rotation_rate, kwargs)
            arguments
                obj
                points
                connectivity_list
                location (1,3)
                speed (1,3)
                rotation (1,3)
                rotation_rate (1,3)
                kwargs.origin (1,3) = [0,0,0]
                kwargs.permittivity = 'PEC'
                kwargs.is_ground = false
            end

            if obj.targets_ptr ==0
                obj.targets_ptr = calllib('radarsimc', 'Init_Targets');
            end

            points_ptr = libpointer("singlePtr", points.');
            connectivity_list_ptr = libpointer("int32Ptr", (connectivity_list.'-1));
            [row,~] = size(connectivity_list);

            origin_ptr = libpointer("singlePtr", kwargs.origin);
            location_ptr = libpointer("singlePtr", location);
            speed_ptr = libpointer("singlePtr", speed);
            rotation_ptr = libpointer("singlePtr", rotation/180*pi);
            rotation_rate_ptr = libpointer("singlePtr", rotation_rate/180*pi);

            if strcmp(kwargs.permittivity, 'PEC')
                ep_real = -1;
                ep_imag = 0;
                mu_real = 1;
                mu_imag = 0;
            else
                ep_real = real(kwargs.permittivity);
                ep_imag = imag(kwargs.permittivity);
                mu_real = 1;
                mu_imag = 0;
            end

            calllib('radarsimc', 'Add_Mesh_Target', ...
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
                kwargs.is_ground, ...
                obj.targets_ptr);

        end

        function set_radar_motion(obj, location, speed, rotation, rotation_rate)
            arguments
                obj
                location (1,3)
                speed (1,3)
                rotation (1,3)
                rotation_rate (1,3)
            end

            obj.radar_loc = location;
            obj.radar_spd = speed;
            obj.radar_rot = rotation/180*pi;
            obj.radar_rrt = rotation_rate/180*pi;
        end

        function run_simulator(obj, kwargs)
            arguments
                obj
                kwargs.noise=true
                kwargs.density=1
                kwargs.level='frame' % 'frame', 'pulse', 'sample'
            end

            obj.radar_ptr=calllib('radarsimc', 'Create_Radar', obj.tx_ptr, obj.rx_ptr);
            radar_loc_ptr=libpointer("singlePtr",obj.radar_loc);
            radar_spd_ptr=libpointer("singlePtr",obj.radar_spd);
            radar_rot_ptr=libpointer("singlePtr",obj.radar_rot);
            radar_rrt_ptr=libpointer("singlePtr",obj.radar_rrt);
            calllib('radarsimc', 'Set_Radar_Motion', radar_loc_ptr, radar_spd_ptr, radar_rot_ptr, radar_rrt_ptr, obj.radar_ptr);

            num_tx = calllib('radarsimc', 'Get_Num_Txchannel', obj.tx_ptr);
            num_rx = calllib('radarsimc', 'Get_Num_Rxchannel', obj.rx_ptr);

            obj.samples_ = floor(obj.tx_p_length_*obj.rx_fs_);
            bb_real = libpointer("doublePtr",zeros(obj.samples_, obj.pulses_, num_tx*num_rx));
            bb_imag = libpointer("doublePtr",zeros(obj.samples_, obj.pulses_, num_tx*num_rx));

            if strcmp(kwargs.level, 'frame')
                level = 0;
            elseif strcmp(kwargs.level, 'pulse')
                level = 1;
            elseif strcmp(kwargs.level, 'sample')
                level = 2;
            else
                error("ERROR! Unknow level.");
            end

            calllib('radarsimc','Run_Simulator',obj.radar_ptr, obj.targets_ptr, level, kwargs.density, bb_real, bb_imag);
            obj.baseband_=reshape(bb_real.Value+1i*bb_imag.Value, obj.samples_, obj.pulses_, num_tx*num_rx);

            obj.timestamp_=repmat((0:1:(obj.samples_-1)).'/obj.rx_fs_, 1, obj.pulses_, num_tx*num_rx)+ ...
                repmat(obj.tx_p_start_time_, obj.samples_,1, num_tx*num_rx)+ ...
                permute(repmat(reshape(repmat(obj.tx_delay_, num_rx, 1), 1,[]).',1, obj.samples_, obj.pulses_), [2, 3,1]);


            if kwargs.noise
                obj.add_noise();
            end
        end

        function reset(obj)
            if obj.targets_ptr~=0
                calllib('radarsimc','Free_Targets',obj.targets_ptr);
            end

            if obj.radar_ptr~=0
                calllib('radarsimc','Free_Radar',obj.radar_ptr);
            else
                if obj.tx_ptr~=0
                    calllib('radarsimc','Free_Transmitter',obj.tx_ptr);
                end
                if obj.rx_ptr~=0
                    calllib('radarsimc','Free_Receiver',obj.rx_ptr);
                end
            end

            obj.targets_ptr=0;
            obj.radar_ptr=0;
            obj.tx_ptr=0;
            obj.rx_ptr=0;

            obj.tx_delay_ = [];
        end

        function delete(obj)
            obj.reset();

            if libisloaded('radarsimc')
                try
                    unloadlibrary radarsimc;
                catch exception
                    disp(exception.message);
                end
            end
        end

        function add_noise(obj)
            boltzmann_const = 1.38064852e-23;
            Ts = 290;
            input_noise_dbm = 10 * log10(boltzmann_const * Ts * 1000);  % dBm/Hz
            receiver_noise_dbm = (input_noise_dbm+ ...
                obj.rx_rf_gain_+ ...
                obj.rx_noise_figure_+ ...
                10 * log10(obj.rx_noise_bandwidth_)+ ...
                obj.rx_baseband_gain_);  % dBm/Hz
            receiver_noise_watts = 1e-3 * 10^(receiver_noise_dbm / 10);  % Watts/sqrt(hz)
            noise_amplitude_mixer = sqrt(receiver_noise_watts * obj.rx_load_resistor_);
            noise_amplitude_peak = sqrt(2) * noise_amplitude_mixer;

            obj.baseband_ = obj.baseband_+noise_amplitude_peak*(randn(size(obj.baseband_))+1i*randn(size(obj.baseband_)));

        end

    end

end