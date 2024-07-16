classdef TxChannel < handle
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

        % Construct app
        function obj = TxChannel(location, kwargs)
            arguments
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

            if ~isnan(kwargs.pulse_amp) && ~isnan(kwargs.pulse_phs)
                pulse_amp=kwargs.pulse_amp;
                pulse_phs=kwargs.pulse_phs/180*pi;

                obj.pulse_mod_ = pulse_amp .* exp(1i * pulse_phs);
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