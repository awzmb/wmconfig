#!/bin/sh

# source: https://www.reddit.com/r/VFIO/comments/12z0jfo/can_gpu_be_switched_between_host_and_vm_while/
# switch from vfio-pci to nvidia

# example
# ID1="0000:01:00.0"
# ID2="0000:01:00.1"

ID1="0000:01:00.0"
ID2="0000:01:00.1"
echo "Unbinding GPU from vfio driver"
sudo sh -c "echo -n $ID1 > /sys/bus/pci/drivers/vfio-pci/unbind" || echo "Failed to unbind $ID1"
sudo sh -c "echo -n $ID2 > /sys/bus/pci/drivers/vfio-pci/unbind" || echo "Failed to unbind $ID2"
echo "Binding GPU to nvidia driver"
sudo sh -c "echo -n $ID1 > /sys/bus/pci/drivers/nvidia/bind" || echo "Failed to bind $ID1"
