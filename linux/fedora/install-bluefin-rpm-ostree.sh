#!/bin/sh

ORIGIN_PATH=${pwd}

rpm-ostree -y install \
  gnome-shell-theme-flat-remix \
  gnome-shell-extension-pop-shell \
  gnome-shell-extension-pop-shell \
  gnome-shell-extension-pop-shell-shortcut-overrides \
  steam

sudo rpm-ostree kargs --append=pcie_ports=native pci=assign-busses,nocrs,realloc iommu=on

