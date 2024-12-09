%% Doppler Radar
%
% Compare to RadarSimPy example at https://radarsimx.com/2019/05/16/doppler-radar/
%
% ██████╗  █████╗ ██████╗  █████╗ ██████╗ ███████╗██╗███╗   ███╗██╗  ██╗
% ██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔════╝██║████╗ ████║╚██╗██╔╝
% ██████╔╝███████║██║  ██║███████║██████╔╝███████╗██║██╔████╔██║ ╚███╔╝
% ██╔══██╗██╔══██║██║  ██║██╔══██║██╔══██╗╚════██║██║██║╚██╔╝██║ ██╔██╗
% ██║  ██║██║  ██║██████╔╝██║  ██║██║  ██║███████║██║██║ ╚═╝ ██║██╔╝ ██╗
% ╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝╚═╝     ╚═╝╚═╝  ╚═╝

clear;

%% Add path of the module

addpath("../src");

%% Transmitter channel

tx_ch = RadarSim.TxChannel([0 0 0]);

%% Transmitter

f=10e9;
t=0.1;
num_pulses = 1;

tx = RadarSim.Transmitter(f, t, 'tx_power',10, 'pulses',num_pulses, 'channels',{tx_ch});

%% Receiver channel

rx_ch = RadarSim.RxChannel([0 0 0]);

%% Receiver

fs=40000;
noise_figure=6;
rf_gain=20;
resistor=1000;
bb_gain=50;
rx = RadarSim.Receiver(fs, rf_gain, resistor, bb_gain, 'noise_figure', noise_figure, 'channels',{rx_ch});

%% Radar

radar = RadarSim.Radar(tx, rx);

%% Targets

targets={};
targets{1} = RadarSim.PointTarget([30 0 0], [-10 0 0], 20, 'phase', 0);
targets{2} = RadarSim.PointTarget([35 0 0], [35 0 0], 20, 'phase', 0);

%% Run Simulation

simc = RadarSim.Simulator();
simc.Run(radar, targets, 'noise', true);

baseband=simc.baseband_+simc.noise_;
timestamp=simc.timestamp_;

figure();
plot(timestamp(:,1,1), real(baseband(:,1,1)), 'LineWidth',1.5);
hold on;
plot(timestamp(:,1,1), imag(baseband(:,1,1)), 'LineWidth',1.5);
hold off;
grid on;
title('I/Q Baseband Signals');
xlabel('Time (s)');
ylabel('Amplitude (V)');

legend('I','Q');

%% Doppler Radar Signal Processing

spec = fftshift(fft(baseband(:, 1, 1)));

speed = linspace(-fs/2, fs/2, radar.samples_per_pulse_)*3e8/2/10e9;

figure();
plot(speed, 20*log10(abs(spec)), 'LineWidth',1.5);
grid on;
xlabel('Speed (m/s)');
ylabel('Magnitude (dB)');

