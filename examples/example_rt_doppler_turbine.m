%% Doppler of a Turbine
%
% Compare to RadarSimPy example at https://radarsimx.com/2021/05/10/doppler-of-a-turbine/
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

f=24.125e9;
t=20;
num_pulses = 1;

tx = RadarSim.Transmitter(f, t, 'tx_power',20, 'pulses',num_pulses, 'channels', {RadarSim.TxChannel([0 0 0])});

%% Receiver

fs=800;
noise_figure=4;
rf_gain=20;
resistor=1000;
bb_gain=50;
rx = RadarSim.Receiver(fs, rf_gain, resistor, bb_gain, 'noise_figure', noise_figure, 'channels', {RadarSim.RxChannel([0 0 0])});

%% Radar

radar = RadarSim.Radar(tx, rx);

%% Targets
turbine = stlread('../models/turbine.stl');

targets = {};
targets{1} = RadarSim.MeshTarget(turbine.Points, ...
    turbine.ConnectivityList, ...
    [8, 0, 0], ...
    [0, 0, 0], ...
    [0, 0, 0], ...
    [0, 50, 0]);

figure();
trimesh(turbine,'FaceColor','green','FaceAlpha', 0.6, 'EdgeColor','blue')
axis equal;
xlabel('x (m)');
ylabel('y (m)');
zlabel('z (m)');

%% Run Simulation

simc = RadarSim.Simulator();
simc.Run(radar, targets, 'noise', true, 'density', 2, 'level', 'sample');

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

%% Short-Time Fourier Transform

[spec, f_axis, t_axis] = stft(squeeze(baseband(:,1,1)), fs);

surf(t_axis, f_axis, 20*log10(abs(spec)));
shading interp;
view(2), axis tight;

xlabel('Time (s)');
ylabel('Doppler (Hz)');
