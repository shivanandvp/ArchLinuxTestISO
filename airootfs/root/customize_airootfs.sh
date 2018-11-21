#!/bin/bash

set -e -u

sed -i 's/#\(en_US\.UTF-8\)/\1/' /etc/locale.gen
locale-gen

ln -sf /usr/share/zoneinfo/UTC /etc/localtime

usermod -s /usr/bin/zsh root
cp -aT /etc/skel/ /root/
chmod 700 /root

sed -i 's/#\(PermitRootLogin \).\+/\1yes/' /etc/ssh/sshd_config
sed -i "s/#Server/Server/g" /etc/pacman.d/mirrorlist
sed -i 's/#\(Storage=\)auto/\1volatile/' /etc/systemd/journald.conf

sed -i 's/#\(HandleSuspendKey=\)suspend/\1ignore/' /etc/systemd/logind.conf
sed -i 's/#\(HandleHibernateKey=\)hibernate/\1ignore/' /etc/systemd/logind.conf
sed -i 's/#\(HandleLidSwitch=\)suspend/\1ignore/' /etc/systemd/logind.conf

systemctl enable pacman-init.service choose-mirror.service

#=============#
# Custom code #
#=============#
cat>/etc/lightdm/lightdm.conf<< EOL
[LightDM]
run-directory=/run/lightdm

[Seat:*]
pam-service=lightdm
pam-autologin-service=lightdm-autologin
session-wrapper=/etc/lightdm/Xsession
autologin-user=root
autologin-user-timeout=0
EOL
groupadd -r autologin
gpasswd -a root autologin
cat>/etc/pam.d/lightdm-autologin<< EOL
#%PAM-1.0
auth        required    pam_env.so
auth        required    pam_tally.so file=/var/log/faillog onerr=succeed
auth        required    pam_shells.so
auth        required    pam_nologin.so
# auth        [success=1 default=ignore]  pam_succeed_if.so user ingroup autologin
auth        required    pam_unix.so
auth        required    pam_permit.so
-auth       optional    pam_gnome_keyring.so
account     include     system-local-login
password    include     system-local-login
session     include     system-local-login
-session    optional    pam_gnome_keyring.so auto_start
EOL

systemctl set-default graphical.target
systemctl enable lightdm
systemctl start lightdm.service
mv /etc/skel/xinitrc /etc/X11/xinit/xinitrc

