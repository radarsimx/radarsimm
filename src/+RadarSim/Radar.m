classdef Radar < handle
    properties (Access = public)
        version_ = '';

    end

    properties (Access = private)
        radar_ptr=0;
    end

    methods (Access = public)

        % Construct app
        function obj = Radar(tx, rx, kwargs)
            arguments
                tx RadarSim.Transmitter
                rx RadarSim.Receiver
                kwargs.location (1,3) = [0,0,0]
                kwargs.speed (1,3) = [0,0,0]
                kwargs.rotation (1,3) = [0,0,0]
                kwargs.rotation_rate (1,3) = [0,0,0]
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

            obj.radar_ptr=calllib('radarsimc', 'Create_Radar', tx.tx_ptr, rx.rx_ptr);

            radar_loc_ptr=libpointer("singlePtr",kwargs.location);
            radar_spd_ptr=libpointer("singlePtr",kwargs.speed);
            radar_rot_ptr=libpointer("singlePtr",kwargs.rotation);
            radar_rrt_ptr=libpointer("singlePtr",kwargs.rotation_rate);
            calllib('radarsimc', 'Set_Radar_Motion', radar_loc_ptr, radar_spd_ptr, radar_rot_ptr, radar_rrt_ptr, obj.radar_ptr);

        end

        function delete(obj)
            if libisloaded('radarsimc')
                try
                    unloadlibrary radarsimc;
                catch exception
                    disp(exception.message);
                end
            end
        end



    end
end