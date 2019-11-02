#!/bin/bash
#author: https://github.com/elmerfdz
ver=1.1.0

#VARS
inscope_containers=("$@") 

echo
echo "CREATE CONTAINERS MANUALLY"

for ((a=0; a < "${#inscope_containers[@]}"; a++)) 
do
    inscope_cont_tmpl+=($(find $docker_tmpl_loc -type f -iname "*-${inscope_containers[$a]}.xml"))
    echo
    echo "--Build ${inscope_containers[$a]}"
    echo
    $rundockertemplate_script -v ${inscope_cont_tmpl[$a]}
    echo
done
