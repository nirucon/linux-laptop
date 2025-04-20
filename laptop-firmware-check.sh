#!/bin/bash

# ============================
# Laptop Firmware & Enhetskontroll för Arch Linux
# ============================

# --- Färginställningar ---
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
NC="\033[0m" # No Color

# --- Kontrollera sudo ---
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Detta skript kräver root. Starta med: sudo $0${NC}"
   exit 1
fi

echo -e "${BLUE}=========================================="
echo -e " 🔧 Laptop Firmware och Enhetskontroll "
echo -e "==========================================${NC}"

# Funktion för att visa steg
show_step() {
  echo -e "\n${YELLOW}>> $1${NC}"
}

# --- Steg 1: fwupd ---
show_step "Installerar och uppdaterar firmware med fwupd..."
pacman -Sy --noconfirm fwupd &>/dev/null
systemctl enable --now fwupd.service
fwupdmgr refresh
fwupdmgr get-updates
fwupdmgr update

# --- Steg 2: Fingeravtrycksstöd ---
show_step "Installerar stöd för fingeravtrycksläsare..."
pacman -Sy --noconfirm fprintd libfprint &>/dev/null

# --- Steg 3: Bluetooth ---
show_step "Installerar och startar Bluetooth..."
pacman -Sy --noconfirm bluez bluez-utils &>/dev/null
systemctl enable --now bluetooth.service

# --- Steg 4: Kamera ---
show_step "Installerar kamera-verktyg..."
pacman -Sy --noconfirm cheese v4l-utils &>/dev/null

# --- Steg 5: Systeminfoverktyg ---
show_step "Installerar verktyg för hårdvaruidentifiering..."
pacman -Sy --noconfirm usbutils pciutils dmidecode lshw &>/dev/null

# --- Steg 6: BIOS-version ---
show_step "BIOS-version:"
BIOS_VER=$(dmidecode -s bios-version)
echo -e "${GREEN}  Nuvarande BIOS-version: $BIOS_VER${NC}"

# --- Steg 7: Visa enheter ---
show_step "USB-enheter:"
lsusb

show_step "PCI-enheter:"
lspci

# --- Steg 8: Fingeravtryck ---
show_step "Registrerade fingeravtryck:"
fprintd-list $(logname) 2>/dev/null || echo "  Inga fingeravtryck registrerade."

# --- Steg 9: Kameracheck ---
show_step "Kameraenheter:"
v4l2-ctl --list-devices || echo "  Ingen kamera hittades."

# --- Steg 10: Bluetooth-status ---
show_step "Bluetooth-information:"
bluetoothctl show

# --- Steg 11: Firmwareproblem (logg) ---
show_step "Firmware-relaterade rader från dmesg:"
dmesg | grep -i firmware | tail -n 10

# --- Steg 12: hw-probe (valfritt) ---
if ! command -v hw-probe &> /dev/null; then
  echo -e "\n${BLUE}Vill du installera hw-probe (från AUR med yay) för att analysera hårdvarustöd?${NC}"
  read -p "Installera hw-probe? (j/n): " install_probe
  if [[ $install_probe == "j" ]]; then
    yay -S --noconfirm hw-probe
    hw-probe -all -upload
  fi
else
  show_step "Kör hw-probe..."
  hw-probe -all -upload
fi

# --- Avslutning ---
echo -e "\n${GREEN}✅ Klart! Starta om datorn för BIOS/firmware uppdateringar."
echo -e "Kontrollera gärna resultat i appar som Cheese (kamera), Bluetooth-menyn, eller med fprintd-enroll (fingeravtryck).${NC}"
