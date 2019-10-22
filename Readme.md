# UnRAIDscripts

## AutoRebuildContainers
Re-create containers that use another container's network stack (i.e. routing container traffic through a VPN container)

### Pre-requisites
- Install 'User Scripts' plugins from CA
- Use the same script names
- Tested on 6.8.0-rcxx

#### ParseDockerTemplate
- Create a script called 'ParseDockerTemplate' on 'User Scripts'
- Set it to run 'At First Array Start Only' on 'User Scripts'
- This script on it's own doesn't do anything without specifying any arguments.
- Run this script once, so that the 'User Script' plugin copies the script files to /tmp/user.scripts/tmpScripts/ (required for 6.8.0-rcx releases) 

#### RecreateVPNcontainers
- Create a script called 'RecreateVPNcontainers' on 'User Scripts'
- Edit script and set the variable `VPNCONTNAME=your_vpn_container_name` , by default it is set to `VPNCONTNAME=vpn`
- Make sure you have your VPN container is running
- Make sure all containers that will be using the VPN container network stack are up & running.
- Run the script & monitor the output.
- If everything is working as expected, set it to run at whatever interval you prefer, e.g. 5mins i.e.  `*/5 * * * *`

#### Note:
1. Any containers that are using `--net=container:vpn_container_name` extra parameter, will automatically be added to the script watch list when it runs.
2. If you want to remove a container from the watch list, simply remove `--net=container:vpn_container_name` parameter & run the script.
3. If for whatever reason you need to restart your VPN container, instead of restarting, delete & re-create the container, that way the script will re-create all other containers relying on it's network stack.
