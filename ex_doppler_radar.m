%% Doppler Radar
%
% Compare to RadarSimPy example at https://radarsimx.com/2019/05/16/doppler-radar/
%

clear;

%% Create RadarSim handle

rsim_obj=RadarSim;

%% Transmitter

f=10e9;
t=0.1;
num_pulses = 1;

rsim_obj.init_transmitter(f, t, 'tx_power',10, 'pulses',num_pulses);

%% Transmitter channel

rsim_obj.add_txchannel([0 0 0]);

%% Receiver

fs=40000;
noise_figure=6;
rf_gain=20;
resistor=1000;
bb_gain=50;
rsim_obj.init_receiver(fs, rf_gain, resistor, bb_gain, 'noise_figure', noise_figure);

%% Receiver channel

rsim_obj.add_rxchannel([0 0 0]);

%% Targets

rsim_obj.add_point_target([30 0 0], [-10 0 0], 20, 0);
rsim_obj.add_point_target([35 0 0], [35 0 0], 20, 0);

%% Run Simulation

rsim_obj.run_simulator('noise', true);
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

%% Doppler Radar Signal Processing

spec = fftshift(fft(baseband(:, 1, 1)));

speed = linspace(-fs/2, fs/2, rsim_obj.samples_)*3e8/2/10e9;

figure();
plot(speed, 20*log10(abs(spec)));
grid on;
xlabel('Speed (m/s)');
ylabel('Magnitude (dB)');

