# [eafxx/rebuild-dndc](https://hub.docker.com/r/eafxx/rebuild-dndc)
Re-create containers that use another container's network stack (e.g. routing container traffic through a VPN container).

* RDNDC will monitor the master container during container re-creation/updates/reboots/host reboots and rebuilds dependent containers using the master container's network stack.
* Only supported on unRAID at the moment.
* Any containers using the master container network stack will be auto added to the watch list. 

## Prerequisites
1. Make sure the master container (e.g. vpn container) is up & running as expected.
2. Create a docker network named container:master_container_name , to do that, do the following:
   open terminal > `docker network create container:master_container_name`  note: master container name should be all lower case, rename your container if it isn't. 
3. Now edit a container you want to add to the master container network stack
4. You should see the created network (step 2) under 'network type', select that & click 'apply'. 

![image](https://user-images.githubusercontent.com/22656503/68093132-3b93e180-fe8a-11e9-8ab8-06934fad3358.png)

**OR** 

Alternate steps

2. Edit a container you want to add to the master container network stack, 
3. Add `--net=container:master_container_name` in extra parameters and 
4. click 'apply' 

## Docker

**Tags**

| Tag      | Description                          | Build Status                                                                                                | 
| ---------|--------------------------------------|-------------------------------------------------------------------------------------------------------------|
| unraid-m | Unraid stable                 | ![Docker Build Master](https://github.com/elmerfdz/unRAIDscripts/workflows/Docker%20Build%20Master/badge.svg)  | 
| unraid-d | Unraid development, pre-release      | ![Docker Build Dev](https://github.com/elmerfdz/unRAIDscripts/workflows/Docker%20Build%20Dev/badge.svg)     |
| unraid-e | Unraid  experimental, unstable        | ![Docker Build Exp](https://github.com/elmerfdz/unRAIDscripts/workflows/Docker%20Build%20Exp/badge.svg)     | 

**Community Applications (unRAID) - recommended** 

1. Open the 'Apps' tab and 
2. Search for 'rebuild-dndc' 
3. Click on the Install button

![ca](https://i.imgur.com/kpNEgGw.png)


**Docker Run** 

```
docker run -d --name='Rebuild-DNDC' --net='bridge' -e TZ="Europe/London" -e HOST_OS="Unraid" -e 'mastercontname'='vpn' -e 'mastercontconcheck'='yes' -e 'ping_ip'='1.1.1.1' -e 'ping_ip_alt'='8.8.8.8' -e 'ping_count'='4' -e 'sleep_secs'='10' -e 'run_startup'='yes' -e 'discord_notifications'='yes' -e 'discord_url'='https://discordapp.com/api/webhooks/xxxxxxxxxxxxxx/xxxxxxxxxxxxxxxxxxx' -e 'cron'='*/5 * * * *' -v '/var/run/docker.sock':'/var/run/docker.sock':'rw' -v '/boot/config/plugins/dockerMan/templates-user':'/config/docker-templates':'ro' -v '/mnt/appdata/rebuild-dndc/config/rebuild-dndc':'/config/rebuild-dndc':'rw' 'eafxx/rebuild-dndc:unraid-m' 

```

### - Parameters

Container images are configured using parameters passed at runtime (such as those above). 

| Parameter | Function |
| :----: | --- |
| `-e mastercontname=vpn` | Master container name, replace this with your master container name|
| `-e mastercontconcheck=yes` | Check for master container connectivity & reboot container if no connectivity [yes/no] |
| `-e ping_count=4` | Number of times you want to ping the ping_ip before the script restarts the master container due to no connectivity, lower number might be too aggressive - default 4 |
| `-e ping_ip=1.1.1.1` | Default ping IP to check master container connectivity |
| `-e ping_ip_alt=8.8.8.8` | Secondary ping IP to check master container connectivity (optional) |
| `-e sleep_secs=10` | Time to wait until the master container has completely booted up - default 10s |
| `-e cron=*/5 * * * *` | Cron schedule set to run every 5mins  - default 5mins|
| `-e run_startup=yes` | Do a first run immediately without waiting [yes/no] |
| `-e discord_notifications=yes` | Enable Discord notifications [yes/no] |
| `-e discord_url` | Full Discord webhook URL, only required if notifications are enabled |
| `-v /config/docker-templates` | Path to user docker templates on Unraid (read-only) |
| `-v /var/run/docker.sock` | Docker-daemon socket location |
| `-v /config/rebuild-dndc` | Contains container monitor list. |
| `-e TZ=Europe/London` | Specify a timezone to use e.g. Europe/London |

### - Additional Optional Parameters

| Parameter | Function |
| :----: | --- |
| `-e cont_list=ContainerA ContainerB` | Specify a list of containers that you can manually rebuild on demand using the rebuildm -b & rebuildm -f commands ([see below](https://github.com/elmerfdz/unRAIDscripts#--create-dependent-containers-manually)). Container names are case sensitive & leave space between each container name.  |

### - Port Forwarding Optional Parameters

#### Supported Apps
* ruTorrent

#### Requirements
* VPN image: [qmcgaw/private-internet-access](https://github.com/qdm12/private-internet-access-docker) (Supports PIA, Mullvad & Windscribe (coming soon) )

| Parameter | Function |
| :----: | --- |
| `-e rutorrent_cont_name=ruTorrent` | ruTorrent container name (case sensitive) |
| `-e rutorrent_pf=yes` | Enable ruTorrent Port Forwarding |
| `-v /app/pf/rutorrent/` | Path to ruTorrent `rtorrent.rc` or `.rtorrent.rc` file without specifying file name |

### - Create dependent containers manually

If for some reason master container dependent containers have failed to be **created**, you can start several containers using a single command, which is far more convenient than doing it through the unRAID GUI.

Interactive Shell

`docker exec -it Rebuild-DNDC bash -c 'rebuildm -b container01 container02 container03'`

`docker exec -it Rebuild-DNDC bash -c 'rebuildm -f container01 container02 container03'`

`docker exec -it Rebuild-DNDC bash -c 'rebuildm -b  $cont_list'`

`docker exec -it Rebuild-DNDC bash -c 'rebuildm -f  $cont_list'`

OR 

SSH onto Rebuild-DNDC container 

`rebuildm -b container01 container02 container03`

`rebuildm -f container01 container02 container03`

`rebuildm -b $cont_list`

`rebuildm -f $cont_list`

* Replace containerXX with the actual containers you want to create (case-sensitive).
* Manual run is not limited to containers dependent on master container network. As long as the docker template for that container exists, it will create the container.
* `-b` : Attempts a container rebuild only, if that container already exists, rebuild will be skipped.
* `-f` : Stop/remove and rebuild containers if it exists or not.
* `$cont_list` : List of containers that need to rebuild.

## Recommended VPN container

You can use any VPN image you want but the following is recommended and ruTorrent port forwarding with RDNDC is supported with the following image (PIA only!)

[qmcgaw/private-internet-access](https://github.com/qdm12/private-internet-access-docker) [Supports PIA, Mullvad & Windscribe (coming soon) ]

### Credits

***

- ParseDockerTemplate.sh: author unRAID forum member: skidelo; contributors: Alex R. Berg and eafx; [source](https://forums.unraid.net/topic/40016-start-docker-template-via-command-line)

- Discord notifications: Discord.sh; source: [source](https://github.com/ChaoticWeg/discord.sh)

- Logo: based on the icon made by Pause08 from www.flaticon.com
