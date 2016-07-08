# `macvlan` and `ipvlan`

## Manually setting up `macvlan`

Add new network namespaces
```bash
ip netns add namespace1
ip netns add namespace2
```

Create the `macvlan` link attaching it to the parent host `eth0`
```bash
ip link add mymacvlan1 link eth0 type macvlan mode bridge
ip link add mymacvlan2 link eth0 type macvlan mode bridge
```

Move the new interface to our recently created network namespaces respectively
```bash
ip link set mymacvlan1 netns namespace1
ip link set mymacvlan2 netns namespace2
```

Bring interfaces in those respective namespaces up
```bash
ip netns exec namespace1 ip link set dev mymacvlan1 up
ip netns exec namespace2 ip link set dev mymacvlan2 up
```

Set IP address to those interfaces
```bash
ip netns exec namespace1 ifconfig mymacvlan1 192.168.121.50/24 up
ip netns exec namespace2 ifconfig mymacvlan2 192.168.121.60/24 up
```

See the IP addr and MAC addr assigned
```
ip netns exec namespace1 ip a
ip netns exec namespace2 ip a
```

Ping from one namespace to another, also ping the host machine.
```bash
ip netns exec namespace1 ping -c 2 192.168.121.60
ip netns exec namespace1 ping -c 2 192.168.121.1
```

Remove those namespaces
```
ip netns del namespace1
ip netns del namespace2
```

## `macvlan` using `docker`

### General `macvlan`

Create Docker Network
```bash
docker network  create  -d macvlan \
    --subnet=192.168.121.0/24 \
    --gateway=192.168.121.1 \
    -o macvlan_mode=bridge \
    -o parent=eth0 \
    macvlan1
```

Start two containers, named `fedora1` and `fedora2`
```bash
docker run --net=macvlan1 -it -d \
    --name fedora1 fedora:my bash
docker run --net=macvlan1 -it -d \
    --name fedora2 fedora:my bash
```

Get IP addresses of the `eth0` interface in both containers
```bash
docker exec -it fedora1 ip a sh eth0
docker exec -it fedora2 ip a sh eth0
```

Ping each other from the containers
```bash
docker exec -it fedora1 ping -c 2 fedora2
docker exec -it fedora2 ping -c 2 fedora1
```

`curl` from the server running on the host machine of this VM.
```bash
docker exec -it fedora1 \
    curl 192.168.121.1:8000/Vagrantfile
```

### Cleanup

Stop all running containers, remove them, remove all manually added networks
```bash
docker stop $(docker ps -qa)
docker rm -f $(docker ps -aq)
docker network rm macvlan1
```

**Note**: In both `macvlan` and `ipvlan` you are not able to ping or communicate with the default namespace IP address. For example, if you create a container and try to ping the Docker host's eth0 it will not work. That traffic is explicitly filtered by the kernel modules themselves to offer additional provider isolation and security.

### Exclude IP addresses in Network creation

```bash
docker network create -d macvlan \
    --subnet=192.168.121.0/24 \
    --gateway=192.168.121.1 \
    --aux-address="exclude_host=192.168.121.224" \
    --aux-address="exclude_host=192.168.121.8" \
    -o macvlan_mode=bridge \
    -o parent=eth0 \
    macvlan1
```


## Manual `ipvlan l2` mode

Add the new namespaces
```bash
ip netns add myns1
ip netns add myns2
```

Create the `ipvlan` link and attach it to parent interface `eth0`
```bash
ip link add ipvlan1 link eth0 type ipvlan mode l2
ip link add ipvlan2 link eth0 type ipvlan mode l2
```

Move those interfaces to new namespace
```bash
ip link set ipvlan1 netns myns1
ip link set ipvlan2 netns myns2
```

Bring up those interfaces
```bash
ip netns exec myns1 ip link set dev ipvlan1 up
ip netns exec myns2 ip link set dev ipvlan2 up
```

Set IP addresses
```bash
ip netns exec myns1 ifconfig ipvlan1 192.168.121.130/24 up
ip netns exec myns2 ifconfig ipvlan2 192.168.121.140/24 up
```

Remove those namespaces
```bash
ip netns del myns1
ip netns del myns2
```

## `ipvlan` using `docker`

### General `l2` mode network

Create Docker Network
```bash
docker network create -d ipvlan \
    --subnet=192.168.121.0/24 \
    --gateway=192.168.121.1 \
    -o ipvlan_mode=l2 \
    -o parent=eth0 \
    ipvlan1
```

Start two containers, named `fedora1` and `fedora2`
```bash
docker run --net=ipvlan1 -it -d  \
    --name fedora1 fedora:my bash
docker run --net=ipvlan1 -it -d  \
    --name fedora2 fedora:my bash
```

Get IP addresses of the `eth0` interface in both containers
```bash
docker exec -it fedora1 ip a sh eth0
docker exec -it fedora2 ip a sh eth0
```

Ping each other from the containers
```bash
docker exec -it fedora1 ping -c 2 fedora2
```

### Isolated `l2` mode network

```bash
docker network create -d ipvlan \
    --subnet=192.168.121.0/24  \
    --internal \
    -o ipvlan_mode=l2 \
    -o parent=eth0 \
    ipvlan3
```