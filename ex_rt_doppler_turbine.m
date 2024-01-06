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

%% Create RadarSim handle

rsim_obj=RadarSim;

%% Transmitter

f=24.125e9;
t=20;
num_pulses = 1;

rsim_obj.init_transmitter(f, t, 'tx_power',20, 'pulses',num_pulses);

%% Transmitter channel

rsim_obj.add_txchannel([0 0 0]);

%% Receiver

fs=800;
noise_figure=4;
rf_gain=20;
resistor=1000;
bb_gain=50;
rsim_obj.init_receiver(fs, rf_gain, resistor, bb_gain, 'noise_figure', noise_figure);

%% Receiver channel

rsim_obj.add_rxchannel([0 0 0]);

%% Targets
turbine = stlread('./models/turbine.stl');

rsim_obj.add_mesh_target(turbine.Points, ...
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

rsim_obj.run_simulator('noise', true, 'density', 2, 'level', 'sample');
baseband=rsim_obj.baseband_;
timestamp=rsim_obj.timestamp_;

figure();
plot(timestamp(:,1,1), real(baseband(:,1,1)));
hold on;
plot(timestamp(:,1,1), imag(baseband(:,1,1)));
hold off;
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
