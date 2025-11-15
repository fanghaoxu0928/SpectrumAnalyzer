# A Portable Spectrum Analyzer Based On PGL50H

### Abstract
This design implements a dual-channel ADC data acquisition, real-time signal analysis, HDMI visual interaction, and threshold detection system based on PGL50H, adopting a modular architecture to ensure functional integrity and real-time performance.

### Functions and Features
**Signal Acquisition**: Driven by PGL50H, dual-channel 16-bit ADCs perform signal acquisition.
It can realize AC/DC signal acquisition with a sampling input range of ±4.5V at 29.5MHz.

**Real-time Spectrum Analysis**: Utilizing PGL50H to perform real-time FFT operations (2048 points) on the collected signals, and simultaneously display the spectrograms of the two channels on a 1920*1080 resolution monitor with a frequency resolution of 14404 Hz.

**Signal Parameter Measurement**: Achieve measurement of amplitude, frequency, and duty cycle for sine waves, triangular waves, and square waves of the two-channel signals.

**Dual-channel Signal Acquisition**: Realize synchronous acquisition of two-channel signals, and the calculation of the phase difference between the two signals can be enabled through button control, with the result displayed on the HDMI monitor.

**Automated Testing**: Implement two methods for measuring signal parameters based on given thresholds. One is button-controlled amplitude threshold detection to check if the signal amplitude meets the standard, and the other is PC-side serial communication-controlled frequency threshold detection to verify if the signal frequency is up to standard. The test results are indicated by on-board LEDs.

**AI-assisted Diagnosis**: A CNN module is used for AI waveform recognition, with its interface adopting the AXI4-Stream protocol. Its input is 2048 results output by FFT, and the output results can be displayed on the HDMI monitor.

**Remote Control**: UART serial communication enables interaction between the FPGA board and the host computer.