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


classdef Radar < handle
    properties (Access = public)
        version_ = '';
        tx_;
        rx_;
        num_tx_;
        num_rx_;
        num_frame_;
        samples_per_pulse_;
        timestamp_;

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

            obj.tx_ = tx;
            obj.rx_ = rx;

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

            radar_loc_ptr=libpointer("singlePtr",kwargs.location);
            radar_spd_ptr=libpointer("singlePtr",kwargs.speed);
            radar_rot_ptr=libpointer("singlePtr",kwargs.rotation);
            radar_rrt_ptr=libpointer("singlePtr",kwargs.rotation_rate);

            obj.radar_ptr=calllib('radarsimc', 'Create_Radar', obj.tx_.tx_ptr, obj.rx_.rx_ptr, radar_loc_ptr, radar_spd_ptr, radar_rot_ptr, radar_rrt_ptr);

            obj.num_tx_ = calllib('radarsimc', 'Get_Num_Txchannel', obj.tx_.tx_ptr);
            obj.num_rx_ = calllib('radarsimc', 'Get_Num_Rxchannel', obj.rx_.rx_ptr);
            obj.num_frame_ = length(obj.tx_.frame_start_time_);

            obj.samples_per_pulse_ = floor(obj.tx_.pulse_duration_*obj.rx_.fs_);

            obj.timestamp_=repmat((0:1:(obj.samples_per_pulse_-1)).'/obj.rx_.fs_, 1, obj.tx_.pulses_, obj.num_tx_*obj.num_rx_*obj.num_frame_)+ ...
                repmat(obj.tx_.pulse_start_time_, obj.samples_per_pulse_,1, obj.num_tx_*obj.num_rx_*obj.num_frame_)+ ...
                permute(repmat(reshape(repmat(obj.tx_.delay_, obj.num_rx_, 1), 1,[]).',1, obj.samples_per_pulse_, obj.tx_.pulses_), [2, 3,1]);

        end

        function reset(obj)
            if obj.radar_ptr~=0
                calllib('radarsimc','Free_Radar',obj.radar_ptr);
            end
            obj.radar_ptr=0;
        end

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