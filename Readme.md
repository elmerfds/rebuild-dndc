# UnRAIDscripts

## Rebuild-DNDC
Re-create containers that use another container's network stack (i.e. routing container traffic through a VPN container)
* [Docker](https://github.com/elmerfdz/unRAIDscripts/wiki/_new#docker)
* [Host](https://github.com/elmerfdz/unRAIDscripts/wiki/_new#host)
## Docker

**Docker Run**

```
docker run -d --name='Rebuild-DNDC' --net='bridge' -e TZ="Europe/London" -e 'mastercontname'='vpn' -e 'ping_count'='4' -e 'ping_ip'='1.1.1.1' -e 'mastercontconcheck'='yes' -e 'sleep_secs'='10' -e 'cron'='*/5 * * * *' -e 'startup'='true' -e 'discord_url'='https://discordapp.com/api/webhooks/xxxxxxxxxxxxxx/xxxxxxxxxxxxxxxxxxx' -e 'discord_notifications'='yes' -v '/var/run/docker.sock':'/var/run/docker.sock':'rw' -v '/boot/config/plugins/dockerMan/templates-user':'/config/docker-templates':'ro' -v '/mnt/cache/appdata/rebuild-dndc/config/rebuild-dndc':'/config/rebuild-dndc':'rw' 'eafxx/rebuild-dndc:unraid-m' 

```

## Parameters

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
| `-e startup=yes` | Do a first run immediately without waiting [yes/no] |
| `-e discord_notifications=yes` | Enable Discord notifications [yes/no] |
| `-e discord_url` | Full Discord webhook URL, only required if notifications are enabled |
| `-v /config/docker-templates` | Path to user docker templates on Unraid (read-only) |
| `-v /var/run/docker.sock` | Docker socket location |
| `-v /config/rebuild-dndc` | Contains container monitor list. |
| `-e TZ=Europe/London` | Specify a timezone to use e.g. Europe/London |

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
- Make sure you have your master container up & running
- Make sure all containers that will be using the master container network stack are up & running.
- Run the script & monitor the output.
- If everything is working as expected, set it to run at whatever interval you prefer, e.g. 5mins i.e.  `*/5 * * * *`
- Try restarting, deleting & rebuilding the master container, the script should be able to detect & rebuild all containers relying on the master container.

##### Note:
1. Any containers that are using `--net=container:vpn_container_name` extra parameter, will automatically be added to the script watch list when it runs.
2. If you want to remove a container from the watch list, simply remove `--net=container:vpn_container_name` parameter & run the script.
3. For Unraid 6.8.0-rcx users, `--net=container:vpn_container_name` extra parameter doesn't work. You can get around this issue by doing the following:

- Open terminal > `docker network create container:vpn_container_name` > Now edit a container you want to add to the VPN network stack, you should see the created network under 'network type' and do not add the `--net=container:vpn_container_name` in extra parameters.

![](https://ipsassets.unraid.net/uploads/monthly_2019_10/image.png.8c9db7f96da162cb4723bb6cccba0f44.png)
