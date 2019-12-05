#!/bin/bash
#author: https://github.com/elmerfdz
ver=2.0.1

#VARS
inscope_containers=("$@")
force=0

rebuild_man()
{
if [ "$force" == "0" ]
then
    inscope_containers_purify=()
    for value in "${inscope_containers[@]}"
    do
        [[ $value != "-b" ]] && inscope_containers_purify+=($value)
    done
    inscope_containers=("${inscope_containers_purify[@]}")
    unset inscope_containers_purify
    
    for ((a=0; a < "${#inscope_containers[@]}"; a++))
    do
        inscope_cont_tmpl+=($(find $docker_tmpl_loc -type f -iname "*-${inscope_containers[$a]}.xml"))
        echo
        echo "--Build ${inscope_containers[$a]}"
        echo
        $rundockertemplate_script -v ${inscope_cont_tmpl[$a]}
        echo
    done
elif [ "$force" == "1" ]
then
        inscope_containers_purify=()
        for value in "${inscope_containers[@]}"
        do
            [[ $value != "-f" ]] && inscope_containers_purify+=($value)
        done
        inscope_containers=("${inscope_containers_purify[@]}")
        unset inscope_containers_purify
    for ((a=0; a < "${#inscope_containers[@]}"; a++))
    do
        inscope_cont_tmpl+=($(find $docker_tmpl_loc -type f -iname "*-${inscope_containers[$a]}.xml"))
        build_stage_var=('Stopping' 'Removing' 'Recreating')
        echo
        echo "--Build ${inscope_containers[$a]}"
        echo
         for ((d=0; d < "${#build_stage_var[@]}"; d++))
            do
                buildcont_cmd="$rundockertemplate_script -v ${inscope_cont_tmpl[$a]}"
                build_stage_cmd_var=("docker stop ${inscope_containers[$a]}" "docker rm ${inscope_containers[$a]}" "$buildcont_cmd")
                build_stage=${build_stage_var[$d]}
                build_stage_cmd=${build_stage_cmd_var[$d]}
            echo
            echo "----------------------------"
            echo "  $build_stage $contname   "
            echo "----------------------------"
            echo
            $build_stage_cmd
            echo
            done
    done
fi
}
echo
echo "-------------------------------"
echo " Rebuild-DNDC-Manual v$ver     "
echo "-------------------------------"
echo
if [[ ! ${inscope_containers[0]} =~ ^(-b|-f)$ ]]
then
    echo "Usage:"
    echo
    echo "-b : Attempts a container rebuild only, if that container already exists, rebuild will be skipped"
    echo "-f : Stop/remove and rebuild containers if it exists or not"
    echo
    echo "Examples:"
    echo
    echo "rebuildm -b container01 container02 container03"
    echo "rebuildm -f container01 container02 container03"
    echo
    exit 0
fi

while getopts f:b: opt; do
    case $opt in
	f)
	    force=1
        rebuild_man
	    ;;
	b)
	    force=0
        rebuild_man
	    ;;
    esac
done



