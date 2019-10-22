#!/bin/bash
#author: https://github.com/elmerfdz
ver=1.0.0

#VARS
RUNDOCKERTEMPLATE_SCRIPT='/tmp/user.scripts/tmpScripts/ParseDockerTemplate/script'
inscope_containers=('ContainerA' 'ContainerB' 'ContainerC')  # replace with containers using your VPN container, case-sensitive
docker_tmpl_loc='/boot/config/plugins/dockerMan/templates-user'

echo
echo "CREATE CONTAINERS MANUALLY"

for ((a=0; a < "${#inscope_containers[@]}"; a++)) 
do
    inscope_cont_tmpl+=($(find $docker_tmpl_loc -type f -iname "*-${inscope_containers[$a]}.xml"))
    echo
    echo "--Build ${inscope_containers[$a]}"
    echo
    $RUNDOCKERTEMPLATE_SCRIPT -v ${inscope_cont_tmpl[$a]}
    echo
done
