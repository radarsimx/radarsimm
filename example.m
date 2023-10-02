rsim_obj=RadarSim;

%% Transmitter

f=[24.075e9, 24.175e9];
t=80e-6;

rsim_obj.init_transmitter(f, t, 'tx_power',10, 'prp', 100e-6, 'pulses',256);

rsim_obj.add_txchannel([0 0 0]);

%% Receiver

fs=2e6;
noise_figure=12;
rf_gain=20;
resistor=500;
bb_gain=30;
rsim_obj.init_receiver(fs, noise_figure, rf_gain, resistor, bb_gain);

rsim_obj.add_rxchannel([0 0 0]);

%% Targets
rsim_obj.add_target([200 0 0], [-5 0 0], 20, 0);

%% Run Simulation
rsim_obj.run_simulator();

%% Range-Doppler Processing

baseband=rsim_obj.baseband_;

range_profile=fft(baseband, [], 2);
rdop = fft(range_profile, [], 1);

