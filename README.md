Sets the range (minimum and maximum) temperature for the GPU, and tries to keep the temperature in the specified range.

Suitable only for:
- Nvidia GPUs;
- Sonm OS.

# Installation

`sudo bash -c "$(curl -s https://raw.githubusercontent.com/sonm-io/fan-control/master/install.sh)"`

## Adjusting temperature range

By default:
- MIN fan speed = 40% (when GPU temp is below MIN temp),
- MIN temp=50˚C, 
- MAX temp=70˚C (fan speed will be set to 100 if temperature rises above this value),
- Between MIN and MAX fan speed adjust graguatelly,
- CRITICAL GPU temp = 87˚C (when GPU temp exceed this value, script initiates force reboot).


If you want to change this values: 
- edit /etc/sonm/fan-control.txt
- restart the service with:

`sudo service sonm-fan-control restart`
