%% TDM MIMO FMCW Radar
%
% Compare to RadarSimPy example at https://radarsimx.com/2019/04/07/tdm-mimo-fmcw-radar/
%

clear;

%% Create RadarSim handle

rsim_obj=RadarSim;

%% Transmitter

f = [24.075e9, 24.175e9];
bw = f(2)-f(1);
t = 80e-6;
num_pulses = 1;
tx_power = 15;

rsim_obj.init_transmitter(f, t, 'tx_power', tx_power, 'pulses', num_pulses);

%% Transmitter channel

wavelength = 3e8 / 24.125e9;

angle = -90:1:90;
pattern = 20 * log10(cos(angle / 180 * pi) + 0.01) + 6;

tx_loc = [-12, -8, -4, 0]*wavelength;

rsim_obj.add_txchannel([0, tx_loc(1), 0], ...
    'azimuth_angle', angle, ...
    'azimuth_pattern', pattern, ...
    'elevation_angle', angle, ...
    'elevation_pattern',pattern, ...
    'delay', 0);

rsim_obj.add_txchannel([0, tx_loc(2), 0], ...
    'azimuth_angle', angle, ...
    'azimuth_pattern', pattern, ...
    'elevation_angle', angle, ...
    'elevation_pattern',pattern, ...
    'delay', 100e-6);

rsim_obj.add_txchannel([0, tx_loc(3), 0], ...
    'azimuth_angle', angle, ...
    'azimuth_pattern', pattern, ...
    'elevation_angle', angle, ...
    'elevation_pattern',pattern, ...
    'delay', 200e-6);

rsim_obj.add_txchannel([0, tx_loc(4), 0], ...
    'azimuth_angle', angle, ...
    'azimuth_pattern', pattern, ...
    'elevation_angle', angle, ...
    'elevation_pattern',pattern, ...
    'delay', 300e-6);

%% Receiver

fs=2e6;
noise_figure=8;
rf_gain=20;
resistor=500;
bb_gain=50;
rsim_obj.init_receiver(fs, rf_gain, resistor, bb_gain, 'noise_figure', noise_figure);

%% Receiver channel

rx_loc = (0:1:7)*wavelength/2;

for idx = 1:8
    rsim_obj.add_rxchannel([0, rx_loc(idx), 0], ...
        'azimuth_angle', angle, ...
        'azimuth_pattern', pattern, ...
        'elevation_angle', angle, ...
        'elevation_pattern',pattern);
end

%% Targets

rsim_obj.add_target([160, 0, 0], [0, 0, 0], 25, 0);
rsim_obj.add_target([80, -80, 0], [0, 0, 0], 20, 0);
rsim_obj.add_target([30, 20, 0], [0, 0, 0], 8, 0);

%% Run Simulation

rsim_obj.run_simulator('noise', true);
baseband=rsim_obj.baseband_;
timestamp=rsim_obj.timestamp_;

%% Range Profile

range_profile=fft(baseband.*repmat(chebwin(160,60),1,1,32), [], 1);
max_range = (3e8 * fs * t / bw / 2);
range_bins = linspace(0, max_range, rsim_obj.samples_);

figure();
plot(range_bins, 20*log10(abs(range_profile(:, 1, 1))));
hold on;
plot(range_bins, 20*log10(abs(range_profile(:, 1, 9))));
plot(range_bins, 20*log10(abs(range_profile(:, 1, 17))));
plot(range_bins, 20*log10(abs(range_profile(:, 1, 25))));
hold off;
grid on;
title('Range Profile');
xlabel('Range (m)');
ylabel('Amplitude (dB)');
legend('Channel 1','Channel 2','Channel 3','Channel 4');

%% Digital Beamforming

azimuth = -90:1:90;
virtual_array = (reshape(repmat(tx_loc, 8, 1), 1, [])+repmat(rx_loc, 1, 4))/wavelength;

[az_grid, loc_grid]=meshgrid(azimuth, virtual_array);

A=exp(1i * 2 * pi * loc_grid .* sin(az_grid / 180 * pi));
bf_window = repmat(chebwin(32,50).', rsim_obj.samples_, 1);

AF = (A.')*(squeeze(range_profile(:,1,:)).*bf_window).';

figure();
surf(range_bins, azimuth, 20 * log10(abs(AF) + 0.1));
shading interp;
title('Range-Azimuth Map');
xlabel('Range (m)');
ylabel('Azimuth (deg)');
zlabel('Amplitude (dB)');
colorbar;
