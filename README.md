vg-docker-rexray
---------------

# Description

Automatically deploy Docker and REX-Ray in an isolated environment on top of VirtualBox to test containers with persistent applications including an option of using Docker Swarm

## Quick Start

#### Deploy with Dell EMC ScaleIO Storage
```
$ vagrant up
```

#### Deploy with Local VirtualBox Media
In a terminal window, start the VirtualBox API SOAP Service
```
$ VBoxManage setproperty websrvauthlibrary null
$ vboxwebsrv -H 0.0.0.0 -v
```

```
$ export VG_SCALEIO_INSTALL=false
$ vagrant up
```

## Usage
Environment Details:

- Deploys three (3) CentOS 7.3 nodes on top of VirtualBox
- By default, the latest stable version of [Docker](https://docker.com) is installed. If `VG_DOCKER_INSTALL` is set to false, then Docker is not installed.
- By default, each node gets installed with [Dell EMC ScaleIO](https://www.dellemc.com/en-us/storage/scaleio/index.htm) software. Configuration happens automatically to have a fully redundant ScaleIO cluster. If `VG_SCALEIO_INSTALL` is set to `false`, then ScaleIO is not installed and VirtualBox is configured for Virutal Media.
  - The ScaleIO gateway is installed as a Docker image on the `master` machine. If `VG_SCALEIO_GW_DOCKER` is set to false, then the ScaleIO Gateway is installed as a traditional linux service on `master`.
- By default, [REX-Ray](https://github.com/thecodeteam/rexray) is installed on each node and configured automatically according to the storage backing service (scaleio or virtualbox).
- Optionally, [Docker Swarm](https://docs.docker.com/engine/swarm/) can be configured for the cluster by setting the environment variable `export VG_SWARM_INSTALL=true`.

Set the following Environment Variables to `true` or `false` for your needs (must use `export`)

 - `VG_SCALEIO_INSTALL` - Default is `true`. If `true` a fully working ScaleIO cluster is installed.
 - `VG_SCALEIO_GW_DOCKER` - Default is `true` which installs the Gateway as a Docker image. `false` will install it as a traditional Linux service.
 - `VG_DOCKER_INSTALL` - Default is `true`.
 - `VG_REXRAY_INSTALL` - Default is `true`.
 - `VG_SWARM_INSTALL` - Default is `false`. Set to `true` to automatically configure Docker Swarm with `master` being the Docker Swarm master.
 - `VG_SCALEIO_RAM` - Default is `1024`. Depending on the docker images being used, RAM needs to be increased to 1.5GB or 2GB for node01 and node02. Master will always use 3GB.
 - `VG_SCALEIO_VERIFY_FILES` - Default is `true`. This will verify the ScaleIO package is available for download.
 - `VG_VOLUME_DIR` - Default will use the current working path (`pwd`) for placement of volumes.

1. `git clone https://github.com/thecodeteam/vg-docker-rexray`
2. `cd vg-docker-rexray`
3. set any environment variables needed
4. `vagrant up` (if you have more than one Vagrant Provider on your machine run `vagrant up --provider virtualbox` instead)

Note, the cluster will come up with the default unlimited license for [Dell EMC ScaleIO](https://www.dellemc.com/en-us/storage/scaleio/index.htm) dev and test use.

### SSH

To login to the nodes, use the following commands: `vagrant ssh master`, `vagrant ssh node01`, or `vagrant ssh node02`.

## Using Docker and REX-Ray

Docker and REX-Ray will automatically be installed on all three nodes but can be overridden using the Environment Variables above. Each will configure REX-Ray to manage ScaleIO or local VirtualBox volumes for persistent applications in containers.

To run a container with persistent data, from any of the cluster nodes you can run the following examples (the examples do not change based on the storage used. REX-Ray abstracts the storage provider so commands are universal):

Pre-provision new volumes with REX-Ray:
```
sudo rexray volume create test --size=16
sudo rexray volume ls
```

**Automatically provision new volumes on the fly when containers are created**
Run Busybox with a volume mounted at `/data`:
```
docker run -it --volume-driver=rexray -v data:/data busybox
```

Run Redis with a volume mounted at `/data`:
```
docker run -d --volume-driver=rexray -v redis-data:/data redis
```

Run MySQL with a volume mounted at `/var/lib/mysql`:
````
docker run -d --volume-driver=rexray -v mysql-data:/var/lib/mysql -e MYSQL_ROOT_PASSWORD=my-secret-pw mysql
````

Visit the [{code} Labs](https://github.com/thecodeteam/labs) for more examples using Postgres and Minecraft.

#### Docker High Availability

Since the nodes all have access to centralized storage, fail over services with REX-Ray are available by stopping a container with a persistent volume on one host, and start it on another. Docker's integration with REX-Ray will automatically map the same volume to the new container, and your application can continue working as intended.

## Docker Swarm

`master` machine has been designated for the management role because when ScaleIO is utilized, the ScaleIO Gateway for API communication is installed on this machine. `node01` and `node02` are configured as Worker nodes with no management functionality.

Automatically build a Swarm cluster with `export VG_SWARM_INSTALL=true` as an environment variable.

The `docker service` command is used to create a service that is scheduled on nodes and can be rescheduled on a node failure. As a quick demonstration go to `master` and run a postgres service and pin it to the worker nodes:

```
$ docker service create --replicas 1 --name pg -e POSTGRES_PASSWORD=mysecretpassword \
--mount type=volume,target=/var/lib/postgresql/data,source=postgres,volume-driver=rexray \
--constraint 'node.role == worker' postgres
```

Use `docker service ps pg` to see which node it was scheduled on. Go to that node and stop the docker service with `sudo systemctl stop docker`. On master, a `docker service ps pg` will show the container being rescheduled on a different worker.

If it doesn't work, restart the service on the node, go to the other and download the image using `docker pull postgres` and start again.


## ScaleIO GUI

The ScaleIO GUI is automatically extracted and put into the `vagrant/scaleio/gui` directory when ScaleIO is installed. Execute `./run.sh` from the `/gui` directory. Connect to your instance with the credentials:
 - Username: admin
 - Password: Scaleio123

The end result will look like this:

![alt text](docs/images/scaleio-docker-rexray.png)

# Troubleshooting

If anything goes wrong during the deployment, run `vagrant destroy -f` to remove all the VMs and then `vagrant up` again to restart the deployment.

# Contribution Rules

Create a fork of the project into your own repository. Make all your necessary changes and create a pull request with a description on what was added or removed and details explaining the changes in lines of code. If approved, project owners will merge it.

# Support

Please file bugs and issues on the [GitHub issues page](https://github.com/thecodeteam/vg-docker-rexray/issues). This is to help keep track and document everything related to this repo. For general discussions and further support you can join the [{code} Community Slack](http://community.thecodeteam.com/). The code and documentation are released with no warranties or SLAs and are intended to be supported through a community driven process.
