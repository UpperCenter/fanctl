# Fanctl - A Simple Shell Script For Dell Server Fan Control

Fanctl is a shell script created for homelabbers and enthusiasts to enable more granular, automatic control over Dell PowerEdge server fan speeds.

## Features

- Automated fan speed control based on CPU temperature thresholds
- IPMI integration with Dell iDRAC
- Logging of temperature and fan speed changes
- Graceful handling of script termination
- Automatic fallback to iDRAC fan control if temperature exceeds safe limits

## Demo

![Demo](./demo.gif)

## Installation

1. Clone the repository:

```bash
git clone https://github.com/UpperCenter/fanctl.git
cd fanctl
```

2. Make the script executable:

```bash
chmod +x fan_control.sh
```

3. Configure iDRAC settings:

   - Enable IPMI Over LAN in iDRAC:
     - Log into the iDRAC web interface
     - Navigate to Network > Services
     - Enable "IPMI Over LAN"
     - Click Apply

4. Adjust script variables:
   Open the script in a text editor and modify the following variables as needed:
   - `IPMI_HOST`: Your iDRAC IP address or FQDN **(Required)**
   - `IPMI_USER`: iDRAC username **(Required)**
   - `IPMI_PASS`: iDRAC password **(Required)**
   - `TEMP_THRESHOLD_*`: Temperature thresholds for fan speed adjustments **(Optional)**
   - `CHECK_INTERVAL`: Time between temperature checks (in seconds) **(Optional but Reccomended)**
   - `LOG_FILE`: Path to the log file **(Optional)**
   - `TEMP_MAX`: Maximum safe temperature threshold **(Optional)**

## Usage

Run the script with:

```bash
./fan_control.sh
```

For long-term use, consider setting up the script as a systemd service or running it in a screen/tmux session.

## Important Notes

- This script takes control of your server's fans. Use at your own risk and monitor temperatures closely when first implementing.
- Ensure your iDRAC firmware is up to date before using this script.
- The script requires root privileges or a user with sufficient permissions to execute IPMI commands.
- If the script terminates unexpectedly, it will attempt to return fan control to iDRAC before exiting.

## Contributing

Contributions are welcome. Please create a pull request detailing your changes and additions. Note that this is a small side project and likely won't get a ton of attention going forward.

## Authors & Contributors

- [@UpperCenter](https://www.github.com/UpperCenter)

## License

[MIT](https://github.com/UpperCenter/fanctl/blob/main/LICENSE)
