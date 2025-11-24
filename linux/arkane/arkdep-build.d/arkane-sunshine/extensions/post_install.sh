#!/bin/bash

useradd -m -G wheel -s /bin/bash steam

mkdir -p /home/steam/.config
cat <<EOT >> /home/steam/.config/autostart-virtual-display.sh
#!/bin/bash

# Create a virtual display using ddcutil
ddcutil setvcp 60 0x15
ddcutil setvcp 62 0x1
ddcutil setvcp 68 0x1
ddcutil setvcp 8d 0x01
EOT

chmod +x /home/steam/.config/autostart-virtual-display.sh