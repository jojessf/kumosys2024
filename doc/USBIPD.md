# usbipd cheat sheet

`usbipd list` \
![usbipd list](img/wsl_pico_setup__usbipd_list.png) \
`usbipd bind --force --busid 00-00` \
![usbipd bind](img/wsl_pico_setup__usbipd_bind.png) \
`usbipd attach --wsl --busid 00-00` \
![usbipd attach](img/wsl_pico_setup__usbipd_attach.png)

`usbipd attach --wsl -a -i 2e8a:0005`

* automodem .bat:
`runas /user:Administrator C:\Progra~1\usbipd-win\usbipd.exe attach --wsl -a -i 2e8a:0005`
