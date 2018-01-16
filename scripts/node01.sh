#!/bin/bash
while [[ $# > 1 ]]
do
  key="$1"

  case $key in
    -o|--os)
    OS="$2"
    shift
    ;;
    -zo|--zipos)
    ZIP_OS="$2"
    shift
    ;;
    -d|--device)
    DEVICE="$2"
    shift
    ;;
    -i|--installpath)
    INSTALLPATH="$2"
    shift
    ;;
    -v|--version)
    VERSION="$2"
    shift
    ;;
    -n|--packagename)
    PACKAGENAME="$2"
    shift
    ;;
    -f|--firstmdmip)
    FIRSTMDMIP="$2"
    shift
    ;;
    -s|--secondmdmip)
    SECONDMDMIP="$2"
    shift
    ;;
    -tb|--tbip)
    TBIP="$2"
    shift
    ;;
    -si|--scaleioinstall)
    SCALEIOINSTALL="$2"
    shift
    ;;
    -dk|--dockerinstall)
    DOCKERINSTALL="$2"
    shift
    ;;
    -r|--rexrayinstall)
    REXRAYINSTALL="$2"
    shift
    ;;
    -dir|--volumedir)
    VOLUMEDIR="$2"
    shift
    ;;
    -ds|--swarminstall)
    SWARMINSTALL="$2"
    shift
    ;;
    *)
    # unknown option
    ;;
  esac
  shift
done
echo DEVICE  = "${DEVICE}"
echo INSTALL PATH     = "${INSTALLPATH}"
echo VERSION    = "${VERSION}"
echo OS    = "${OS}"
echo PACKAGENAME    = "${PACKAGENAME}"
echo FIRSTMDMIP    = "${FIRSTMDMIP}"
echo SECONDMDMIP    = "${SECONDMDMIP}"
echo TBIP    = "${TBIP}"
echo PASSWORD    = "${PASSWORD}"
echo SCALEIOINSTALL   =  "${SCALEIOINSTALL}"
echo DOCKERINSTALL     = "${DOCKERINSTALL}"
echo REXRAYINSTALL     = "${REXRAYINSTALL}"
echo VOLUMEDIR     = "${VOLUMEDIR}"
echo SWARMINSTALL     = "${SWARMINSTALL}"
echo ZIP_OS    = "${ZIP_OS}"

echo "Checking Interface State: enp0s8"
INTERFACE_STATE=$(cat /sys/class/net/enp0s8/operstate)
if [ "${INTERFACE_STATE}" == "down" ]; then
  echo "Bringing Up Interface: enp0s8"
  ifup enp0s8
fi

echo "Adding Nodes to /etc/hosts"
echo "192.168.50.11 master" >> /etc/hosts
echo "192.168.50.12 node01" >> /etc/hosts
echo "192.168.50.13 node02" >> /etc/hosts

if [ "${DOCKERINSTALL}" == "true" ]; then
  echo "Installing Docker"
  yum install -y yum-utils
  yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
  yum makecache fast
  yum install docker-ce -y
  echo "Setting Docker service to Start on boot"
  systemctl enable docker
  systemctl start docker
  echo "Setting Docker Permissions"
  usermod -aG docker vagrant
  echo "Restarting Docker"
  systemctl restart docker
fi

if [ "${SCALEIOINSTALL}" == "true" ]; then
  VERSION_MAJOR=`echo "${VERSION}" | awk -F \. {'print $1'}`
  VERSION_MINOR=`echo "${VERSION}" | awk -F \. {'print $2'}`
  VERSION_MINOR_FIRST=`echo $VERSION_MINOR | awk -F "-" {'print $1'}`
  VERSION_MAJOR_MINOR=`echo $VERSION_MAJOR"."$VERSION_MINOR_FIRST`
  VERSION_MINOR_SUB=`echo $VERSION_MINOR | awk -F "-" {'print $2'}`
  VERSION_MINOR_SUB_FIRST=`echo $VERSION_MINOR_SUB | head -c 1`
  VERSION_SUMMARY=`echo $VERSION_MAJOR"."$VERSION_MINOR_FIRST"."$VERSION_MINOR_SUB_FIRST`

  echo VERSION_MAJOR = $VERSION_MAJOR
  echo VERSION_MAJOR_MINOR = $VERSION_MAJOR_MINOR
  echo VERSION_SUMMARY = $VERSION_SUMMARY

  #echo "Number files in SEARCH PATH with EXTENSION:" $(ls -1 "${SEARCHPATH}"/*."${EXTENSION}" | wc -l)
  truncate -s 100GB ${DEVICE}
  yum install unzip numactl libaio socat -y

  cd /vagrant
  DIR=`unzip -n -l "ScaleIO_Linux_v"$VERSION_MAJOR_MINOR".zip" | awk '{print $4}' | grep $ZIP_OS | awk -F'/' '{print $1 "/" $2 "/" $3}' | head -1`

  echo "Entering directory /vagrant/scaleio/$DIR"
  cd /vagrant/scaleio/$DIR

  MDMRPM=`ls -1 | grep "\-mdm\-"`
  SDSRPM=`ls -1 | grep "\-sds\-"`
  SDCRPM=`ls -1 | grep "\-sdc\-"`

  echo "Installing MDM $MDMRPM"
  MDM_ROLE_IS_MANAGER=1 rpm -Uv $MDMRPM 2>/dev/null
  echo "Installing SDS $SDSRPM"
  rpm -Uv $SDSRPM 2>/dev/null
  echo "Installing SDC $SDCRPM"
  MDM_IP=${FIRSTMDMIP},${SECONDMDMIP} rpm -Uv $SDCRPM 2>/dev/null
fi

if [ "${REXRAYINSTALL}" == "true" ]; then
  if [ "${SCALEIOINSTALL}" == "true" ]; then
    echo "Installing REX-Ray and Configuring for ScaleIO"
    /vagrant/scripts/rexray-scaleio.sh
  else
    echo "Installing REX-Ray and Configuring for VirtualBox Media Local Volumes"
    /vagrant/scripts/rexray-vbox.sh
    sed -i "s|/tmp|${VOLUMEDIR}|" /etc/rexray/config.yml
    systemctl daemon-reload
    systemctl start rexray
    systemctl enable rexray
    #sed -i '/.*volumePath.*/c\\\x20\x20volumePath: \"#{VOLUMEDIR}\"' /etc/rexray/config.yml
  fi
fi

if [ "${SWARMINSTALL}" == "true" ]; then
  echo "Configuring Host as Docker Swarm Worker"
  WORKER_TOKEN=`cat /vagrant/swarm_worker_token`
	docker swarm join --listen-addr ${SECONDMDMIP} --advertise-addr ${SECONDMDMIP} --token=$WORKER_TOKEN ${FIRSTMDMIP}
fi

if [[ -n $1 ]]; then
  echo "Last line of file specified as non-opt/last argument:"
  #tail -1 $1
fi
