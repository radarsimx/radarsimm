clear;

%%
rsim_obj=RadarSim;

%% Transmitter

f=[24.075e9, 24.175e9];
t=80e-6;

rsim_obj.init_transmitter(f, t, 'tx_power',10, 'prp', 100e-6, 'pulses',256);

%%
az_angle = -80:1:80;
az_pattern = 20 * log10(cos(az_angle / 180 * pi).^4) + 6;

el_angle = -80:1:80;
el_pattern = 20 * log10((cos(el_angle / 180 * pi)).^20) + 6;

rsim_obj.add_txchannel([0 0 0], ...
    'azimuth_angle', az_angle, ...
    'azimuth_pattern', az_pattern, ...
    'elevation_angle', el_angle, ...
    'elevation_pattern', el_pattern);

rsim_obj.add_txchannel([40 0 0], ...
    'azimuth_angle', az_angle, ...
    'azimuth_pattern', az_pattern, ...
    'elevation_angle', el_angle, ...
    'elevation_pattern', el_pattern);

%% Receiver

fs=2e6;
noise_figure=12;
rf_gain=20;
resistor=500;
bb_gain=30;
rsim_obj.init_receiver(fs, rf_gain, resistor, bb_gain, 'noise_figure', noise_figure);

%%
rsim_obj.add_rxchannel([0 0 0], ...
    'azimuth_angle', az_angle, ...
    'azimuth_pattern', az_pattern, ...
    'elevation_angle', el_angle, ...
    'elevation_pattern', el_pattern);

%% Targets
rsim_obj.add_target([200 0 0], [-5 0 0], 20, 0);
rsim_obj.add_target([95 20 0], [-50 0 0], 15, 0);
rsim_obj.add_target([30 -5 0], [-22 0 0], 5, 0);

%% Run Simulation
rsim_obj.run_simulator();

%% Range-Doppler Processing

baseband=rsim_obj.baseband_;

range_profile=fft(baseband.*repmat(chebwin(160,60),1,256), [], 1);
rdop = fft(range_profile.*repmat(chebwin(256,60).',160,1), [], 2);

%surf(20*log10(abs(rdop)));