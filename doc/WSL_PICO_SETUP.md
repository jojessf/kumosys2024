# WSL / RP Pico Setup
##Connecting USB Devices to WSL applications

0. have WSL v2 debian 12, git, etc
```
sudo apt install git xxd dhex git cmake gcc-arm-none-eabi libnewlib-arm-none-eabi libstdc++-arm-none-eabi-newlib build-essential pkg-config libusb-1.0-0-dev python3.11-venv
```

1. get usbipd [ cmd.exe, administrator ]
[Install usbipd: https://github.com/dorssel/usbipd-win/releases](https://github.com/dorssel/usbipd-win/releases) \
[More info: https://learn.microsoft.com/en-us/windows/wsl/connect-usb](https://learn.microsoft.com/en-us/windows/wsl/connect-usb) \
`dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart` \
`usbipd list` \
![usbipd list](img/wsl_pico_setup__usbipd_list.png) \
`usbipd bind --force --busid 00-00` \
![usbipd bind](img/wsl_pico_setup__usbipd_bind.png) \
`usbipd attach --wsl --busid 00-00` \
![usbipd attach](img/wsl_pico_setup__usbipd_attach.png)

2. configure python venv [ wsl / bash / user ] \
`chmod +x py/bin/activate` \
![python3 venv apt](img/wsl_pico_setup__usbipd_installvenv.png) \
```python3 -m venv py```
![python3 venv apt](wsl_pico_setup__py3venvdir.png)
```source py/bin/activate```

3. install pyserial & mpremote \
`pip install mpremote` \
![pip install mpremote](img/wsl_pico_setup__pip_mpremote.jpg)

4. clone pico-sdk to new project
```
mkdir ~/picorem
cd ~/picorem
git clone -b master https://github.com/raspberrypi/pico-sdk
git clone -b master https://github.com/raspberrypi/pico-examples.git

git config --global --add safe.directory ${HOME}/picorem/pico-sdk

cd pico-sdk
mkdir build
cd build

export PICO_SDK_PATH=${HOME}/picorem/pico-sdk
cmake ..
cmake ..	#see note 2 below
make 
```
![clone picosdk](img/wsl_pico_setup__picosdk.jpg)
![pico submodules](img/wsl_pico_setup__picosdk_submodule.jpg)
![pico cmake](img/wsl_pico_setup__picosdk_cmakebuild.jpg)
![pico make](img/wsl_pico_setup__picosdk_makebuild.jpg)


5. picotool
```
export PICO_SDK_PATH=${HOME}/picorem/pico-sdk
cd ~/picorem   
git clone "https://github.com/raspberrypi/picotool"
sudo cp udev/99-picotool.rules /etc/udev/rules.d/
export LIBUSB_ROOT=${HOME}/picorem/picotool
cd picotool
mkdir build
cd build
cmake ..
make
cp picotool ${HOME}/py/bin/
picotool info
```
![pico tool make](wsl_pico_setup__picotool_build.jpg)
![pico tool make](wsl_pico_setup__picotool_use.jpg)

99. Modify .bashrc etc \
`chmod +x py/bin/activate`
```
${HOME}/py/bin/activate
export PATH=${HOME}/py/bin:${PATH}
export PICO_SDK_PATH=${HOME}/picorem/pico-sdk
export LIBUSB_ROOT=${HOME}/picorem/picotool
```

