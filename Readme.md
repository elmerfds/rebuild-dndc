# Rebuild-DNDC
Re-create containers that use another container's network stack (e.g. routing container traffic through a VPN container).

* RDNDC will monitor the master container during updates, reboots or after host reboots and rebuild dependent containers.
* Only supported on unRAID at the moment.
* Any containers using the master container network stack will be auto added to the watch list. 

## Prerequisites
1. Make sure the master container (e.g. vpn container) is up & running as expected.
2. Create a docker network named container:master_container_name , to do that, do the following:
   open terminal > `docker network create container:master_container_name`  note: container name is case-sensitive
3. Now edit a container you want to add to the master container network stack
4. You should see the created network (step 2) under 'network type', select that & click 'apply'. 

![image](https://user-images.githubusercontent.com/22656503/68093132-3b93e180-fe8a-11e9-8ab8-06934fad3358.png)

Note: Step 2 & 4 replaces the use of `--net=container:master_container_name` in extra parameters & are required to work on unRAID 6.8.0-rcx & subsequent releases.

## Docker

**Community Applications (unRAID) - recommended** 

1. Open the 'Apps' tab and 
2. Search for 'rebuild-dndc' 
3. Click on the Download button

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

### - Create dependent containers manually
If for some reason master container dependent containers have failed to be **created**, you can start several containers using a single command, which is far more convenient than doing it through the unRAID GUI.

`docker exec Rebuild-DNDC /bin/sh -c "rebuildm -b container01 container02 container03"`

OR

`docker exec Rebuild-DNDC /bin/sh -c "rebuildm -f container01 container02 container03"`


* Replace containerXX with the actual containers you want to create (case-sensitive).
* Manual run is not limited to containers dependent on master container network. As long as the docker template for that container exists, it will create the container.
* -b : Attempts a container rebuild only, if that container already exists, rebuild will be skipped.
* -f : Stop/remove and rebuild containers if it exists or not.


### Credits

***

- ParseDockerTemplate.sh: author unRAID forum member: skidelo; contributors: Alex R. Berg and eafx; [source](https://forums.unraid.net/topic/40016-start-docker-template-via-command-line)

- Discord notifications: Discord.sh; source: [source](https://github.com/ChaoticWeg/discord.sh)

- Logo: based on the icon made by Pause08 from www.flaticon.com
