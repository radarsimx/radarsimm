%% FMCW Radar with a Corner Reflector
%
% Compare to RadarSimPy example at https://radarsimx.com/2021/05/10/fmcw-radar-with-a-corner-reflector/
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
num_pulses = 256;

tx = RadarSim.Transmitter(f, t, 'tx_power',25, 'prp', prp, 'pulses', num_pulses, 'channels', {RadarSim.TxChannel([0 0 0])});

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
cr=stlread('../models/cr.stl');

targets = {};
targets{1} = RadarSim.MeshTarget(cr.Points, ...
    cr.ConnectivityList, ...
    [50, 0, 0], ...
    [-5, 0, 0], ...
    [0, 0, 0], ...
    [0, 0, 0]);

figure();
trimesh(cr,'FaceColor','green','FaceAlpha', 0.6, 'EdgeColor','blue')
axis equal;
xlabel('x (m)');
ylabel('y (m)');
zlabel('z (m)');

%% Run Simulation

simc = RadarSim.Simulator();
tic;
simc.Run(radar, targets, 'noise', true, 'density', 0.2);
toc;

baseband=simc.baseband_;
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
colormap jet;
colorbar;
axis tight;

