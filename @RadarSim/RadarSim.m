classdef RadarSim < handle
    properties (Access = public)
        version_ = '1.0';
        bandwidth_;
        pulse_period_;
        samples_;
        baseband_;
        noise_figure_;
    end

    properties (Access = private)
        tx_ptr=0;
        rx_ptr=0;
        radar_ptr=0;
        targets_ptr=0;
        
        pulses_=0;
        fs_;
    end

    methods (Access = public)

        % Construct app
        function obj = RadarSim()
            loadlibrary('radarsimc','radarsim.h');
            obj.targets_ptr = calllib('radarsimc', 'Init_Targets');
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

            if length(f) == 1
                f = [f, f];
            end

            if length(t) == 1
                t=[0, t];
            end

            if length(t)~=length(f)
                error("f and t must have the same length.");
            end

            f_ptr = libpointer("doublePtr",f);
            t_ptr = libpointer("doublePtr",t);

            obj.pulses_ = kwargs.pulses;
            obj.pulse_period_ = t(end)-t(1);

            if isnan(kwargs.prp)
                prp = obj.pulse_period_+zeros(1, obj.pulses_);
            elseif length(kwargs.prp)==1
                prp = kwargs.prp+zeros(1, obj.pulses_);
            else
                prp = kwargs.prp;
            end

            if length(prp)<obj.pulses_
                error("The length of prp must be the same of pulses.");
            end

            if any(prp<obj.pulse_period_)
                error("prp can't be smaller than the pulse length.")
            end

            pulse_start_time_ptr = libpointer("doublePtr",cumsum(prp)-prp(1));

            if isnan(kwargs.f_offset)
                f_offset = zeros(1, obj.pulses_);
            else
                f_offset = kwargs.f_offset;
            end

            if length(f_offset) ~= obj.pulses_
                error("The length of f_offset must be the same as pulses.");
            end

            f_offset_ptr = libpointer("doublePtr",f_offset);

            frame_start_time_ptr = libpointer("doublePtr",0);

            obj.tx_ptr = calllib('radarsimc', 'Create_Transmitter', f_ptr, t_ptr, length(f), f_offset_ptr, pulse_start_time_ptr, obj.pulses_, frame_start_time_ptr, 1, kwargs.tx_power);

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
                error("Transmitter is not initialized.");
            end

            location_ptr=libpointer("singlePtr",location);
            polar_ptr=libpointer("singlePtr",kwargs.polarization);

            phi = kwargs.azimuth_angle/180*pi;
            phi_ptn = kwargs.azimuth_pattern-max(kwargs.azimuth_pattern);
            if length(phi)~=length(phi_ptn)
                error("The length of azimuth_angle and azimuth_pattern must be the same.")
            end

            phi_ptr = libpointer("singlePtr",phi);
            phi_ptn_ptr = libpointer("singlePtr",phi_ptn);

            theta = flip(90-kwargs.elevation_angle)/180*pi;
            theta_ptn = flip(kwargs.elevation_pattern)-max(kwargs.elevation_pattern);
            if length(theta)~=length(theta)
                error("The length of elevation_angle and elevation_pattern must be the same.")
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
                error("The length of pulse_phs and pulse_amp must be the same as the number of pulses.")
            end

            pulse_mod_real_ptr = libpointer("singlePtr",real(pulse_mod));
            pulse_mod_imag_ptr = libpointer("singlePtr",imag(pulse_mod));

            if ~isempty(kwargs.phs) && ~isempty(kwargs.amp)
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
                pulse_mod_real_ptr, pulse_mod_imag_ptr, kwargs.delay, 1, ...
                obj.tx_ptr);
        end

        function init_receiver(obj, fs, noise_figure, rf_gain, load_resistor, baseband_gain)
            obj.fs_ = fs;
            obj.noise_figure_ = noise_figure;
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
                error("Receiver is not initialized.");
            end

            location_ptr=libpointer("singlePtr",location);
            polar_ptr=libpointer("singlePtr",kwargs.polarization);

            phi = kwargs.azimuth_angle/180*pi;
            phi_ptn = kwargs.azimuth_pattern-max(kwargs.azimuth_pattern);
            if length(phi)~=length(phi_ptn)
                error("The length of azimuth_angle and azimuth_pattern must be the same.")
            end

            phi_ptr = libpointer("singlePtr",phi);
            phi_ptn_ptr = libpointer("singlePtr",phi_ptn);

            theta = flip(90-kwargs.elevation_angle)/180*pi;
            theta_ptn = flip(kwargs.elevation_pattern)-max(kwargs.elevation_pattern);
            if length(theta)~=length(theta)
                error("The length of elevation_angle and elevation_pattern must be the same.")
            end

            theta_ptr = libpointer("singlePtr",theta);
            theta_ptn_ptr = libpointer("singlePtr",theta_ptn);

            antenna_gain = max(kwargs.azimuth_pattern);

            calllib('radarsimc', 'Add_Rxchannel', location_ptr, polar_ptr, ...
                phi_ptr, phi_ptn_ptr, length(phi), ...
                theta_ptr, theta_ptn_ptr, length(theta), antenna_gain, ...
                obj.rx_ptr);
        end

        function add_target(obj, location, speed, rcs, phase)
            arguments
                obj
                location (1,3)
                speed (1,3)
                rcs
                phase = 0
            end

            location_ptr = libpointer("singlePtr",location);
            speed_ptr = libpointer("singlePtr",speed);
            calllib('radarsimc', 'Add_Target', location_ptr, speed_ptr, rcs, phase/180*pi, obj.targets_ptr);
        end

        function run_simulator(obj)

            obj.radar_ptr=calllib('radarsimc', 'Create_Radar', obj.tx_ptr, obj.rx_ptr);
            radar_loc_ptr=libpointer("singlePtr",[0,0,0]);
            radar_spd_ptr=libpointer("singlePtr",[0,0,0]);
            radar_rot_ptr=libpointer("singlePtr",[0,0,0]);
            radar_rrt_ptr=libpointer("singlePtr",[0,0,0]);
            calllib('radarsimc', 'Set_Radar_Motion', radar_loc_ptr, radar_spd_ptr, radar_rot_ptr, radar_rrt_ptr, obj.radar_ptr);

            obj.samples_ = floor(obj.pulse_period_*obj.fs_);
            bb_real = libpointer("doublePtr",zeros(obj.samples_, obj.pulses_));
            bb_imag = libpointer("doublePtr",zeros(obj.samples_, obj.pulses_));

            calllib('radarsimc','Run_Simulator',obj.radar_ptr, obj.targets_ptr, bb_real, bb_imag);
            obj.baseband_=bb_real.Value+1i*bb_imag.Value;
        end

        function delete(obj)
            calllib('radarsimc','Free_Targets',obj.targets_ptr);

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

            unloadlibrary radarsimc;
        end

    end

end