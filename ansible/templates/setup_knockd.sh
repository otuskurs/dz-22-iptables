#!/bin/bash

# Конфигурация /etc/default/knockd
grep -q '^START_KNOCKD=' /etc/default/knockd && \
    sed -i 's/^START_KNOCKD=.*/START_KNOCKD=1/' /etc/default/knockd || \
    echo 'START_KNOCKD=1' >> /etc/default/knockd

# Создание файла systemd unit для knockd
cat <<EOF >/etc/systemd/system/knockd.service
[Unit]
Description=Port-Knock Daemon
After=network.target
Requires=network.target
Documentation=man:knockd(1)

[Service]
EnvironmentFile=-/etc/default/knockd
ExecStartPre=/usr/bin/sleep 1
ExecStart=/usr/sbin/knockd \$KNOCKD_OPTS
ExecReload=/bin/kill -HUP \$MAINPID
KillMode=mixed
Restart=always
SuccessExitStatus=0 2 15
ProtectSystem=full
CapabilityBoundingSet=CAP_NET_RAW CAP_NET_ADMIN

[Install]
WantedBy=multi-user.target
EOF

# Создание файла конфигурации /etc/knockd.conf
cat <<EOF >/etc/knockd.conf
[options]
UseSyslog
Interface = enp0s8

[opencloseSSH]
sequence    = 7777:tcp,9991:tcp,22:tcp
seq_timeout = 15
tcpflags    = syn
start_command = /sbin/iptables -I INPUT 1 -s %IP% -p tcp --dport 22 -j ACCEPT
cmd_timeout = 30
stop_command  = /sbin/iptables -D INPUT -s %IP% -p tcp --dport 22 -j ACCEPT
EOF


# Настройка правил iptables
iptables-save > /etc/iptables/rules.v4.original
cat <<EOF >/etc/iptables/rules.v4
*filter
:INPUT DROP [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:TRAFFIC - [0:0]
:SSH-INPUT - [0:0]
:SSH-INPUTTWO - [0:0]
-A INPUT -p icmp -j ACCEPT
-A INPUT -i lo -j ACCEPT
-A INPUT -i enp0s8 -j TRAFFIC
-A TRAFFIC -i enp0s8 -m state --state RELATED,ESTABLISHED -j ACCEPT
-A TRAFFIC -i enp0s8 -p tcp -m state --state NEW -m tcp --dport 22 -m recent --rcheck --seconds 30 --name SSH2 --mask 255.255.255.255 --rsource -j ACCEPT
-A TRAFFIC -i enp0s8 -p tcp -m state --state NEW -m tcp -m recent --remove --name SSH2 --mask 255.255.255.255 --rsource -j DROP
-A TRAFFIC -i enp0s8 -p tcp -m state --state NEW -m tcp --dport 9991 -m recent --rcheck --name SSH1 --mask 255.255.255.255 --rsource -j SSH-INPUTTWO
-A TRAFFIC -i enp0s8 -p tcp -m state --state NEW -m tcp -m recent --remove --name SSH1 --mask 255.255.255.255 --rsource -j DROP
-A TRAFFIC -i enp0s8 -p tcp -m state --state NEW -m tcp --dport 7777 -m recent --rcheck --name SSH0 --mask 255.255.255.255 --rsource -j SSH-INPUT
-A TRAFFIC -i enp0s8 -p tcp -m state --state NEW -m tcp -m recent --remove --name SSH0 --mask 255.255.255.255 --rsource -j DROP
-A TRAFFIC -i enp0s8 -p tcp -m state --state NEW -m tcp --dport 8881 -m recent --set --name SSH0 --mask 255.255.255.255 --rsource -j DROP
-A TRAFFIC -i enp0s8 -j DROP
COMMIT

*nat
:PREROUTING ACCEPT [0:0]
:INPUT ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
-A POSTROUTING ! -d 192.168.0.0/16 -o enp0s3 -j MASQUERADE
COMMIT
EOF
iptables-restore < /etc/iptables/rules.v4


# Проверка статуса systemd
systemctl daemon-reload

# Включение и запуск knockd
systemctl enable knockd
systemctl start knockd
