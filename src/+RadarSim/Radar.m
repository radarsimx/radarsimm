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
        % Public properties
        version_ = '';
        tx_;
        rx_;
        num_tx_;
        num_rx_;
        num_frame_;
        frame_start_time_;
        samples_per_pulse_;
        timestamp_;

        radar_ptr=0;
    end

    methods (Access = public)

        % Constructor for the Radar class.
        % Initializes the radar system with the given transmitter and receiver.
        % 
        % Parameters:
        %   tx (RadarSim.Transmitter): The radar transmitter object.
        %   rx (RadarSim.Receiver): The radar receiver object.
        %   kwargs.location (1,3 double): Radar location coordinates (default: [0,0,0]).
        %   kwargs.speed (1,3 double): Radar speed (default: [0,0,0]).
        %   kwargs.rotation (1,3 double): Radar rotation in degrees (default: [0,0,0]).
        %   kwargs.rotation_rate (1,3 double): Radar rotation rate in degrees per second (default: [0,0,0]).
        function obj = Radar(tx, rx, kwargs)
            arguments
                tx RadarSim.Transmitter
                rx RadarSim.Receiver
                kwargs.frame_time = [0]
                kwargs.location (1,3) = [0,0,0]
                kwargs.speed (1,3) = [0,0,0]
                kwargs.rotation (1,3) = [0,0,0]
                kwargs.rotation_rate (1,3) = [0,0,0]
            end

            obj.tx_ = tx;
            obj.rx_ = rx;

            if ~libisloaded('radarsimc')
                loadlibrary('radarsimc','radarsim.h');

                % Activate license
                lic_files = dir('license_radarsimc_*.lic');
                for k = 1:length(lic_files)
                    calllib('radarsimc', 'Set_License', fullfile(lic_files(k).folder, lic_files(k).name), 'RadarSimM');
                end

                version_ptr = libpointer("int32Ptr", zeros(1, 3));

                calllib('radarsimc', 'Get_Version', version_ptr);
                obj.version_ = [num2str(version_ptr.Value(1)), '.', num2str(version_ptr.Value(2)), '.', num2str(version_ptr.Value(3))];
            else
                version_ptr = libpointer("int32Ptr", zeros(1, 3));

                calllib('radarsimc', 'Get_Version', version_ptr);
                obj.version_ = [num2str(version_ptr.Value(1)), '.', num2str(version_ptr.Value(2)), '.', num2str(version_ptr.Value(3))];
            end

            obj.frame_start_time_ = kwargs.frame_time;
            frame_start_time_ptr = libpointer("doublePtr",obj.frame_start_time_);

            radar_loc_ptr=libpointer("singlePtr",kwargs.location);
            radar_spd_ptr=libpointer("singlePtr",kwargs.speed);
            radar_rot_ptr=libpointer("singlePtr",kwargs.rotation);
            radar_rrt_ptr=libpointer("singlePtr",kwargs.rotation_rate);

            obj.radar_ptr=calllib('radarsimc', 'Create_Radar', obj.tx_.tx_ptr, obj.rx_.rx_ptr, frame_start_time_ptr, length(obj.frame_start_time_), radar_loc_ptr, radar_spd_ptr, radar_rot_ptr, radar_rrt_ptr);

            obj.num_tx_ = calllib('radarsimc', 'Get_Num_Txchannel', obj.tx_.tx_ptr);
            obj.num_rx_ = calllib('radarsimc', 'Get_Num_Rxchannel', obj.rx_.rx_ptr);
            obj.num_frame_ = length(obj.frame_start_time_);

            obj.samples_per_pulse_ = floor(obj.tx_.pulse_duration_*obj.rx_.fs_);

            obj.timestamp_=repmat((0:1:(obj.samples_per_pulse_-1)).'/obj.rx_.fs_, 1, obj.tx_.pulses_, obj.num_tx_*obj.num_rx_*obj.num_frame_)+ ...
                repmat(obj.tx_.pulse_start_time_, obj.samples_per_pulse_,1, obj.num_tx_*obj.num_rx_*obj.num_frame_)+ ...
                permute(repmat(reshape(repmat(obj.tx_.delay_, obj.num_rx_, 1), 1,[]).',1, obj.samples_per_pulse_, obj.tx_.pulses_), [2, 3,1]);

        end

        % Get license information
        % Returns the license information string from the license manager.
        %
        % Returns:
        %   license_info (string): License information string.
        function license_info = get_license_info(obj)
            buffer_size = 1024;
            buffer_ptr = libpointer('cstring', blanks(buffer_size));
            actual_length = calllib('radarsimc', 'Get_License_Info', buffer_ptr, buffer_size);
            license_info = string(buffer_ptr.Value);
        end

        % Reset radar
        % Resets the radar system by freeing the radar pointer.
        function reset(obj)
            if obj.radar_ptr~=0
                calllib('radarsimc','Free_Radar',obj.radar_ptr);
            end
            obj.radar_ptr=0;
        end

        % Delete radar
        % Destructor for the Radar class.
        % Frees the radar pointer and unloads the radar library if loaded.
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