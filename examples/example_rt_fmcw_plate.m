%% FMCW Radar with a Plate
%
% Compare to RadarSimPy example at https://radarsimx.com/2021/05/10/fmcw-radar-with-a-plate/
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

%% Transmitter

f=[1e9-50e6, 1e9+50e6];
t=80e-6;
bw = abs(f(2)-f(1));
fc = sum(f)/2;
prp = 0.5;
num_pulses = 180;

tx = RadarSim.Transmitter(f, t, 'tx_power',15, 'prp', prp, 'pulses',num_pulses, 'channels', {RadarSim.TxChannel([0 0 0])});

%% Receiver

fs=2e6;
noise_figure=8;
rf_gain=20;
resistor=500;
bb_gain=30;
rx = RadarSim.Receiver(fs, rf_gain, resistor, bb_gain, 'noise_figure', noise_figure, 'channels', {RadarSim.RxChannel([0 0 0])});

%% Radar

radar = RadarSim.Radar(tx, rx);

%% Targets
plate = stlread('../models/plate5x5.stl');

targets = {};
targets{1} = RadarSim.MeshTarget(plate.Points, ...
    plate.ConnectivityList, ...
    [200, 0, 0], ...
    [0, 0, 0], ...
    [0, 0, 0], ...
    [1, 0, 0]);

figure();
trimesh(plate,'FaceColor','green','FaceAlpha', 0.6, 'EdgeColor','blue')
axis equal;
xlabel('x (m)');
ylabel('y (m)');
zlabel('z (m)');

%% Run Simulation
simc = RadarSim.Simulator();
tic;
simc.Run(radar, targets, 'noise', false, 'density', 1, 'level','pulse');
toc;

baseband=simc.baseband_;
timestamp=simc.timestamp_;

%% Range Profile

range_profile=fft(baseband.*repmat(chebwin(160,60),1,180), [], 1);

max_range = (3e8 * fs * t / bw / 2);

figure();
surf(0:(num_pulses-1), linspace(0, max_range, radar.samples_per_pulse_), 20*log10(abs(range_profile(:,:,1))));
shading interp;
title('Range Profile');
xlabel('Chirp');
ylabel('Range (m)');
zlabel('Amplitude (dB)');
colormap jet;
colorbar;
view(2);
axis tight;

obs_angle = 0:0.5:89.5;

figure();
plot(obs_angle, 20*log10(abs(range_profile(134,:,1))), 'LineWidth',1.5);
shading interp;
xlabel('Observation angle (deg)');
ylabel('Peak amplitude (dB)');
grid on;

