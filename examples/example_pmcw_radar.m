%% PMCW Radar
%
% Compare to RadarSimPy example at https://radarsimx.com/2019/05/24/pmcw-radar/
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

%% Phase code

code1 = [1, 1, -1, -1, -1, -1, 1, 1, 1, 1, -1, 1, -1, 1, -1, 1, ...
    1, 1, -1, 1, 1, -1, 1, -1, 1, -1, -1, 1, -1, -1, 1, 1, ...
    1, 1, -1, 1, -1, 1, 1, 1, -1, -1, 1, -1, 1, -1, 1, -1, ...
    -1, 1, 1, 1, 1, 1, -1, -1, -1, -1, -1, 1, -1, 1, 1, -1, ...
    1, -1, -1, 1, -1, 1, -1, -1, 1, 1, 1, -1, -1, -1, -1, -1, ...
    1, -1, 1, 1, 1, 1, -1, 1, -1, -1, -1, -1, 1, 1, 1, -1, ...
    1, 1, -1, -1, 1, -1, -1, 1, 1, 1, 1, -1, 1, 1, 1, 1, ...
    -1, 1, -1, -1, -1, -1, -1, 1, 1, 1, -1, 1, 1, -1, -1, -1, ...
    -1, -1, -1, -1, 1, -1, -1, -1, 1, 1, -1, 1, -1, -1, -1, 1, ...
    1, -1, 1, 1, 1, -1, 1, 1, 1, 1, 1, -1, -1, 1, 1, 1, ...
    1, 1, 1, -1, 1, -1, -1, -1, 1, 1, -1, 1, 1, -1, -1, 1, ...
    -1, -1, 1, -1, -1, 1, 1, 1, -1, -1, -1, 1, -1, -1, 1, -1, ...
    -1, 1, 1, -1, 1, 1, 1, 1, -1, -1, -1, -1, 1, -1, -1, -1, ...
    -1, 1, -1, -1, -1, -1, 1, -1, 1, -1, -1, -1, 1, 1, 1, -1, ...
    1, 1, 1, -1, 1, -1, 1, 1, 1, -1, -1, 1, 1, 1, -1, -1, ...
    1, -1, -1, 1, -1, 1, 1, 1, 1, 1, -1, -1, -1, 1, 1];
code2 = [1, -1, 1, 1, -1, -1, -1, -1, 1, 1, 1, -1, 1, -1, -1, -1, ...
    -1, 1, -1, -1, 1, -1, 1, -1, -1, -1, -1, 1, -1, -1, 1, -1, ...
    -1, -1, -1, 1, 1, 1, 1, -1, -1, -1, -1, 1, 1, -1, 1, 1, ...
    -1, 1, -1, -1, -1, 1, 1, -1, 1, -1, 1, -1, -1, -1, 1, -1, ...
    1, 1, -1, 1, -1, -1, -1, 1, 1, 1, -1, -1, -1, -1, 1, 1, ...
    -1, 1, -1, 1, 1, 1, -1, 1, -1, -1, 1, -1, -1, -1, -1, -1, ...
    1, 1, 1, 1, -1, -1, 1, -1, -1, -1, 1, -1, 1, -1, 1, -1, ...
    1, 1, -1, 1, 1, -1, 1, -1, 1, 1, -1, 1, -1, 1, 1, 1, ...
    -1, -1, 1, 1, -1, -1, -1, -1, 1, -1, -1, -1, -1, 1, 1, -1, ...
    -1, 1, -1, -1, -1, -1, 1, -1, 1, -1, -1, 1, 1, 1, -1, 1, ...
    1, -1, 1, 1, 1, -1, -1, -1, -1, -1, -1, -1, -1, 1, -1, -1, ...
    1, -1, -1, 1, 1, -1, -1, 1, 1, -1, 1, -1, 1, -1, -1, -1, ...
    -1, 1, 1, -1, -1, -1, 1, 1, 1, -1, 1, -1, -1, -1, 1, -1, ...
    -1, 1, 1, 1, -1, 1, 1, 1, -1, -1, -1, -1, -1, -1, 1, -1, ...
    1, 1, 1, 1, 1, -1, -1, 1, -1, 1, -1, -1, -1, 1, 1, -1, ...
    -1, -1, -1, -1, 1, 1, -1, 1, 1, -1, 1, 1, 1, -1, 1];

