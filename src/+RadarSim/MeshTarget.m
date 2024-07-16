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