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

%% Add path of the module

addpath("../src");

%% Transmitter channel
wavelength = 3e8 / 60.5e9;
N_tx = 64;
N_rx = 128;

tx_ch = {};
tx_cnt = 1;
for idx=1:N_tx/2
    tx_ch{tx_cnt} = RadarSim.TxChannel([0, -N_rx/2*wavelength/4, wavelength*(idx-1)-(N_tx/2-1)*wavelength/2]);
    tx_cnt = tx_cnt+1;
end

for idx=1:N_tx/2
    tx_ch{tx_cnt} = RadarSim.TxChannel([0, wavelength*N_rx/4-N_rx/2*wavelength/4, wavelength*(idx-1)-(N_tx/2-1)*wavelength/2]);
    tx_cnt = tx_cnt+1;
end

%% Transmitter

f=[61e9, 60e9];
t=16e-6;
bw = abs(f(2)-f(1));
fc = sum(f)/2;
prp = 40e-6;
num_pulses = 1;

tx = RadarSim.Transmitter(f, t, 'tx_power',15, 'prp', prp, 'pulses', num_pulses, 'channels', tx_ch);

%% Receiver channel

rx_ch = {};
rx_cnt = 1;
for idx=1:N_rx/2
    rx_ch{rx_cnt} = RadarSim.RxChannel([0, wavelength/2*(idx-1)-(N_rx/2-1)*wavelength/4, -(N_tx/2)*wavelength/2]);
    rx_cnt = rx_cnt+1;
end

for idx=1:N_rx/2
    rx_ch{rx_cnt} = RadarSim.RxChannel([0, wavelength/2*(idx-1)-(N_rx/2-1)*wavelength/4, wavelength*(N_tx/2)-(N_tx/2)*wavelength/2]);
    rx_cnt = rx_cnt+1;
end

%% Receiver

fs=20e6;
noise_figure=8;
rf_gain=20;
resistor=500;
bb_gain=30;
rx = RadarSim.Receiver(fs, rf_gain, resistor, bb_gain, 'noise_figure', noise_figure, 'channels', rx_ch);

%% Radar

radar = RadarSim.Radar(tx, rx);

%% Targets
tg1=stlread('../models/half_ring.stl');

targets = {};
targets{1} = RadarSim.MeshTarget(tg1.Points, ...
    tg1.ConnectivityList, ...
    [20, 0, 0], ...
    [0, 0, 0], ...
    [0, 0, 0], ...
    [0, 0, 0]);

tg2=stlread('../models/ball_1m.stl');

targets{2} = RadarSim.MeshTarget(tg2.Points, ...
    tg2.ConnectivityList, ...
    [20, -1, -1], ...
    [0, 0, 0], ...
    [0, 0, 0], ...
    [0, 0, 0]);

tg3=stlread('../models/ball_1m.stl');

targets{3} = RadarSim.MeshTarget(tg3.Points, ...
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

simc = RadarSim.Simulator();
tic;
simc.Run(radar, targets, 'noise', true, 'density', 0.3);
toc;

baseband=simc.baseband_;
timestamp=simc.timestamp_;

figure();
plot(timestamp(:,1,1), real(baseband(:,1,1)), 'LineWidth',1.5);
hold on;
plot(timestamp(:,1,1), imag(baseband(:,1,1)), 'LineWidth',1.5);
hold off;
title('I/Q Baseband Signals');
xlabel('Time (s)');
ylabel('Amplitude (V)');
grid on;

legend('I','Q');

%% Range Profile

range_profile=fft(conj(baseband).*repmat(chebwin(320,80),1,1,8192), [], 1);

range_profile_avg=mean(abs(range_profile), 3);

max_range = (3e8 * fs * t / bw / 2);

figure();
plot(linspace(0, max_range, radar.samples_per_pulse_), 20*log10(range_profile_avg), 'LineWidth',1.5);
xlabel('Range (m)');
ylabel('Amplitude (dB)');
grid on;

%% Imaging

[peak, idx] = max(range_profile_avg);
win_el = chebwin(64, 50);
win_az = chebwin(128, 50);

win_mat = repmat(win_el, 1, N_rx).*repmat(win_az.', N_tx, 1);

raw_bv = squeeze(range_profile(idx, 1, :));

bv = zeros(N_tx, N_rx);

half_tx = (N_tx/2);
half_rx = (N_rx/2);

for t_idx=1:half_tx
    bv(t_idx, 1:half_rx) = raw_bv(((t_idx-1)*N_rx+1):((t_idx-1)*N_rx+half_rx));
    bv(t_idx, (half_rx+1):end) = raw_bv(((t_idx+half_tx-1)*N_rx+1):((t_idx+half_tx-1)*N_rx+half_rx));

    bv(t_idx+half_tx, 1:half_rx) = raw_bv(((t_idx-1)*N_rx+half_rx+1):((t_idx-1)*N_rx+N_rx));
    bv(t_idx+half_tx, (half_rx+1):end) = raw_bv(((t_idx+half_tx-1)*N_rx+half_rx+1):((t_idx+half_tx-1)*N_rx+N_rx));
end

spec = 20*log10(abs(fftshift(fft2(bv.*win_mat, 512, 1024))));

figure();
surf(flipud(spec));
shading interp;
view(2), axis tight;
axis equal;