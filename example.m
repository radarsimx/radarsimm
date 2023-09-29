
loadlibrary('radarsimc','radarsim.h');

%% Transmitter
f = libpointer("doublePtr",[24.075e9, 24.175e9]);
t = libpointer("doublePtr",[0,80e-6]);

freq_offset = libpointer("doublePtr",zeros(1,256));
pulse_start_time = libpointer("doublePtr",(0:1:255)*100e-6);

frame_start_time = libpointer("doublePtr",0);

tx_ptr=calllib('radarsimc', 'Create_Transmitter', f, t, 2, freq_offset, pulse_start_time,256, frame_start_time, 1, 10);

%% Tx Channel
location=libpointer("singlePtr",[0,0,0]);
polar=libpointer("singlePtr",[0,0,1]);
phi=libpointer("singlePtr",[-pi/4,pi/4]);
phi_ptn=libpointer("singlePtr",[0,0]);
theta=libpointer("singlePtr",[0,pi]);
theta_ptn=libpointer("singlePtr",[0,0]);
antenna_gain=0;
mod_t=libpointer("singlePtr",[]);
mod_var_real=libpointer("singlePtr",[]);
mod_var_imag=libpointer("singlePtr",[]);

pulse_mod_real=libpointer("singlePtr",ones(1,256));
pulse_mod_imag=libpointer("singlePtr",zeros(1,256));

calllib('radarsimc', 'Add_Txchannel', location, polar, phi, phi_ptn, 2, ...
    theta, theta_ptn, 2, antenna_gain, ...
    mod_t, mod_var_real, mod_var_imag, 0, ...
    pulse_mod_real, pulse_mod_imag, 0, 1, ...
    tx_ptr);

%% Receiver
fs=2e6;
rf_gain = 20;
resistor=500;
baseband_gain=30;
rx_ptr = calllib('radarsimc', 'Create_Receiver', fs, rf_gain, resistor, ...
                            baseband_gain);

%% Rx Channel
calllib('radarsimc', 'Add_Rxchannel', location, polar, phi, phi_ptn, 2, ...
    theta, theta_ptn, 2, antenna_gain, ...
    rx_ptr);

%% Radar
radar_ptr=calllib('radarsimc', 'Create_Radar', tx_ptr, rx_ptr);

radar_loc_ptr=libpointer("singlePtr",[0,0,0]);
radar_spd_ptr=libpointer("singlePtr",[0,0,0]);
radar_rot_ptr=libpointer("singlePtr",[0,0,0]);
radar_rrt_ptr=libpointer("singlePtr",[0,0,0]);
calllib('radarsimc', 'Radar_Motion', radar_loc_ptr, radar_spd_ptr, radar_rot_ptr, radar_rrt_ptr, radar_ptr);


%% Targets
targets_ptr=calllib('radarsimc', 'Init_Targets');

tg_loc = libpointer("singlePtr",[200,0,0]);
tg_speed = libpointer("singlePtr",[-5,0,0]);
calllib('radarsimc', 'Add_Target', tg_loc, tg_speed, 20, 0, targets_ptr);

%% Simulator
bb_real = libpointer("doublePtr",zeros(160, 256));
bb_imag = libpointer("doublePtr",zeros(160, 256));

calllib('radarsimc','Run_Simulator',radar_ptr, targets_ptr, bb_real, bb_imag);

calllib('radarsimc','Dump_Transmitter',tx_ptr);

calllib('radarsimc','Free_Transmitter',tx_ptr);

clear tx_ptr;
clear rx_ptr;
clear radar_ptr;
clear targets_ptr;
unloadlibrary radarsimc;


% a = libpointer('doublePtr',[4 5 6]);
% b = libpointer('doublePtr',[1 2 3]);
% n = int32(3);
% s = calllib("addition","addition", a, b, n);
% s.setdatatype('doublePtr',double(n),1);
% out = s.Value;