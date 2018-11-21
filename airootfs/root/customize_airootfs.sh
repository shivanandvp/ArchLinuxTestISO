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
session-wrapper=/etc/lightdm/Xsession
autologin-guest=false
autologin-user=root
autologin-user-timeout=0
greeter-session = lightdm-webkit2-greeter
greeter-show-manual-login=false
greeter-hide-users=true
allow-guest=false
user-session=budgie-desktop

[XDMCPServer]

[VNCServer]

EOL
groupadd -r autologin
groupadd -r nopasswdlogin
gpasswd -a root autologin
gpasswd -a root nopasswdlogin

systemctl set-default graphical.target
systemctl enable lightdm
systemctl start lightdm.service
mv /etc/skel/xinitrc /etc/X11/xinit/xinitrc

