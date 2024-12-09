%% TDM MIMO FMCW Radar
%
% Compare to RadarSimPy example at https://radarsimx.com/2019/04/07/tdm-mimo-fmcw-radar/
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

wavelength = 3e8 / 24.125e9;

angle = -90:1:90;
pattern = 20 * log10(cos(angle / 180 * pi) + 0.01) + 6;

tx_loc = [-12, -8, -4, 0]*wavelength;

tx_ch = {};
tx_ch{1} = RadarSim.TxChannel([0, tx_loc(1), 0], ...
    'azimuth_angle', angle, ...
    'azimuth_pattern', pattern, ...
    'elevation_angle', angle, ...
    'elevation_pattern',pattern, ...
    'delay', 0);

tx_ch{2} = RadarSim.TxChannel([0, tx_loc(2), 0], ...
    'azimuth_angle', angle, ...
    'azimuth_pattern', pattern, ...
    'elevation_angle', angle, ...
    'elevation_pattern',pattern, ...
    'delay', 100e-6);

tx_ch{3} = RadarSim.TxChannel([0, tx_loc(3), 0], ...
    'azimuth_angle', angle, ...
    'azimuth_pattern', pattern, ...
    'elevation_angle', angle, ...
    'elevation_pattern',pattern, ...
    'delay', 200e-6);

tx_ch{4} = RadarSim.TxChannel([0, tx_loc(4), 0], ...
    'azimuth_angle', angle, ...
    'azimuth_pattern', pattern, ...
    'elevation_angle', angle, ...
    'elevation_pattern',pattern, ...
    'delay', 300e-6);

%% Transmitter

f = [24.075e9, 24.175e9];
bw = f(2)-f(1);
t = 80e-6;
num_pulses = 1;
tx_power = 15;

tx = RadarSim.Transmitter(f, t, 'tx_power', tx_power, 'pulses', num_pulses, 'channels', tx_ch);

%% Receiver channel

rx_loc = (0:1:7)*wavelength/2;
rx_ch = {};
for idx = 1:8
    rx_ch{idx} = RadarSim.RxChannel([0, rx_loc(idx), 0], ...
        'azimuth_angle', angle, ...
        'azimuth_pattern', pattern, ...
        'elevation_angle', angle, ...
        'elevation_pattern',pattern);
end

%% Receiver

fs=2e6;
noise_figure=8;
rf_gain=20;
resistor=500;
bb_gain=50;
rx = RadarSim.Receiver(fs, rf_gain, resistor, bb_gain, 'noise_figure', noise_figure, 'channels', rx_ch);

%% Radar

radar = RadarSim.Radar(tx, rx);

%% Targets

targets={};
targets{1} = RadarSim.PointTarget([160, 0, 0], [0, 0, 0], 25);
targets{2} = RadarSim.PointTarget([80, -80, 0], [0, 0, 0], 20);
targets{3} = RadarSim.PointTarget([30, 20, 0], [0, 0, 0], 8);

%% Run Simulation

simc = RadarSim.Simulator();
simc.Run(radar, targets, 'noise', true);
baseband=simc.baseband_+simc.noise_;
timestamp=simc.timestamp_;

%% Range Profile

range_profile=fft(baseband.*repmat(chebwin(160,60),1,1,32), [], 1);
max_range = (3e8 * fs * t / bw / 2);
range_bins = linspace(0, max_range, radar.samples_per_pulse_);

figure();
plot(range_bins, 20*log10(abs(range_profile(:, 1, 1))), 'LineWidth',1.5);
hold on;
plot(range_bins, 20*log10(abs(range_profile(:, 1, 9))), 'LineWidth',1.5);
plot(range_bins, 20*log10(abs(range_profile(:, 1, 17))), 'LineWidth',1.5);
plot(range_bins, 20*log10(abs(range_profile(:, 1, 25))), 'LineWidth',1.5);
hold off;
grid on;
title('Range Profile');
xlabel('Range (m)');
ylabel('Amplitude (dB)');
legend('Channel 1','Channel 2','Channel 3','Channel 4');

%% Digital Beamforming

azimuth = -90:1:90;
virtual_array = (reshape(repmat(tx_loc, 8, 1), 1, [])+repmat(rx_loc, 1, 4))/wavelength;

[az_grid, loc_grid]=meshgrid(azimuth, virtual_array);

A=exp(1i * 2 * pi * loc_grid .* sin(az_grid / 180 * pi));
bf_window = repmat(chebwin(32,50).', radar.samples_per_pulse_, 1);

AF = (A.')*(squeeze(range_profile(:,1,:)).*bf_window).';

figure();
surf(range_bins, azimuth, 20 * log10(abs(AF) + 0.1));
shading interp;
title('Range-Azimuth Map');
xlabel('Range (m)');
ylabel('Azimuth (deg)');
zlabel('Amplitude (dB)');
colorbar;
axis tight;
