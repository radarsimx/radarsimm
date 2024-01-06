%% Imaging Radar
%
% Compare to RadarSimPy example at https://radarsimx.com/2022/12/02/imaging-radar/
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

wavelength = 3e8 / 60.5e9;
N_tx = 64;
N_rx = 128;

f=[61e9, 60e9];
t=16e-6;
bw = abs(f(2)-f(1));
fc = sum(f)/2;
prp = 40e-6;
num_pulses = 1;

rsim_obj.init_transmitter(f, t, 'tx_power',15, 'prp', prp, 'pulses',num_pulses);

%% Transmitter channel

for idx=1:N_tx/2
    rsim_obj.add_txchannel([0, -N_rx/2*wavelength/4, wavelength*(idx-1)-(N_tx/2-1)*wavelength/2]);
end

for idx=1:N_tx/2
    rsim_obj.add_txchannel([0, wavelength*N_rx/4-N_rx/2*wavelength/4, wavelength*(idx-1)-(N_tx/2-1)*wavelength/2]);
end


%% Receiver

fs=20e6;
noise_figure=8;
rf_gain=20;
resistor=500;
bb_gain=30;
rsim_obj.init_receiver(fs, rf_gain, resistor, bb_gain, 'noise_figure', noise_figure);

%% Receiver channel

for idx=1:N_rx/2
    rsim_obj.add_rxchannel([0, wavelength/2*(idx-1)-(N_rx/2-1)*wavelength/4, -(N_tx/2)*wavelength/2]);
end

for idx=1:N_rx/2
    rsim_obj.add_rxchannel([0, wavelength/2*(idx-1)-(N_rx/2-1)*wavelength/4, wavelength*(N_tx/2)-(N_tx/2)*wavelength/2]);
end


%% Targets
tg1=stlread('./models/half_ring.stl');

rsim_obj.add_mesh_target(tg1.Points, ...
    tg1.ConnectivityList, ...
    [20, 0, 0], ...
    [0, 0, 0], ...
    [0, 0, 0], ...
    [0, 0, 0]);

tg2=stlread('./models/ball_1m.stl');

rsim_obj.add_mesh_target(tg2.Points, ...
    tg2.ConnectivityList, ...
    [20, -1, -1], ...
    [0, 0, 0], ...
    [0, 0, 0], ...
    [0, 0, 0]);

tg3=stlread('./models/ball_1m.stl');

rsim_obj.add_mesh_target(tg3.Points, ...
    tg3.ConnectivityList, ...
    [20, 1, -1], ...
    [0, 0, 0], ...
    [0, 0, 0], ...
    [0, 0, 0]);

% figure();
% trimesh(tg1,'FaceColor','green','FaceAlpha', 0.6, 'EdgeColor','blue')
% axis equal;
% xlabel('x (m)');
% ylabel('y (m)');
% zlabel('z (m)');

%% Run Simulation

tic;
rsim_obj.run_simulator('noise', true, 'density', 0.3);
toc;

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

range_profile=fft(conj(baseband).*repmat(chebwin(320,80),1,1,8192), [], 1);

range_profile_avg=mean(abs(range_profile), 3);

max_range = (3e8 * fs * t / bw / 2);

figure();
plot(linspace(0, max_range, rsim_obj.samples_), 20*log10(range_profile_avg));

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

