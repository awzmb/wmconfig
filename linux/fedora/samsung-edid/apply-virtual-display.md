# Credits
- https://gist.github.com/iamthenuggetman/6d0884954653940596d463a48b2f459c

# Manual

1. First connect whatever display you want to use Moonlight on. I'll be using a 65" Roku TV. I connected it to my laptop running Fedora and after my system detected it I use for p in /sys/class/drm/*/status; do con=${p%/status}; echo -n "${con#*/card?-}: "; cat $p; done to find which directory has the EDID file for me it's HDMI-A-1

2. Copy that edid file to your home directory cp /sys/class/drm/card0-HDMI-A-1/edid ~/. Now get that edid file over to your Bazzite (streaming machine). I used LocalSend to transfer it.

2. Create a directory to store this new edid file sudo mkdir -p /usr/local/lib/firmware then place the file in there sudo mv ./edid.bin /usr/local/lib/firmware/

3. Add this new edid to your kernel args sudo rpm-ostree kargs --append-if-missing="firmware_class.path=/usr/local/lib/firmware drm.edid_firmware=HDMI-A-1:edid.bin video=HDMI-A-1:e"

4. Reboot systemctl reboot. After you log back into Bazzite open up your Display Configuration window (right-click on desktop) and notice you have an additional display set your virtual display to Mirror/Replica your primary.

5. Configure Sunshine so we force all our games to use the virtual display instead of our primary when using Moonlight. Open a terminal and run kscreen-doctor -o | grep Output: look for your virtual screen id. In my case it's HDMI-A-1.

6. Right-click Sunshine icon in your tray and select "Open Sunshine" go to Configuration page. Once there click on the General tab and click + Add to put a "Do" and a "Undo Command".

7. For your "Do" command you want to disable your primary display(s) and only enable your virtual display (this will force games to launch on the correct screen with correct resolution). In your "Undo" command you want to do the opposite (i.e. disable your Virtual Display and enable your primary display(s)). Below are my Do and Undo commands:

Do:

/usr/bin/kscreen-doctor output.DP-2.disable && /usr/bin/kscreen-doctor output.HDMI-A-1.enable
Undo (make sure you re-enable your Virtual Display as well):

/usr/bin/kscreen-doctor output.DP-2.enable
Test on Moonlight to verify everything works as expected.
(citation: https://www.reddit.com/r/linux_gaming/comments/199ylqz/streaming_with_sunshine_from_virtual_screens/)
