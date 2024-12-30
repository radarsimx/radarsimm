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


classdef Receiver < handle
    properties (Access = public)
        version_ = '';
        fs_;
        noise_figure_;
        rf_gain_;
        baseband_gain_;
        load_resistor_;
        noise_bandwidth_;
        bb_type_;
        channels_={};
        rx_ptr=0;
    end

    methods (Access = public)
        % Constructor for the Receiver class.
        % Initializes the receiver with specified parameters.
        %
        % Parameters:
        %   fs (double): Sampling frequency.
        %   rf_gain (double): RF gain.
        %   load_resistor (double): Load resistor.
        %   baseband_gain (double): Baseband gain.
        %   kwargs.noise_figure (double): Noise figure (default: 0).
        %   kwargs.bb_type (char): Baseband type ('complex' or 'real') (default: 'complex').
        %   kwargs.channels (cell): Channels (default: {}).
        function obj = Receiver(fs, rf_gain, load_resistor, baseband_gain, kwargs)
            arguments
                fs
                rf_gain
                load_resistor
                baseband_gain
                kwargs.noise_figure = 0
                kwargs.bb_type = "complex"
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

            obj.fs_ = fs;
            obj.noise_figure_ = kwargs.noise_figure;
            obj.rf_gain_ = rf_gain;
            obj.baseband_gain_ = baseband_gain;
            obj.load_resistor_ = load_resistor;

            obj.bb_type_ = kwargs.bb_type;

            if strcmp(obj.bb_type_, "complex")
                obj.noise_bandwidth_ = fs;
            elseif strcmp(obj.bb_type_, "real")
                obj.noise_bandwidth_ = fs/2;
            end

            obj.rx_ptr = calllib('radarsimc', 'Create_Receiver', obj.fs_, obj.rf_gain_, obj.load_resistor_, ...
                obj.baseband_gain_, obj.noise_bandwidth_);

            for ch_idx=1:length(kwargs.channels)
                obj.add_rxchannel(kwargs.channels{ch_idx});
            end
        end

        % Add a receiver channel
        % Adds a receiver channel to the Receiver object.
        %
        % Parameters:
        %   rx_ch (RadarSim.RxChannel): The receiver channel object.
        function add_rxchannel(obj, rx_ch)
            arguments
                obj
                rx_ch RadarSim.RxChannel
            end

            location_ptr=libpointer("singlePtr",rx_ch.location_);
            polar_real_ptr=libpointer("singlePtr",real(rx_ch.polarization_));
            polar_imag_ptr=libpointer("singlePtr",imag(rx_ch.polarization_));

            phi_ptr = libpointer("singlePtr",rx_ch.phi_);
            phi_ptn_ptr = libpointer("singlePtr",rx_ch.phi_ptn_);

            theta_ptr = libpointer("singlePtr",rx_ch.theta_);
            theta_ptn_ptr = libpointer("singlePtr",rx_ch.theta_ptn_);

            status = calllib('radarsimc', 'Add_Rxchannel', location_ptr, polar_real_ptr, polar_imag_ptr, ...
                phi_ptr, phi_ptn_ptr, length(rx_ch.phi_), ...
                theta_ptr, theta_ptn_ptr, length(rx_ch.theta_), rx_ch.antenna_gain_, ...
                obj.rx_ptr);

            if status
                error("RadarSim:FreeTier", "Error: \nYou're currently using RadarSimM's FreeTier, " + ...
                    "which imposes a restriction on the maximum number of receiver channels to 1. " + ...
                    "Please consider supporting my work by upgrading to the standard version. Just choose " + ...
                    "any amount greater than zero on https://radarsimx.com/product/radarsimm/ to access the " + ...
                    "standard version download links. Your support will help improve the software. " + ...
                    "Thank you for considering it.");
            end
            obj.channels_ = [obj.channels_, rx_ch];
        end

        % Reset the receiver
        % Resets the Receiver object, freeing any allocated resources.
        function reset(obj)
            if obj.rx_ptr~=0
                calllib('radarsimc','Free_Receiver',obj.rx_ptr);
            end
            obj.rx_ptr=0;

            obj.channels_ = {};
        end

        % Delete the receiver
        % Deletes the Receiver object and unloads the library if loaded.
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