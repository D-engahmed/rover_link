# Phase 06 — Owner localization

RSSI is implemented as a coarse proximity signal only. It is not treated as an exact phone-to-rover distance.

For true spatial navigation toward a phone, the production path should add a ranging/localization technology such as UWB, or fuse a vision target bearing with a calibrated proximity signal.

Acceptance:
- link loss invalidates owner proximity;
- RSSI produces only coarse proximity bands;
- target bearing remains a separate input;
- autonomy never assumes RSSI equals meters.
