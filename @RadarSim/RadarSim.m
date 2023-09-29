classdef RadarSim < handle
    properties (Access = public)
        version_ = '1.0';
        bandwidth_;
        pulse_length_;
    end

    properties (Access = private)
        tx_ptr=NaN;
        rx_ptr=NaN;
        radar_ptr=NaN;
        targets_ptr=NaN;
        sim_ptr=NaN;

        pulses_=0;
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
            obj.pulse_length_ = t(end)-t(1);

            if isnan(kwargs.prp)
                prp = obj.pulse_length_+zeros(1, obj.pulses_);
            elseif length(kwargs.prp)==1
                prp = kwargs.prp+zeros(1, obj.pulses_);
            else
                prp = kwargs.prp;
            end

            if length(prp)<obj.pulses_
                error("The length of prp must be the same of pulses.");
            end

            if any(prp<obj.pulse_length_)
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
            if isnan(obj.tx_ptr)
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
            pulse_mod = pulse_amp * exp(1i * pulse_phs);

            if length(pulse_mod)~= obj.pulses_
                error("The length of pulse_phs and pulse_amp must be the same as the number of pulses.")
            end

            pulse_mod_real_ptr = libpointer("singlePtr",real(pulse_mod));
            pulse_mod_imag_ptr = libpointer("singlePtr",imag(pulse_mod));

            if ~isempty(kwargs.phs) && ~isempty(kwargs.amp)
                mod_var = kwargs.amp * exp(1i * kwargs.phs/180*pi);
            else
                mod_var= [];
            end

            mod_t_ptr=libpointer("singlePtr",kwargs.mod_t);
            mod_var_real_ptr=libpointer("singlePtr",real(mod_var));
            mod_var_imag_ptr=libpointer("singlePtr",imag(mod_var));

            calllib('radarsimc', 'Add_Txchannel', location_ptr, polar_ptr, ...
                phi_ptr, phi_ptn_ptr, length(phi), ...
                theta_ptr, theta_ptn_ptr, length(theta), antenna_gain, ...
                mod_t_ptr, mod_var_real_ptr, mod_var_imag_ptr, length(mod_t), ...
                pulse_mod_real_ptr, pulse_mod_imag_ptr, kwargs.delay, 1, ...
                obj.tx_ptr);
        end

        function init_receiver(obj, fs, rf_gain, resistor, baseband_gain)
            obj.rx_ptr = calllib('radarsimc', 'Create_Receiver', fs, rf_gain, resistor, ...
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
            if isnan(obj.rx_ptr)
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

        function add_target(obj)
        end

        function run_simulator(obj)
        end

        function delete(obj)
            calllib('radarsimc','Free_Targets',obj.targets_ptr);

            clear obj.targets_ptr;

            unloadlibrary radarsimc;
        end

    end

end