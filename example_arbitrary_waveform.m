%% Arbitrary Waveform
%
% Compare to RadarSimPy example at https://radarsimx.com/2021/05/10/arbitrary-waveform/
%
% ██████╗  █████╗ ██████╗  █████╗ ██████╗ ███████╗██╗███╗   ███╗██╗  ██╗
% ██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔════╝██║████╗ ████║╚██╗██╔╝
% ██████╔╝███████║██║  ██║███████║██████╔╝███████╗██║██╔████╔██║ ╚███╔╝
% ██╔══██╗██╔══██║██║  ██║██╔══██║██╔══██╗╚════██║██║██║╚██╔╝██║ ██╔██╗
% ██║  ██║██║  ██║██████╔╝██║  ██║██║  ██║███████║██║██║ ╚═╝ ██║██╔╝ ██╗
% ╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝╚═╝     ╚═╝╚═╝  ╚═╝

clear;

%% Non-linear Chirp vs. Linear Chirp

freq_nonlinear = [
    2.40750000e+10, 2.40760901e+10, 2.40771786e+10, 2.40782654e+10, ...
    2.40793506e+10, 2.40804341e+10, 2.40815161e+10, 2.40825964e+10, ...
    2.40836750e+10, 2.40847521e+10, 2.40858275e+10, 2.40869012e+10, ...
    2.40879734e+10, 2.40890439e+10, 2.40901127e+10, 2.40911800e+10, ...
    2.40922456e+10, 2.40933096e+10, 2.40943719e+10, 2.40954326e+10, ...
    2.40964917e+10, 2.40975491e+10, 2.40986049e+10, 2.40996591e+10, ...
    2.41007117e+10, 2.41017626e+10, 2.41028119e+10, 2.41038595e+10, ...
    2.41049055e+10, 2.41059499e+10, 2.41069927e+10, 2.41080338e+10, ...
    2.41090733e+10, 2.41101111e+10, 2.41111473e+10, 2.41121819e+10, ...
    2.41132149e+10, 2.41142462e+10, 2.41152759e+10, 2.41163039e+10, ...
    2.41173304e+10, 2.41183552e+10, 2.41193783e+10, 2.41203999e+10, ...
    2.41214198e+10, 2.41224380e+10, 2.41234546e+10, 2.41244696e+10, ...
    2.41254830e+10, 2.41264947e+10, 2.41275048e+10, 2.41285133e+10, ...
    2.41295202e+10, 2.41305254e+10, 2.41315289e+10, 2.41325309e+10, ...
    2.41335312e+10, 2.41345298e+10, 2.41355269e+10, 2.41365223e+10, ...
    2.41375161e+10, 2.41385082e+10, 2.41394987e+10, 2.41404876e+10, ...
    2.41414748e+10, 2.41424605e+10, 2.41434444e+10, 2.41444268e+10, ...
    2.41454075e+10, 2.41463866e+10, 2.41473640e+10, 2.41483399e+10, ...
    2.41493140e+10, 2.41502866e+10, 2.41512575e+10, 2.41522268e+10, ...
    2.41531945e+10, 2.41541605e+10, 2.41551249e+10, 2.41560876e+10, ...
    2.41570488e+10, 2.41580083e+10, 2.41589661e+10, 2.41599224e+10, ...
    2.41608770e+10, 2.41618299e+10, 2.41627812e+10, 2.41637309e+10, ...
    2.41646790e+10, 2.41656254e+10, 2.41665702e+10, 2.41675134e+10, ...
    2.41684550e+10, 2.41693949e+10, 2.41703331e+10, 2.41712698e+10, ...
    2.41722048e+10, 2.41731381e+10, 2.41740699e+10, 2.41750000e+10];

t_nonlinear = linspace(0, 80e-6, 100);

freq_linear = [24.125e9-50e6, 24.125e9+50e6];
t_linear = [0, 80e-6];

figure();
plot(t_nonlinear*1e6, freq_nonlinear/1e9, 'LineWidth',1.5);
hold on;
plot(t_linear*1e6, freq_linear/1e9, 'LineWidth',1.5);
hold off;
grid on;

xlabel('Time (us)');
ylabel('Frequency (GHz)');
legend('Non-linear chirp','Linear chirp');

%% Create RadarSim handle

rsim_obj = RadarSim;

%% Transmitter Parameters

prp = 100e-6;
num_pulses = 1;

%% Receiver Parameters

fs = 2e6;
noise_figure = 12;
rf_gain = 20;
resistor = 500;
bb_gain = 30;


%% Simulation of nonlinear chirps
% Transmitter

rsim_obj.init_transmitter(freq_nonlinear, t_nonlinear, 'tx_power',60, 'prp', prp, 'pulses',num_pulses);
rsim_obj.add_txchannel([0 0 0]);

% Receiver

rsim_obj.init_receiver(fs, rf_gain, resistor, bb_gain, 'noise_figure', noise_figure);
rsim_obj.add_rxchannel([0 0 0]);

% Targets

rsim_obj.add_point_target([200 0 0], [0 0 0], 30, 0);
rsim_obj.add_point_target([95 20 0], [-50 0 0], 25, 0);
rsim_obj.add_point_target([30 -5 0], [-22 0 0], 15, 0);

% Run Simulation

rsim_obj.run_simulator('noise', true);

baseband_nonlinear = rsim_obj.baseband_;
timestamp_nonlinear = rsim_obj.timestamp_;

%% Simulation of linear chirps
% Reset object

rsim_obj.reset();

% Transmitter

rsim_obj.init_transmitter(freq_linear, t_linear, 'tx_power',60, 'prp', prp, 'pulses',num_pulses);
rsim_obj.add_txchannel([0 0 0]);

% Receiver

rsim_obj.init_receiver(fs, rf_gain, resistor, bb_gain, 'noise_figure', noise_figure);
rsim_obj.add_rxchannel([0 0 0]);

% Targets

rsim_obj.add_point_target([200 0 0], [0 0 0], 30, 0);
rsim_obj.add_point_target([95 20 0], [-50 0 0], 25, 0);
rsim_obj.add_point_target([30 -5 0], [-22 0 0], 15, 0);

% Run Simulation

rsim_obj.run_simulator('noise', true);

baseband_linear = rsim_obj.baseband_;
timestamp_linear = rsim_obj.timestamp_;

%% Range Profile

range_profile_nonlinear = fft(baseband_nonlinear.*repmat(chebwin(160,60),1,1), [], 1);
range_profile_linear = fft(baseband_linear.*repmat(chebwin(160,60),1,1), [], 1);

max_range = (3e8 * fs * 80e-6 / 100e6 / 2);

figure();
plot(linspace(0, max_range, rsim_obj.samples_), 20 * log10(abs(range_profile_nonlinear(:,1))), 'LineWidth',1.5);
hold on;
plot(linspace(0, max_range, rsim_obj.samples_), 20 * log10(abs(range_profile_linear(:,1))), 'LineWidth',1.5);
hold off;
grid on;

xlabel('Range (m)');
ylabel('Amplitude (dB)');
legend('Non-linear chirp','Linear chirp');

