classdef RadarSim < handle
    properties (Access = public)
        version = '1.0';
    end

    properties (Access = private)
        tx_ptr;
        rx_ptr;
        radar_ptr;
        targets_ptr;
        simulator_ptr;
    end

    methods (Access = public)

        % Construct app
        function obj = RadarSim()
        end

        function init_transmitter(obj)
        end

        function add_txchannel(obj)
        end

        function init_receiver(obj)
        end

        function add_rxchannel(obj)
        end

        function add_target(obj)
        end

        function run_simulator(obj)
        end

        function delete(obj)
        end

    end

end