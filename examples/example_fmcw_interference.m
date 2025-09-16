%% FMCW Radar Interference
%
% Compare to RadarSimPy example at https://radarsimx.com/2023/01/13/interference/
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

%% 

int_tx_ch = RadarSim.TxChannel([0 0.1 0], ...
    'pulse_phs', [0, 0, 180, 0, 0, 0, 0, 0]);

% Transmitter

int_f=[60.4e9, 60.6e9];
int_t=[0, 8e-6];
int_prp = 11e-6;
int_num_pulses = 8;
int_f_offset = (0:7) * 70e6;

int_tx=RadarSim.Transmitter(int_f, int_t, 'tx_power',15, 'prp', int_prp, 'pulses',int_num_pulses, 'f_offset', int_f_offset, 'channels',{int_tx_ch});

% Receiver channel

int_rx_ch = RadarSim.RxChannel([0 0.1 0]);

% Receiver

fs=20e6;
noise_figure=8;
rf_gain=20;
resistor=500;
bb_gain=30;
int_rx = RadarSim.Receiver(fs, rf_gain, resistor, bb_gain, 'noise_figure', noise_figure, 'channels',{int_rx_ch});

% Radar

int_radar = RadarSim.Radar(int_tx, int_rx, location=[30, 0, 0], rotation=[180, 0, 0]);

%%

tx_ch = RadarSim.TxChannel([0 0 0], ...
    'pulse_phs', [180, 0, 0, 0]);

% Transmitter

f=[60.6e9, 60.4e9];
t=[0, 16e-6];
bw = abs(f(2)-f(1));
fc = sum(f)/2;
prp = 20e-6;
num_pulses = 4;
f_offset = (0:3) * 90e6;

tx=RadarSim.Transmitter(f, t, 'tx_power',25, 'prp', prp, 'pulses',num_pulses, 'f_offset', f_offset, 'channels',{tx_ch});

% Receiver channel

rx_ch = RadarSim.RxChannel([0 0.1 0]);

% Receiver

fs=40e6;
noise_figure=2;
rf_gain=20;
resistor=500;
bb_gain=60;
rx = RadarSim.Receiver(fs, rf_gain, resistor, bb_gain, 'noise_figure', noise_figure, 'channels',{rx_ch});

% Radar

radar = RadarSim.Radar(tx, rx);

%% Targets

targets={};
targets{1} = RadarSim.PointTarget([30 0 0], [0 0 0], 10);
targets{2} = RadarSim.PointTarget([20 1 0], [-10 0 0], 10);

%% Run Simulation

simc = RadarSim.RadarSimulator();
simc.Run(radar, targets, 'noise', false, 'interf', int_radar);

baseband=simc.baseband_;
timestamp=simc.timestamp_;
interference=simc.interference_;

interf_bb = baseband+interference;

%%
figure();
for idx=1:num_pulses
    subplot(2,1,1), plot([timestamp(1, idx, 1),timestamp(end,idx, 1)], f+f_offset(idx), 'LineWidth',1.5);
    hold on;
    subplot(2,1,2), plot(timestamp(:,idx, 1), real(interf_bb(:,idx,1)));
    hold on;
    subplot(2,1,2), plot(timestamp(:,idx, 1), imag(interf_bb(:,idx,1)));
end

for idx=1:int_num_pulses
    subplot(2,1,1), plot([int_radar.timestamp_(1, idx, 1),int_radar.timestamp_(end,idx, 1)], int_f+int_f_offset(idx), 'k', 'LineWidth',1.5);
    hold on;
end

subplot(2,1,1), axis([0, 8e-5, 60.4e9, 61e9]);
xlabel('Time (s)');
ylabel('Frequency (Hz)');
grid on;
hold off;
subplot(2,1,2), axis([0, 8e-5, -0.5, 0.5]);
hold off;
xlabel('Time (s)');
ylabel('Amplitude (V)');
grid on;
