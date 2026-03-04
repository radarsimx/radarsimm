---
layout: default
title: Home
---

# RadarSimM Documentation

Radar Simulator for MATLAB &mdash; [radarsimx.com](https://radarsimx.com)

## Classes

- [RadarSim.License](License.md)
- [RadarSim.MeshTarget](MeshTarget.md)
- [RadarSim.PointTarget](PointTarget.md)
- [RadarSim.Radar](Radar.md)
- [RadarSim.RadarSimulator](RadarSimulator.md)
- [RadarSim.Receiver](Receiver.md)
- [RadarSim.RxChannel](RxChannel.md)
- [RadarSim.Transmitter](Transmitter.md)
- [RadarSim.TxChannel](TxChannel.md)

## Quick Start

```matlab
%% Create channels
tx_ch = RadarSim.TxChannel([0 0 0]);
rx_ch = RadarSim.RxChannel([0 0 0]);

%% Create transmitter and receiver
tx = RadarSim.Transmitter([10e9, 11e9], 0.1, 'channels', {tx_ch});
rx = RadarSim.Receiver(40000, 20, 1000, 50, 'channels', {rx_ch});

%% Create radar and targets
radar = RadarSim.Radar(tx, rx);
targets = {RadarSim.PointTarget([100 0 0], [0 0 0], 10)};

%% Run simulation
simc = RadarSim.RadarSimulator();
simc.Run(radar, targets);
baseband = simc.baseband_;  %% Get simulated data
```

---
*Copyright (C) 2023 - 2026 RadarSimX LLC*
