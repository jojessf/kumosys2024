# WSL / RP Pico Setup


##Connecting USB Devices to WSL applications##

Install usbipd:
https://github.com/dorssel/usbipd-win/releases

More info:

https://learn.microsoft.com/en-us/windows/wsl/connect-usb


`usbipd list`

![usbipd list](img/wsl_pico_setup__usbipd_list.png)


`usbipd bind --force --busid 00-00`

![usbipd bind](img/wsl_pico_setup__usbipd_bind.png)


`usbipd attach --wsl --busid 00-00`
![usbipd attach](img/wsl_pico_setup__usbipd_attach.png)

`sudo apt install python3.11-venv`
![python3 venv apt](img/wsl_pico_setup__usbipd_installvenv.png)

`python3 -m venv py`
![python3 venv apt](wsl_pico_setup__py3venvdir.png)