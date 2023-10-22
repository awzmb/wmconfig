#!/bin/sh

# source: https://www.reddit.com/r/VFIO/comments/12z0jfo/can_gpu_be_switched_between_host_and_vm_while/
# switch from nvidia to vfio-pci
# leave NO process running on your GPU before switching

# example
# ID1="0000:01:00.0"
# ID2="0000:01:00.1"

ID1="0000:01:00.0"
ID2="0000:01:00.1"
echo "Unbinding GPU from nvidia driver"
sudo sh -c "echo -n $ID1 > /sys/bus/pci/drivers/nvidia/unbind" && echo "Successfuly unbounded $ID1" || echo "Failed to unbind $ID1"
echo "Binding GPU to vfio driver"
sudo sh -c "echo -n $ID1 > /sys/bus/pci/drivers/vfio-pci/bind" || echo "Failed to bind $ID1"
sudo sh -c "echo -n $ID2 > /sys/bus/pci/drivers/vfio-pci/bind" || echo "Failed to bind $ID2"