% convert binary code to phases in degrees
phase_code1 = zeros(size(code1));
phase_code2 = zeros(size(code2));
phase_code1(code1 == 1) = 0;
phase_code1(code1 == -1) = 180;
phase_code2(code2 == 1) = 0;
phase_code2(code2 == -1) = 180;

% define modulation timing (4e-9 s per code)
t_mod1 = (0:1:(length(phase_code1)-1))*4e-9;
t_mod2 = (0:1:(length(phase_code2)-1))*4e-9;

figure();
plot(t_mod1, phase_code1, 'LineWidth',1.5);
hold on;
plot(t_mod2, phase_code2, 'LineWidth',1.5);
hold off;
grid on;
title('Phase modulation sequences');
xlabel('Time (s)');
ylabel('Phase (deg)');
legend('Phase code 1','Phase code 2');

%% Transmitter channel

tx_ch = {};
tx_ch{1} = RadarSim.TxChannel([0 0 0], 'mod_t', t_mod1, 'phs',phase_code1);
tx_ch{2} = RadarSim.TxChannel([1 0 0], 'mod_t', t_mod2, 'phs',phase_code2);

%% Transmitter

f=24.125e9;
t=2.1e-6;
num_pulses = 256;

tx = RadarSim.Transmitter(f, t, 'tx_power',20, 'pulses',num_pulses,'channels', tx_ch);

%% Receiver

fs=250e6;
noise_figure=10;
rf_gain=20;
resistor=1000;
bb_gain=30;
rx = RadarSim.Receiver(fs, rf_gain, resistor, bb_gain, 'noise_figure', noise_figure, 'channels', {RadarSim.RxChannel([0 0 0])});

%% Radar

radar = RadarSim.Radar(tx, rx);

%% Targets

targets = {};
targets{1} = RadarSim.PointTarget([20 0 0], [-200 0 0], 10);
targets{2} = RadarSim.PointTarget([70 0 0], [0 0 0], 35);
targets{3} = RadarSim.PointTarget([33 10 0], [100 0 0], 20);

%% Run Simulation

simc = RadarSim.Simulator();
simc.Run(radar, targets, 'noise', true);

baseband=simc.baseband_;
timestamp=simc.timestamp_;

% For convenience, the baseband signals for the two transmitter channels are
% initially kept separate. As a result, the total size of the baseband data matrix is  
% samples × pulses × 2
%
% However, in a realistic scenario, these two transmitter channels should transmit
% simultaneously. Consequently, it becomes necessary to combine the baseband
% signals from these two channels.
baseband = baseband(:, :, 1)+baseband(:, :, 2);

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

%% Demodulate the 2 channels separately

range_profile = zeros(255, num_pulses, 2);

for pulse_idx=1:num_pulses
    for bin_idx=1:255
        range_profile(bin_idx, pulse_idx, 1) = sum(code1.*baseband(bin_idx:(bin_idx+254), pulse_idx).');
    end
end

for pulse_idx=1:num_pulses
    for bin_idx=1:255
        range_profile(bin_idx, pulse_idx, 2) = sum(code2.*baseband(bin_idx:(bin_idx+254), pulse_idx).');
    end
end

bin_size = 3e8/2*4e-9;
range_bin = (0:254)*bin_size;

figure();
plot(range_bin, 20 * log10(mean(abs(range_profile(:, :, 1)), 2)), 'LineWidth',1.5);
hold on;
plot(range_bin, 20 * log10(mean(abs(range_profile(:, :, 2)), 2)), 'LineWidth',1.5);
hold off;
grid on;
title('Range profile');
xlabel('Range (m)');
ylabel('Amplitude (dB)');
legend('Channel 1, averaged pulses','Channel 2, averaged pulses');


%% Doppler processing

rdop = fftshift(fft(range_profile.*repmat(chebwin(num_pulses,50).',255,1), [], 2), 2);

unambiguous_speed = 3e8 / t / f / 2;

figure();
surf(linspace(-unambiguous_speed, 0, num_pulses), range_bin, 20*log10(abs(rdop(:,:,1))));
shading interp;
title('Range Doppler');
xlabel('Velocity (m/s)');
ylabel('Range (m)');
zlabel('Amplitude (dB)');
axis tight;
colormap jet;
colorbar;

