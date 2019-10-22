# UnRAIDscripts

## AutoRebuildContainers
Re-create containers that use another container's network stack (i.e. routing container traffic through a VPN container)

### Prerequisites
- Install 'User Scripts' plugins from CA
- Use the same script names
- ParseDockerTemplate script
- Tested on 6.8.0-rcxx

#### ParseDockerTemplate (Required)
- Create a script called 'ParseDockerTemplate' on 'User Scripts'
- Set it to run 'At First Array Start Only' on 'User Scripts'
- This script on it's own doesn't do anything without specifying any arguments.
- Run this script once, so that the 'User Script' plugin copies the script files to /tmp/user.scripts/tmpScripts/ (required for 6.8.0-rcx releases), _Ignore the File does not exist error_

#### RecreateVPNcontainers (Required)
- Create a script called 'RecreateVPNcontainers' on 'User Scripts'
- Edit script and set the variable `VPNCONTNAME=your_vpn_container_name` , by default it is set to `VPNCONTNAME=vpn`
- Make sure you have your VPN container up & running
- Make sure all containers that will be using the VPN container network stack are up & running.
- Run the script & monitor the output.
- If everything is working as expected, set it to run at whatever interval you prefer, e.g. 5mins i.e.  `*/5 * * * *`

#### RecreateVPNcontainerManual (optional)
- Create a script called 'RecreateVPNcontainersManual' on 'User Scripts'
- Edit the line `inscope_containers=('ContainerA' 'ContainerB' 'ContainerC')` . Replace ContainerA/B/C with the container names that use the VPN container network.
- This script can come in handy during times when for whatever reason the 'RecreateVPNcontainer' has failed to detect/rebuild the containers.

#### Note:
1. Any containers that are using `--net=container:vpn_container_name` extra parameter, will automatically be added to the script watch list when it runs.
2. If you want to remove a container from the watch list, simply remove `--net=container:vpn_container_name` parameter & run the script.
3. If for whatever reason you need to restart your VPN container, instead of restarting, delete & re-create the container, that way the script will re-create all other containers relying on it's network stack.
4. For Unraid 6.8.0-rcx users, `--net=container:vpn_container_name` extra parameter doesn't work. You can get around this issue by doing the following:

- Open terminal > `docker network create container:vpn_container_name` > Now edit a container you want to add to the VPN network stack, you should see the created network under 'network type' and do not add the `--net=container:vpn_container_name` in extra parameters.

![](https://ipsassets.unraid.net/uploads/monthly_2019_10/image.png.8c9db7f96da162cb4723bb6cccba0f44.png)
