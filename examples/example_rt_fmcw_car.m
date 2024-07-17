%% FMCW Radar with a Car
%
% Compare to RadarSimPy example at https://radarsimx.com/2021/05/10/fmcw-radar-with-a-car/
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

f=[77e9-50e6, 77e9+50e6];
t=80e-6;
bw = abs(f(2)-f(1));
fc = sum(f)/2;
prp = 100e-6;
num_pulses = 512;

tx = RadarSim.Transmitter(f, t, 'tx_power',40, 'prp', prp, 'pulses',num_pulses, 'channels', {RadarSim.TxChannel([0 0 0.5])});

%% Receiver

fs=2e6;
noise_figure=8;
rf_gain=20;
resistor=500;
bb_gain=30;
rx = RadarSim.Receiver(fs, rf_gain, resistor, bb_gain, 'noise_figure', noise_figure, 'channels', {RadarSim.RxChannel([0 0 0.5])});

%% Radar

radar = RadarSim.Radar(tx, rx);

%% Targets
car = stlread('../models/vehicles/ford_raptor.stl');

targets = {};
targets{1} = RadarSim.MeshTarget(car.Points, ...
    car.ConnectivityList, ...
    [150, 0, 0], ...
    [-10, 0, 0], ...
    [180, 0, 0], ...
    [0, 0, 0]);

ground = stlread('../models/surface_400x400.stl');

targets{2} = RadarSim.MeshTarget(ground.Points, ...
    ground.ConnectivityList, ...
    [0, 0, 0], ...
    [0, 0, 0], ...
    [0, 0, 0], ...
    [0, 0, 0], ...
    'permittivity',3.2+0.1i, ...
    'is_ground', true);

figure();
trimesh(car,'FaceColor','green','FaceAlpha', 0.6, 'EdgeColor','blue')
axis equal;
xlabel('x (m)');
ylabel('y (m)');
zlabel('z (m)');

%% Run Simulation
simc = RadarSim.Simulator();
tic;
simc.Run(radar, targets, 'noise', true, 'density', 0.1);
toc;

baseband=simc.baseband_;
timestamp=simc.timestamp_;

%% Range Profile

range_profile=fft(baseband.*repmat(chebwin(160,60),1,512), [], 1);

max_range = (3e8 * fs * t / bw / 2);

%% Range-Doppler

rdop = fft(range_profile.*repmat(chebwin(512,60).',160,1), [], 2);

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

