classdef PointTarget < handle
    properties (Access = public)
        type_="point";
        location_;
        rcs_;
        speed_;
        phase_;

    end

    methods (Access = public)

        % Construct app
        function obj = PointTarget(location, speed, rcs, kwargs)
            arguments
                location (1,3)
                speed (1,3)
                rcs
                kwargs.phase = 0
            end

            obj.location_=location;
            obj.speed_ = speed;
            obj.rcs_ = rcs;
            obj.phase_ = kwargs.phase/180*pi;
        end
    end
end