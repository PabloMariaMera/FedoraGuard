# Start graphical feedback window in install environment (i.e. outside chroot)
# https://blog.entek.org.uk/notes/2023/04/06/graphical-progress-feedback-for-red-hat-and-rocky-kickstart-post-scripts.html
%post --nochroot
# This should possibly have more error checking/handling
set -e # Abort on any error

# For zenity, which provides feedback and a progress bar.
export DISPLAY=:1

# The echo statements within the subshell are of the form:
# percentage\n# message
# See zenity manual for more details
(
  echo -e "25\n# Creating post script messsage socket daemon..."
  cat - >/etc/systemd/system/post-graphical-feedback.service <<EOF
[Unit]
Description=graphical feedback dialog with named pipe inside chroot

[Service]
Type=exec
User=root
Group=root
Environment=SOCKET=/mnt/sysimage/tmp/graphical-feedback
Environment=DISPLAY=${DISPLAY}
# Mush use bash for '||' (or) to work
ExecStartPre=/bin/bash -c '[ -e \${SOCKET} ] || /bin/mknod \${SOCKET} p'
# Must use bash for streams (pipe) to work.
# --auto-close will cause zenity to exit when a progress of 100% is
# send to it
ExecStart=/bin/bash -c 'cat \${SOCKET} | /bin/zenity --width=600 --progress --auto-close --no-cancel --title="Post install script progress" --text="Waiting for chrooted post script to start..."'
ExecStop=/bin/rm \${SOCKET}
Restart=on-failure
EOF

  echo -e "50\n# Reloading systemd..."
  systemctl daemon-reload

  echo -e "75\n# Starting new feedback service..."
  systemctl start post-graphical-feedback

  echo -e "100\n#End of non-chrooted post."
# Without auto-close, waits for user to press 'ok'
) | zenity --progress --no-cancel --auto-close
%end
