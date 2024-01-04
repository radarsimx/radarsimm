%% FMCW Radar
%
% Compare to RadarSimPy example at https://radarsimx.com/2021/05/10/fmcw-radar-with-a-corner-reflector/
%

clear;

%% Create RadarSim handle

rsim_obj=RadarSim;

%% Transmitter

f=[77e9-50e6, 77e9+50e6];
t=80e-6;
bw = abs(f(2)-f(1));
fc = sum(f)/2;
prp = 100e-6;
num_pulses = 256;

rsim_obj.init_transmitter(f, t, 'tx_power',25, 'prp', prp, 'pulses',num_pulses);

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
cr=stlread('./models/cr.stl');

rsim_obj.add_mesh_target(cr.Points, ...
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

rsim_obj.run_simulator('noise', true, 'density', 0.2);
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

%% Range Profile

range_profile=fft(baseband.*repmat(chebwin(160,60),1,256), [], 1);

max_range = (3e8 * fs * t / bw / 2);

%% Range-Doppler

rdop = fft(range_profile.*repmat(chebwin(256,60).',160,1), [], 2);

unambiguous_speed = 3e8/prp/fc/2;

figure();
surf(linspace(-unambiguous_speed, 0, num_pulses), linspace(0, max_range, rsim_obj.samples_), 20*log10(abs(rdop(:,:,1))));
shading interp;
title('Range Doppler');
xlabel('Velocity (m/s)');
ylabel('Range (m)');
zlabel('Amplitude (dB)');
colormap jet;
colorbar;

