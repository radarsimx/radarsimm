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


classdef PointTarget < handle
    % PointTarget Class representing a point target in the radar simulation.
    % This class defines the properties and methods for a point target,
    % including its location, speed, radar cross section (RCS), and phase.

    properties (Access = public)
        type_="point"; % Type of the target
        location_;    % Location of the target [x, y, z]
        rcs_;         % Radar cross section of the target
        speed_;       % Speed of the target [vx, vy, vz]
        phase_;       % Phase of the target in radians
    end

    methods (Access = public)

        % Construct app
        % PointTarget Constructor for the PointTarget class.
        % Initializes the location, speed, RCS, and phase of the target.
        %
        % Parameters:
        %   location (1,3): Location of the target [x, y, z]
        %   speed (1,3): Speed of the target [vx, vy, vz]
        %   rcs: Radar cross section of the target
        %   kwargs.phase: Phase of the target in degrees (default: 0)
        function obj = PointTarget(location, speed, rcs, kwargs)
            arguments
                location (1,3)
                speed (1,3)
                rcs
                kwargs.phase = 0
            end

            obj.location_ = location;
            obj.speed_ = speed;
            obj.rcs_ = rcs;
            obj.phase_ = kwargs.phase / 180 * pi;
        end
    end
end