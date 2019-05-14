This bunch of scripts allows to set permanent GPU Fan speed at given value.

Suitable only for:
- Nvidia GPUs;
- Sonm OS.

# Installation

`sudo bash -c "$(curl -s https://raw.githubusercontent.com/sonm-io/fan-control/master/install.sh)"`

## Adjusting Fan speed

By default, fan speed is set for 100%.
If you want to change this value: 
- edit /etc/sonm/fan-control.txt
- restart the service with:

`sudo service sonm-fan-control restart`
