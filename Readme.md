# Rebuild-DNDC
Re-create containers that use another container's network stack (i.e. routing container traffic through a VPN container).

* RDNDC will monitor the master container during updates, reboots or after host reboots and rebuild dependent containers.
* Only supported on unRAID at the moment.
* Any containers using the master container network stack will be auto added to the watch list. 

## Prerequisites (Docker & Host)
1. Make sure the master container is up & running as expected.
2. Create a docker network named container:master_container_name , to do that, do the following:
   open terminal > `docker network create container:master_container_name`  note: container name is case-sensitive
3. Now edit a container you want to add to the master container network stack
4. You should see the created network (step 2) under 'network type', select that & click 'apply'. 

![image](https://user-images.githubusercontent.com/22656503/68093132-3b93e180-fe8a-11e9-8ab8-06934fad3358.png)

Note: Step 4 replaces the use of `--net=container:master_container_name` in extra parameters & is required to work on unRAID 6.8.0-rcx & subsequent releases.

* [Docker](https://github.com/elmerfdz/unRAIDscripts#docker)  (Recommended)
* [Host](https://github.com/elmerfdz/unRAIDscripts#host)

## Docker

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
| `-v /var/run/docker.sock` | Docker socket location |
| `-v /config/rebuild-dndc` | Contains container monitor list. |
| `-e TZ=Europe/London` | Specify a timezone to use e.g. Europe/London |

### - Create dependent containers manually
If for some reason master container dependent containers have failed to be **created**, you can start several containers using a single command, which is far more convenient than doing it through the unRAID GUI.

`docker exec Rebuild-DNDC /bin/sh -c "rebuildm container01 container02 container03"`

* Replace containerXX with the actual containers you want to create (case-sensitive).
* Manual run is not limited to containers dependent on master container network. As long as the docker template for that container exists, it will create the container.



## Host
#### Prerequisites
- Install 'User Scripts' plugins from CA
- Use the same script names
- ParseDockerTemplate script
- 6.8.0-rcxx is most probably not required but that's the last build I've tested this version of the script on.
- Or use the 

#### ParseDockerTemplate (Dependency)
- Create a script called 'ParseDockerTemplate' on 'User Scripts'
- Set it to run 'At First Array Start Only' on 'User Scripts'
- This script on it's own doesn't do anything without specifying any arguments.
- Run this script once, so that the 'User Script' plugin copies the script files to /tmp/user.scripts/tmpScripts/ (required for 6.8.0-rcx releases), `File '' does not exist!` message

#### Rebuild-DNDC (Required-Main)
- Create a script called 'Rebuild-DNDC' on 'User Scripts'
- Edit script and set the variable `mastercontname=your_vpn/master__container_name` , by default it is set to `mastercontname=vpn`
- Read & enable the variables under the `#USER CONFIGURABLE VARS` section of the script.
- Make sure you have your master container up & running
- Make sure all containers that will be using the master container network stack are up & running.
- Run the script & monitor the output.
- If everything is working as expected, set it to run at whatever interval you prefer, e.g. 5mins i.e.  `*/5 * * * *`
- Try restarting, deleting & rebuilding the master container, the script should be able to detect & rebuild all containers relying on the master container.

### Credits

***

ParseDockerTemplate.sh: author unRAID forum member: skidelo; contributors: Alex R. Berg and eafx; source: [link](https://forums.unraid.net/topic/40016-start-docker-template-via-command-line)

Temporary logo based on the icon made by Pause08 from www.flaticon.com