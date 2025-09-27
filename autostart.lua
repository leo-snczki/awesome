local awful = require("awful")

-- equalizer
awful.util.spawn_with_shell("easyeffects --gapplication-service &")

-- dualmonitor
awful.util.spawn_with_shell("xrandr --output eDP-1 --mode 1920x1080 --pos 0x360 --rotate normal --output HDMI-1 --primary --mode 2560x1440 --pos 1920x0 --rotate normal")

-- wacom only on hdmi
awful.util.spawn_with_shell("xinput map-to-output 14 HDMI-1") -- Check the id with xinput | grep "stylus"

awful.util.spawn_with_shell("xsetwacom --set 14 Button 2 'pan'")

awful.util.spawn_with_shell("xsetwacom --set 14 'PanScrollThreshold' 200")