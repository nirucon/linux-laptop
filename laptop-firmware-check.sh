#!/bin/bash

echo "=============================="
echo " 🔧 Firmware och enhetscheck "
echo "=============================="

# 1. fwupd - Firmware updater
echo ">> Installerar och kör fwupd..."
pacman -Sy --noconfirm fwupd
systemctl enable --now fwupd.service
fwupdmgr refresh
fwupdmgr get-updates
fwupdmgr update

# 2. Fingeravtrycksstöd
echo ">> Installerar fingeravtrycksstöd..."
pacman -Sy --noconfirm fprintd libfprint

# 3. Bluetooth
echo ">> Installerar och startar Bluetooth..."
pacman -Sy --noconfirm bluez bluez-utils
systemctl enable --now bluetooth.service

# 4. Kamera – testverktyg
echo ">> Installerar verktyg för kamera..."
pacman -Sy --noconfirm cheese v4l-utils

# 5. Installera hårdvaruidentifiering
echo ">> Installerar verktyg för systeminformation..."
pacman -Sy --noconfirm usbutils pciutils dmidecode lshw

# 6. BIOS-version
BIOS_VER=$(dmidecode -s bios-version)
echo ">> Nuvarande BIOS-version: $BIOS_VER"

# 7. Lista enheter
echo ">> USB-enheter:"
lsusb

echo ""
echo ">> PCI-enheter:"
lspci

echo ""
echo ">> Fingeravtrycksläsare:"
fprintd-list $(logname) 2>/dev/null || echo "Inga fingeravtryck registrerade"

# 8. Kontrollera kamera
echo ""
echo ">> V4L2 kameracheck:"
v4l2-ctl --list-devices || echo "Kamera hittades inte"

# 9. Bluetooth-status
echo ""
echo ">> Bluetooth-status:"
bluetoothctl show

# 10. Dmesg firmware-koll
echo ""
echo ">> Letar efter firmware-problem i dmesg:"
dmesg | grep -i firmware | tail -n 10

# 11. Firmwarecheck från hw-probe (valfri)
if command -v hw-probe &> /dev/null; then
    echo ""
    echo ">> Kör hw-probe för hårdvarudata (om installerat)..."
    hw-probe -all -upload
else
    echo ""
    echo ">> Vill du installera hw-probe (för att ladda upp hårdvarudata och se supportstatus online)?"
    read -p "Installera hw-probe från AUR via yay? (j/n): " choice
    if [[ $choice == "j" ]]; then
        yay -S hw-probe
        hw-probe -all -upload
    fi
fi

echo ""
echo "✅ Färdig! Starta om datorn om firmware har uppdaterats."

