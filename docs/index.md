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
%% Set license
RadarSim.License.set_license();

%% Create transmitter and receiver
tx = RadarSim.Transmitter(f, t, 'channels', {tx_ch});
rx = RadarSim.Receiver(fs, rf_gain, load_resistor, bb_gain, 'channels', {rx_ch});

%% Create radar system
radar = RadarSim.Radar(tx, rx);
```

---
*Copyright (C) 2023 - PRESENT radarsimx.com*
