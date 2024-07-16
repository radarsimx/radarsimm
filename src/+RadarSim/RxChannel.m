classdef RxChannel < handle
    properties (Access = public)
        location_;
        polarization_;
        phi_;
        phi_ptn_;
        theta_;
        theta_ptn_;
        antenna_gain_;

    end

    methods (Access = public)

        % Construct app
        function obj = RxChannel(location, kwargs)
            arguments
                location (1,3)
                kwargs.polarization (1,3) = [0,0,1]
                kwargs.azimuth_angle = [-90, 90]
                kwargs.azimuth_pattern = [0, 0]
                kwargs.elevation_angle = [-90, 90]
                kwargs.elevation_pattern = [0, 0]
            end
            
            obj.location_ = location;
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

        end

    end
end