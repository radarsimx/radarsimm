classdef Radar < handle
    properties (Access = public)
        version_ = '';

    end

    methods (Access = public)

        % Construct app
        function obj = Radar()
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