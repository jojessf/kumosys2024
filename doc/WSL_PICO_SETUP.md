# WSL / RP Pico Setup
##Connecting USB Devices to WSL applications

0. have WSL v2 debian 12

1. usbipd
[Install usbipd: https://github.com/dorssel/usbipd-win/releases](https://github.com/dorssel/usbipd-win/releases) \
[More info: https://learn.microsoft.com/en-us/windows/wsl/connect-usb](https://learn.microsoft.com/en-us/windows/wsl/connect-usb) \
`usbipd list` \
![usbipd list](img/wsl_pico_setup__usbipd_list.png) \
`usbipd bind --force --busid 00-00` \
![usbipd bind](img/wsl_pico_setup__usbipd_bind.png) \
`usbipd attach --wsl --busid 00-00` \
![usbipd attach](img/wsl_pico_setup__usbipd_attach.png) \

2. python venv \
`sudo apt install python3.11-venv` \
`chmod +x py/bin/activate` \
![python3 venv apt](img/wsl_pico_setup__usbipd_installvenv.png) \
```python3 -m venv py```
![python3 venv apt](wsl_pico_setup__py3venvdir.png)


3. Modify .bashrc etc \
`chmod +x py/bin/activate` \
```
py/bin/activate
export PATH=${HOME}/py/bin:${PATH}
```