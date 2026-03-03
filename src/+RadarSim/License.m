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


classdef License
    % License - Class for handling RadarSimM license management
    %
    % This class provides static methods for managing RadarSimM licenses,
    % including activating license files and retrieving license information.
    
    methods (Static)
        
        % Activate license file(s)
        % If a license file path is provided, activates that specific file.
        % If no path is provided, searches the package directory for all
        % license files matching 'license_RadarSimM_*.lic' pattern.
        %
        % Parameters:
        %   lic_path (string): Path to a specific license file.
        %                      If not specified, searches the package directory.
        %
        % Example:
        %   RadarSim.License.set_license();
        %   RadarSim.License.set_license('/path/to/license_RadarSimM_M1772546579.lic');
        function set_license(lic_path)
            arguments
                lic_path {mustBeTextScalar} = ''
            end
            
            % Check if library is loaded
            if ~libisloaded('radarsimc')
                error('RadarSim:License:LibraryNotLoaded', ...
                    'radarsimc library must be loaded before activating license.');
            end
            
            % If a specific file path is provided
            if ~isempty(lic_path) && strlength(lic_path) > 0
                % Check if file exists
                if ~isfile(lic_path)
                    error('RadarSim:License:FileNotFound', ...
                        'License file not found: %s', lic_path);
                end
                % Activate the specific license file
                calllib('radarsimc', 'Set_License', lic_path, 'RadarSimM');
            else
                % No path provided - search in package directory
                pkg_dir = fileparts(mfilename('fullpath'));
                lic_files = dir(fullfile(pkg_dir, 'license_RadarSimM_*.lic'));
                
                if isempty(lic_files)
                    warning('RadarSim:License:NoLicenseFiles', ...
                        'No license files found in directory: %s', pkg_dir);
                    return;
                end
                
                % Activate each license file found
                for k = 1:length(lic_files)
                    file_path = fullfile(lic_files(k).folder, lic_files(k).name);
                    calllib('radarsimc', 'Set_License', file_path, 'RadarSimM');
                end
            end
        end
        
        % Get license information
        % Returns the license information string from the license manager.
        %
        % Returns:
        %   license_info (string): License information string.
        %
        % Example:
        %   info = RadarSim.License.get_info();
        function license_info = get_info()
            % Check if library is loaded
            if ~libisloaded('radarsimc')
                error('RadarSim:License:LibraryNotLoaded', ...
                    'radarsimc library must be loaded before getting license info.');
            end
            
            buffer_size = 1024;
            buffer_ptr = libpointer('cstring', blanks(buffer_size));
            actual_length = calllib('radarsimc', 'Get_License_Info', buffer_ptr, buffer_size);
            license_info = string(buffer_ptr.Value);
        end
        
        % Set a specific license file
        % Activates a single license file by its full path.
        %
        % Parameters:
        %   license_path (string): Full path to the license file.
        %   product_name (string): Product name (default: 'RadarSimM').
        %
        % Example:
        %   RadarSim.License.set('/path/to/license.lic');
        function set(license_path, product_name)
            arguments
                license_path {mustBeTextScalar, mustBeFile}
                product_name {mustBeTextScalar} = 'RadarSimM'
            end
            
            % Check if library is loaded
            if ~libisloaded('radarsimc')
                error('RadarSim:License:LibraryNotLoaded', ...
                    'radarsimc library must be loaded before setting license.');
            end
            
            calllib('radarsimc', 'Set_License', license_path, product_name);
        end
        
    end
end
