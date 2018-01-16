curl -sSL https://dl.bintray.com/emccode/rexray/install | sh -s -- stable
cat << EOF > /etc/rexray/config.yml
libstorage:
  service: virtualbox
  integration:
    volume:
      operations:
        mount:
          preempt: true
virtualbox:
  endpoint: http://192.168.50.1:18083
  volumePath: /tmp
  controllerName: SATA Controller
EOF
sed -i '/KillMode/a RestartSec=10' /etc/systemd/system/rexray.service
sed -i '/KillMode/a Restart=always' /etc/systemd/system/rexray.service
