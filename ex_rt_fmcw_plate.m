%% FMCW Radar
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

%% Create RadarSim handle

rsim_obj=RadarSim;

%% Transmitter

f=[1e9-50e6, 1e9+50e6];
t=80e-6;
bw = abs(f(2)-f(1));
fc = sum(f)/2;
prp = 0.5;
num_pulses = 180;

rsim_obj.init_transmitter(f, t, 'tx_power',15, 'prp', prp, 'pulses',num_pulses);

%% Transmitter channel

rsim_obj.add_txchannel([0 0 0]);

%% Receiver

fs=2e6;
noise_figure=8;
rf_gain=20;
resistor=500;
bb_gain=30;
rsim_obj.init_receiver(fs, rf_gain, resistor, bb_gain, 'noise_figure', noise_figure);

%% Receiver channel

rsim_obj.add_rxchannel([0 0 0]);

%% Targets
plate = stlread('./models/plate5x5.stl');

rsim_obj.add_mesh_target(plate.Points, ...
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
tic;
rsim_obj.run_simulator('noise', false, 'density', 1, 'level','pulse');
toc;

baseband=rsim_obj.baseband_;
timestamp=rsim_obj.timestamp_;

%% Range Profile

range_profile=fft(baseband.*repmat(chebwin(160,60),1,180), [], 1);

max_range = (3e8 * fs * t / bw / 2);

figure();
surf(0:(num_pulses-1), linspace(0, max_range, rsim_obj.samples_), 20*log10(abs(range_profile(:,:,1))));
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
plot(obs_angle, 20*log10(abs(range_profile(134,:,1))))
shading interp;
xlabel('Observation angle (deg)');
ylabel('Peak amplitude (dB)');
grid on;

