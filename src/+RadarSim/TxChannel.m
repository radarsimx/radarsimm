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


classdef TxChannel < handle
    % TxChannel class represents a transmission channel in the radar simulation.
    % This class handles the properties and methods related to the transmission
    % channel including location, polarization, delay, angles, patterns, and modulation.

    properties (Access = public)
        location_;
        polarization_;
        delay_;
        phi_;
        phi_ptn_;
        theta_;
        theta_ptn_;
        antenna_gain_;
        pulse_mod_;
        mod_t_;
        mod_var_;

    end

    methods (Access = public)
        % Constructor for TxChannel class.
        % Initializes the transmission channel with specified location and optional parameters.
        %
        % Parameters:
        %   location (1,3 double): The location coordinates of the transmission channel.
        %   kwargs.polarization (1,3 double): The polarization vector (default: [0,0,1]).
        %   kwargs.delay (double): The delay in the transmission (default: 0).
        %   kwargs.azimuth_angle (1,2 double): The azimuth angle range in degrees (default: [-90, 90]).
        %   kwargs.azimuth_pattern (1,2 double): The azimuth pattern (default: [0, 0]).
        %   kwargs.elevation_angle (1,2 double): The elevation angle range in degrees (default: [-90, 90]).
        %   kwargs.elevation_pattern (1,2 double): The elevation pattern (default: [0, 0]).
        %   kwargs.pulse_amp (double): The pulse amplitude.
        %   kwargs.pulse_phs (double): The pulse phase in degrees.
        %   kwargs.mod_t (double): The modulation time.
        %   kwargs.phs (double): The phase in degrees.
        %   kwargs.amp (double): The amplitude.
        function obj = TxChannel(location, kwargs)
            arguments
                location (1,3)
                kwargs.polarization (1,3) = [0,0,1]
                kwargs.delay = 0
                kwargs.azimuth_angle = [-90, 90]
                kwargs.azimuth_pattern = [0, 0]
                kwargs.elevation_angle = [-90, 90]
                kwargs.elevation_pattern = [0, 0]
                kwargs.pulse_amp = []
                kwargs.pulse_phs = []
                kwargs.mod_t = []
                kwargs.phs = []
                kwargs.amp = []
            end

            obj.location_=location;

            obj.polarization_ = kwargs.polarization;

            obj.phi_ = kwargs.azimuth_angle/180*pi;
            obj.phi_ptn_ = kwargs.azimuth_pattern-max(kwargs.azimuth_pattern);
            if length(obj.phi_)~=length(obj.phi_ptn_)
                error("ERROR! The length of azimuth_angle and azimuth_pattern must be the same.")
            end

            obj.theta_ = flip(90-kwargs.elevation_angle)/180*pi;
            obj.theta_ptn_ = flip(kwargs.elevation_pattern)-max(kwargs.elevation_pattern);
            if length(obj.theta_)~=length(obj.theta_ptn_)
                error("ERROR! The length of elevation_angle and elevation_pattern must be the same.")
            end

            obj.antenna_gain_ = max(kwargs.azimuth_pattern);

            if ~isempty(kwargs.pulse_amp) && ~isempty(kwargs.pulse_phs)
                pulse_amp=kwargs.pulse_amp;
                pulse_phs=kwargs.pulse_phs/180*pi;

                obj.pulse_mod_ = pulse_amp .* exp(1i * pulse_phs);
            elseif isempty(kwargs.pulse_amp) && ~isempty(kwargs.pulse_phs)
                pulse_phs=kwargs.pulse_phs/180*pi;
                obj.pulse_mod_ = exp(1i * pulse_phs);
            elseif ~isempty(kwargs.pulse_amp) && isempty(kwargs.pulse_phs)
                obj.pulse_mod_ = kwargs.pulse_amp;
            else
                obj.pulse_mod_=[];
            end

            if ~isempty(kwargs.phs) || ~isempty(kwargs.amp)
                if isempty(kwargs.phs)
                    kwargs.phs=0;
                end

                if isempty(kwargs.amp)
                    kwargs.amp=1;
                end

                obj.mod_var_ = kwargs.amp .* exp(1i * kwargs.phs/180*pi);

            else
                obj.mod_var_= [];
            end
            obj.mod_t_ = kwargs.mod_t;

            obj.delay_ = kwargs.delay;
        end
    end
end