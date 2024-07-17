%% Multi-Path Effect
%
% Compare to RadarSimPy example at https://radarsimx.com/2021/05/10/multi-path-effect/
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

%% Case 1: A corner reflector with ground surface

% Transmitter

f=[76.5e9-80e6, 76.5e9+80e6];
t=20e-6;
bw = abs(f(2)-f(1));
fc = sum(f)/2;
prp = 100e-6;
num_pulses = 1;
frame_time = 0:1:289;

tx = RadarSim.Transmitter(f, t, 'tx_power', 15, 'prp', prp, 'pulses', num_pulses, 'frame_time', frame_time, 'channels', {RadarSim.TxChannel([0 0 0])});

% Receiver

fs=20e6;
noise_figure=8;
rf_gain=20;
resistor=1000;
bb_gain=80;
rx = RadarSim.Receiver(fs, rf_gain, resistor, bb_gain, 'noise_figure', noise_figure, 'channels', {RadarSim.RxChannel([0 0 0])});

% Radar

radar = RadarSim.Radar(tx, rx);

% Targets
tg1=stlread('../models/cr.stl');

targets = {};
targets{1} = RadarSim.MeshTarget(tg1.Points, ...
    tg1.ConnectivityList, ...
    [300, 0, 0], ...
    [-1, 0, 0], ...
    [0, 0, 0], ...
    [0, 0, 0]);

tg2=stlread('../models/surface_400x400.stl');

targets{2} = RadarSim.MeshTarget(tg2.Points, ...
    tg2.ConnectivityList, ...
    [0, 0, -0.5], ...
    [0, 0, 0], ...
    [0, 0, 0], ...
    [0, 0, 0], ...
    'permittivity', 3.2+0.1i, ...
    'is_ground', true);


% Run Simulation
simc = RadarSim.Simulator();
tic;
simc.Run(radar, targets, 'noise', false, 'density', 0.5);
toc;

baseband=simc.baseband_;

% Range Profile

range_profile=fft(baseband.*repmat(chebwin(400,60),1,1,290), [], 1);

t_range = 10+(289:-1:0)*1;

amp_multi = squeeze(max(20*log10(abs(range_profile)), [], 1));


%% Case 2: A corner reflector without ground surface

% Transmitter

f=[76.5e9-80e6, 76.5e9+80e6];
t=20e-6;
bw = abs(f(2)-f(1));
fc = sum(f)/2;
prp = 100e-6;
num_pulses = 1;
frame_time = 0:1:289;

tx = RadarSim.Transmitter(f, t, 'tx_power', 15, 'prp', prp, 'pulses', num_pulses, 'frame_time', frame_time, 'channels', {RadarSim.TxChannel([0 0 0])});

% Receiver

fs=20e6;
noise_figure=8;
rf_gain=20;
resistor=1000;
bb_gain=80;
rx = RadarSim.Receiver(fs, rf_gain, resistor, bb_gain, 'noise_figure', noise_figure, 'channels', {RadarSim.RxChannel([0 0 0])});

% Radar

radar = RadarSim.Radar(tx, rx);

% Targets
tg1=stlread('../models/cr.stl');

targets = {};
targets{1} = RadarSim.MeshTarget(tg1.Points, ...
    tg1.ConnectivityList, ...
    [300, 0, 0], ...
    [-1, 0, 0], ...
    [0, 0, 0], ...
    [0, 0, 0]);


% Run Simulation

tic;
simc.Run(radar, targets, 'noise', false, 'density', 0.5);
toc;

baseband=simc.baseband_;

% Range Profile

range_profile=fft(baseband.*repmat(chebwin(400,60),1,1,290), [], 1);

amp_single = squeeze(max(20*log10(abs(range_profile)), [], 1));

%% Plot

figure();
plot(t_range, amp_multi, 'LineWidth',1.5);
hold on;
plot(t_range, amp_single, 'LineWidth',1.5);
xlabel('Target Range (m)');
ylabel('Amplitude (dB)');

legend('CR with Ground', 'CR without Ground');
axis tight;
grid on;
