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


classdef Transmitter < handle
    properties (Access = public)
        version_ = '';
        f_;
        t_;
        power_;
        pulses_;
        pulse_duration_;
        prp_;
        pulse_start_time_;
        f_offset_;
        frame_start_time_;
        tx_ptr = 0;
        channels_ = {};
        delay_=[];
    end

    methods (Access = public)
        % Construct app
        % This function initializes the Transmitter object with given frequency, time, and other parameters.
        function obj = Transmitter(f, t, kwargs)
            arguments
                f
                t
                kwargs.tx_power double = 0
                kwargs.pulses uint32 = 1
                kwargs.prp = NaN
                kwargs.f_offset = NaN
                kwargs.pn_f = NaN
                kwargs.pn_power = NaN
                kwargs.frame_time = [0]
                kwargs.channels = {}
            end
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

            obj.f_ = f;
            obj.t_ = t;
            obj.power_ = kwargs.tx_power;

            if length(obj.f_) == 1
                obj.f_ = [obj.f_, obj.f_];
            end

            if length(obj.t_) == 1
                obj.t_=[0, obj.t_];
            end

            if length(obj.t_)~=length(obj.f_)
                error("ERROR! f and t must have the same length.");
            end

            f_ptr = libpointer("doublePtr",obj.f_);
            t_ptr = libpointer("doublePtr",obj.t_);

            obj.pulses_ = kwargs.pulses;
            obj.pulse_duration_ = obj.t_(end)-obj.t_(1);

            if isnan(kwargs.prp)
                obj.prp_ = obj.pulse_duration_+zeros(1, obj.pulses_);
            elseif length(kwargs.prp)==1
                obj.prp_ = kwargs.prp+zeros(1, obj.pulses_);
            else
                obj.prp_ = kwargs.prp;
            end

            if length(obj.prp_)<obj.pulses_
                error("ERROR! The length of prp must be the same of pulses.");
            end

            if any(obj.prp_<obj.pulse_duration_)
                error("ERROR! prp can't be smaller than the pulse length.")
            end

            obj.pulse_start_time_ = cumsum(obj.prp_)-obj.prp_(1);
            pulse_start_time_ptr = libpointer("doublePtr",obj.pulse_start_time_);

            if isnan(kwargs.f_offset)
                obj.f_offset_ = zeros(1, obj.pulses_);
            else
                obj.f_offset_ = kwargs.f_offset;
            end

            if length(obj.f_offset_) ~= obj.pulses_
                error("ERROR! The length of f_offset must be the same as pulses.");
            end

            f_offset_ptr = libpointer("doublePtr",obj.f_offset_);

            obj.frame_start_time_ = kwargs.frame_time;
            frame_start_time_ptr = libpointer("doublePtr",obj.frame_start_time_);

            obj.tx_ptr = calllib('radarsimc', 'Create_Transmitter', ...
                f_ptr, t_ptr, length(obj.f_), ...
                f_offset_ptr, pulse_start_time_ptr, obj.pulses_, ...
                frame_start_time_ptr, length(obj.frame_start_time_), ...
                obj.power_);

            for ch_idx=1:length(kwargs.channels)
                obj.add_txchannel(kwargs.channels{ch_idx});
            end

        end

        % Add transmitter channel
        % This function adds a transmitter channel to the Transmitter object.
        function add_txchannel(obj, tx_ch)
            arguments
                obj
                tx_ch RadarSim.TxChannel
            end

            location_ptr=libpointer("singlePtr",tx_ch.location_);
            polar_real_ptr=libpointer("singlePtr",real(tx_ch.polarization_));
            polar_imag_ptr=libpointer("singlePtr",imag(tx_ch.polarization_));

            phi_ptr = libpointer("singlePtr",tx_ch.phi_);
            phi_ptn_ptr = libpointer("singlePtr",tx_ch.phi_ptn_);

            theta_ptr = libpointer("singlePtr",tx_ch.theta_);
            theta_ptn_ptr = libpointer("singlePtr",tx_ch.theta_ptn_);

            if isempty(tx_ch.pulse_mod_)
                tx_ch.pulse_mod_ = ones(1, obj.pulses_);
            end

            pulse_mod_real_ptr = libpointer("singlePtr",real(tx_ch.pulse_mod_));
            pulse_mod_imag_ptr = libpointer("singlePtr",imag(tx_ch.pulse_mod_));

            mod_t_ptr=libpointer("singlePtr",tx_ch.mod_t_);
            mod_var_real_ptr=libpointer("singlePtr",real(tx_ch.mod_var_));
            mod_var_imag_ptr=libpointer("singlePtr",imag(tx_ch.mod_var_));

            status = calllib('radarsimc', 'Add_Txchannel', location_ptr, polar_real_ptr, polar_imag_ptr, ...
                phi_ptr, phi_ptn_ptr, length(tx_ch.phi_), ...
                theta_ptr, theta_ptn_ptr, length(tx_ch.theta_), tx_ch.antenna_gain_, ...
                mod_t_ptr, mod_var_real_ptr, mod_var_imag_ptr, length(tx_ch.mod_t_), ...
                pulse_mod_real_ptr, pulse_mod_imag_ptr, tx_ch.delay_, 1/180*pi, ...
                obj.tx_ptr);

            if status
                error("RadarSim:FreeTier", "Error: \nYou're currently using RadarSimM's FreeTier, " + ...
                    "which imposes a restriction on the maximum number of transmitter channels to 1. " + ...
                    "Please consider supporting my work by upgrading to the standard version. Just choose " + ...
                    "any amount greater than zero on https://radarsimx.com/product/radarsimm/ to access the " + ...
                    "standard version download links. Your support will help improve the software. " + ...
                    "Thank you for considering it.");
            end

            obj.delay_ = [obj.delay_, tx_ch.delay_];

            obj.channels_ = [obj.channels_, tx_ch];
        end

        % Reset transmitter
        % This function resets the Transmitter object, freeing any allocated resources.
        function reset(obj)
            if obj.tx_ptr~=0
                calllib('radarsimc','Free_Transmitter',obj.tx_ptr);
            end

            obj.tx_ptr=0;
            obj.delay_ = [];
            obj.channels_ = {};
        end

        % Delete transmitter
        % This function deletes the Transmitter object and unloads the library if loaded.
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