# WiFiSnipe

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE) 
[![Platform](https://img.shields.io/badge/Platform-Linux-lightgrey.svg)](https://github.com/scap3sh4rk/WiFiSnipe)
[![Tools](https://img.shields.io/badge/Tools-aircrack--ng%2Cmdk4%2Cgnome--terminal-blue.svg)](https://github.com/scap3sh4rk/WiFiSnipe)

WiFiSnipe is a powerful and menu-driven Bash script that automates wireless network attacks and handshake capturing tasks.  
Designed for Wi-Fi security assessments, WiFiSnipe enables you to easily configure a wireless adapter, scan nearby networks, perform targeted jamming, or capture WPA/WPA2 handshakes for password cracking.

Repository: [https://github.com/scap3sh4rk/WiFiSnipe](https://github.com/scap3sh4rk/WiFiSnipe)



## Features
- Lists available wireless adapters and configures the selected adapter in monitor mode with optimized settings.
- Runs a passive scan (`airodump-ng`) to identify nearby access points and clients.
- Offers two main attack options:
  - **Jamming Mode**: 
    - Jam a specific device (based on BSSID and channel).
    - Jam all nearby networks.
  - **Handshake Capture Mode**: 
    - Send deauthentication packets.
    - Capture WPA/WPA2 handshake files.
    - Auto-generates capture filenames with timestamps.
    - Launches a new terminal instance for capturing handshakes.
- Easy-to-follow, menu-driven interface.



## Requirements
- Linux distribution with Bash (Kali Linux or Ubuntu recommended)
- Wireless adapter supporting monitor mode and packet injection
- Installed tools:
  - `aircrack-ng`
  - `mdk4`
  - `gnome-terminal` (or equivalent terminal application)

Install dependencies if needed:

```bash
sudo apt update
sudo apt install aircrack-ng mdk4 gnome-terminal
```



## Installation

Clone the repository:

```bash
git clone https://github.com/scap3sh4rk/WiFiSnipe.git
cd WiFiSnipe
```

Give execution permissions to the script:

```bash
chmod +x WiFiSnipe_v1.0.sh
```



## Usage

Run the script with root privileges:

```bash
sudo ./WiFiSnipe_v1.0.sh
```

Follow the on-screen menu:
1. Select a wireless adapter to enable monitor mode.
2. Passive scan for 15 seconds to discover nearby Wi-Fi networks.
3. Choose to either:
   - **Jam** a single target or all networks.
   - **Capture** WPA/WPA2 handshakes for password cracking.

Captured handshake files are automatically saved with timestamped filenames.



## Important Notes
- **Legal Warning**:  
  Unauthorized scanning, jamming, or intrusion into networks without permission is illegal.  
  Use WiFiSnipe **only** for educational purposes or authorized penetration testing.
- Ensure that your Wi-Fi adapter is compatible with monitor mode and packet injection.
- If your system uses a terminal emulator other than `gnome-terminal`, you may need to modify the script accordingly.



## Contributing
Contributions are welcome!  
Feel free to open issues, suggest improvements, or submit pull requests.



## License
This project is licensed under the [MIT License](LICENSE).



## ‼️Disclaimer
This tool is intended for **educational and authorized security testing purposes only**.  
The author is not responsible for any misuse, damage, or legal consequences resulting from the use of this tool.
