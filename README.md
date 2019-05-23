Sets the range (minimum and maximum) temperature for the GPU, and tries to keep the temperature in the specified range.

Suitable only for:
- Nvidia GPUs;
- Sonm OS.

# Installation

`sudo bash -c "$(curl -s https://raw.githubusercontent.com/sonm-io/fan-control/master/install.sh)"`

## Adjusting temperature range

By default:
- MIN temp=50 (fan speed will be set to 0, if temperature drops below this value), 
- MAX temp=70 (fan speed will be set to 100 if temperature rises above this value),
- Between MIN and MAX fan speed adjust graguatelly.

If you want to change this values: 
- edit /etc/sonm/fan-control.txt
- restart the service with:

`sudo service sonm-fan-control restart`
