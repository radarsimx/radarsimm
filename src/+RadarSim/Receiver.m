classdef Receiver < handle
    properties (Access = public)
        version_ = '';
        fs_;
        noise_figure_;
        rf_gain_;
        baseband_gain_;
        load_resistor_;
        noise_bandwidth_;
        rx_ptr=0;
    end

    methods (Access = public)

        % Construct app
        function obj = Receiver(fs, rf_gain, load_resistor, baseband_gain, kwargs)
            arguments
                fs
                rf_gain
                load_resistor
                baseband_gain
                kwargs.noise_figure = 0
                kwargs.channels = {}
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

            obj.fs_ = fs;
            obj.noise_figure_ = kwargs.noise_figure;
            obj.rf_gain_ = rf_gain;
            obj.baseband_gain_ = baseband_gain;
            obj.load_resistor_ = load_resistor;
            obj.noise_bandwidth_ = fs;

            obj.rx_ptr = calllib('radarsimc', 'Create_Receiver', obj.fs_, obj.rf_gain_, obj.load_resistor_, ...
                obj.baseband_gain_);

            for ch_idx=1:length(kwargs.channels)
                obj.add_rxchannel(kwargs.channels{ch_idx});
            end
        end

        function add_rxchannel(obj, rx_ch)
            arguments
                obj
                rx_ch RadarSim.RxChannel
            end

            location_ptr=libpointer("singlePtr",rx_ch.location_);
            polar_real_ptr=libpointer("singlePtr",real(rx_ch.polarization_));
            polar_imag_ptr=libpointer("singlePtr",imag(rx_ch.polarization_));

            phi_ptr = libpointer("singlePtr",rx_ch.phi_);
            phi_ptn_ptr = libpointer("singlePtr",rx_ch.phi_ptn_);

            theta_ptr = libpointer("singlePtr",rx_ch.theta_);
            theta_ptn_ptr = libpointer("singlePtr",rx_ch.theta_ptn_);

            calllib('radarsimc', 'Add_Rxchannel', location_ptr, polar_real_ptr, polar_imag_ptr, ...
                phi_ptr, phi_ptn_ptr, length(rx_ch.phi_), ...
                theta_ptr, theta_ptn_ptr, length(rx_ch.theta_), rx_ch.antenna_gain_, ...
                obj.rx_ptr);
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