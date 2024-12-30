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


classdef MeshTarget < handle
    properties (Access = public)
        type_="mesh";
        points_;
        connectivity_list_;
        location_;
        speed_;
        rotation_;
        rotation_rate_;
        origin_;
        permittivity_;
        is_ground_;
    end

    methods (Access = public)
        % Construct app
        % Constructor for the MeshTarget class.
        % 
        % Parameters:
        %   points: Array of points defining the mesh.
        %   connectivity_list: List defining the connectivity of the mesh points.
        %   location: 1x3 array specifying the location of the target.
        %   speed: 1x3 array specifying the speed of the target.
        %   rotation: 1x3 array specifying the rotation of the target in degrees.
        %   rotation_rate: 1x3 array specifying the rotation rate of the target in degrees per second.
        %   kwargs: Optional keyword arguments including:
        %       - origin: 1x3 array specifying the origin of the target (default: [0,0,0]).
        %       - permittivity: String specifying the permittivity of the target (default: 'PEC').
        %       - is_ground: Boolean specifying if the target is on the ground (default: false).
        function obj = MeshTarget(points, connectivity_list, location, speed, rotation, rotation_rate, kwargs)
            arguments
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

            obj.points_ = points;
            obj.connectivity_list_ = connectivity_list;
            obj.location_=location;
            obj.speed_ = speed;
            obj.rotation_ = rotation/180*pi;
            obj.rotation_rate_ = rotation_rate/180*pi;
            obj.origin_ = kwargs.origin;
            obj.permittivity_ = kwargs.permittivity;
            obj.is_ground_ = kwargs.is_ground;
        end
    end
end