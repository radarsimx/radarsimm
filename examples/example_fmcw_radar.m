%% FMCW Radar
%
% Compare to RadarSimPy example at https://radarsimx.com/2018/10/11/fmcw-radar/
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

az_angle = -80:1:80;
az_pattern = 20 * log10(cos(az_angle / 180 * pi).^4) + 6;

el_angle = -80:1:80;
el_pattern = 20 * log10((cos(el_angle / 180 * pi)).^20) + 6;

tx_ch = RadarSim.TxChannel([0 0 0], ...
    'azimuth_angle', az_angle, ...
    'azimuth_pattern', az_pattern, ...
    'elevation_angle', el_angle, ...
    'elevation_pattern', el_pattern);

%% Transmitter

f=[24.075e9, 24.175e9];
t=80e-6;
bw = abs(f(2)-f(1));
fc = sum(f)/2;
prp = 100e-6;
num_pulses = 256;

tx=RadarSim.Transmitter(f, t, 'tx_power',10, 'prp', prp, 'pulses',num_pulses, 'channels',{tx_ch});

%% Receiver channel

rx_ch = RadarSim.RxChannel([0 0 0], ...
    'azimuth_angle', az_angle, ...
    'azimuth_pattern', az_pattern, ...
    'elevation_angle', el_angle, ...
    'elevation_pattern', el_pattern);

%% Receiver

fs=2e6;
noise_figure=12;
rf_gain=20;
resistor=500;
bb_gain=30;
rx = RadarSim.Receiver(fs, rf_gain, resistor, bb_gain, 'noise_figure', noise_figure, 'channels',{rx_ch});

%% Radar

radar = RadarSim.Radar(tx, rx);

%% Targets

targets={};
targets{1} = RadarSim.PointTarget([200 0 0], [-5 0 0], 20);
targets{2} = RadarSim.PointTarget([95 20 0], [-50 0 0], 15);
targets{3} = RadarSim.PointTarget([30 -5 0], [-22 0 0], 5);

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

%% Range Profile

range_profile=fft(baseband.*repmat(chebwin(160,60),1,256), [], 1);

max_range = (3e8 * fs * t / bw / 2);

figure();
surf(0:(num_pulses-1), linspace(0, max_range, radar.samples_per_pulse_), 20*log10(abs(range_profile(:,:,1))));
shading interp;
title('Range Profile');
xlabel('Chirp');
ylabel('Range (m)');
zlabel('Amplitude (dB)');
axis tight;
colormap jet;
colorbar;

%% Range-Doppler

rdop = fft(range_profile.*repmat(chebwin(256,60).',160,1), [], 2);

unambiguous_speed = 3e8/prp/fc/2;

figure();
surf(linspace(-unambiguous_speed, 0, num_pulses), linspace(0, max_range, radar.samples_per_pulse_), 20*log10(abs(rdop(:,:,1))));
shading interp;
title('Range Doppler');
xlabel('Velocity (m/s)');
ylabel('Range (m)');
zlabel('Amplitude (dB)');
axis tight;
colormap jet;
colorbar;

