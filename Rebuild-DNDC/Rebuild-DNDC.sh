#!/bin/bash
#Rebuild-DNDC
#author: https://github.com/elmerfdz
ver=3.8.9-u

#NON-CONFIGURABLE VARS
contname=''
templatename=''
datetime=$(date)
buildcont_cmd="$rundockertemplate_script -v $docker_tmpl_loc/my-$templatename.xml"
mastercontid=$(docker inspect --format="{{.Id}}" $mastercontname)
getmastercontendpointid=$(docker inspect $mastercontname --format="{{ .NetworkSettings.EndpointID }}")
get_container_names=($(docker ps -a --format="{{ .Names }}"))
get_container_ids=($(docker ps -a --format="{{ .ID }}"))



#NOTIFICATIONS
recreatecont_notify_complete()
{
    echo "REBUILDING - Completed!: ${recreatecont_notify_complete_msg[*]}"
    if [ "$unraid_notifications" == "yes" ]
    then    
        /usr/local/emhttp/webGui/scripts/notify -i "normal"  -s "Rebuild-DNDC"  -d "- REBUILD: ${recreatecont_notify_complete_msg[*]} Completed "
    fi
    if [ "$discord_notifications" == "yes" ]
    then        
        ./discord-notify.sh --webhook-url=$discord_url --username "$discord_username" --avatar "$rdndc_logo" --title "REBUILD - Completed!" --description "- ${recreatecont_notify_complete_msg[*]}" --color "0x66ff33" --author-icon "$rdndc_logo" --footer "v$ver" --footer-icon "$rdndc_logo"  &> /dev/null
    fi
}

recreatecont_notify()
{
    if [ "$getmastercontendpointid" != "$currentendpointid" ]
    then
        echo "- REBUILDING: $mastercontname container EndpointID doesn't match"
        if [ "$unraid_notifications" == "yes" ]
        then              
            /usr/local/emhttp/webGui/scripts/notify -i "warning" -s "Rebuild-DNDC"  -d "- REBUILDING: $mastercontname container EndpointID doesn't match" 
        fi
        if [ "$discord_notifications" == "yes" ]
        then          
            ./discord-notify.sh --webhook-url=$discord_url --username "$discord_username" --avatar "$rdndc_logo" --title "REBUILD - In Progress..." --description "- $mastercontname container EndpointID doesn't match!" --color "0xb30000" --author-icon "$rdndc_logo" --footer "v$ver" --footer-icon "$rdndc_logo"  &> /dev/null
        fi
    elif [ "$contnetmode" != "$mastercontid" ]
    then
        echo "- REBUILDING: ${recreatecont_notify_complete_msg[*]} "
        if [ "$unraid_notifications" == "yes" ]
        then           
            /usr/local/emhttp/webGui/scripts/notify -i "warning"  -s "Rebuild-DNDC"  -d "- REBUILDING: ${recreatecont_notify_complete_msg[*]} "
        fi
        if [ "$discord_notifications" == "yes" ]
        then            
            ./discord-notify.sh --webhook-url=$discord_url --username "$discord_username" --avatar "$rdndc_logo" --title "REBUILD - In Progress..." --description "- ${recreatecont_notify_complete_msg[*]}" --color "0xe68a00" --author-icon "$rdndc_logo" --footer "v$ver" --footer-icon "$rdndc_logo"  &> /dev/null
        fi
    fi 
}

#MAIN CODE
first_run()
{
    if [ ! -d "$mastercontepfile_loc" ] || [ ! -e "$mastercontepfile_loc/mastercontepid.tmp" ] || [ ! -e "$mastercontepfile_loc/allmastercontid.tmp" ] || [ ! -e "$mastercontepfile_loc/list_inscope_cont_ids.tmp" ] || [ ! -e "$mastercontepfile_loc/list_inscope_cont_tmpl.tmp" ] || [ ! -e "$mastercontepfile_loc/list_inscope_cont_names.tmp" ]  
    then
        mkdir -p "$mastercontepfile_loc" && touch "$mastercontepfile_loc/mastercontepid.tmp" && touch "$mastercontepfile_loc/list_inscope_cont_ids.tmp" && touch "$mastercontepfile_loc/list_inscope_cont_tmpl.tmp" && touch "$mastercontepfile_loc/list_inscope_cont_names.tmp"
        echo "$getmastercontendpointid" > $mastercontepfile_loc/mastercontepid.tmp
        echo "$mastercontid" > $mastercontepfile_loc/allmastercontid.tmp
        echo "A. FIRST-RUN: SETUP COMPLETE"
        if [ "$unraid_notifications" == "yes" ]
        then              
            /usr/local/emhttp/webGui/scripts/notify -i "normal"  -s "Rebuild-DNDC"  -d "- FIRST-RUN: Setup Complete "
        fi
        if [ "$discord_notifications" == "yes" ]
        then        
            ./discord-notify.sh --webhook-url=$discord_url --username "$discord_username" --avatar "$rdndc_logo" --title "FIRST-RUN" --description "- Setup Complete" --color "0x66ff33" --author-icon "$rdndc_logo" --footer "v$ver" --footer-icon "$rdndc_logo"  &> /dev/null
        fi
        was_run=1
    elif [ -d "$mastercontepfile_loc" ] && [ -e "$mastercontepfile_loc/mastercontepid.tmp" ] 
    then
        echo "A. SKIPPING: FIRST RUN SETUP" 
        was_run=0
        getmastercontendpointid=$(docker inspect $mastercontname --format="{{ .NetworkSettings.EndpointID }}")
        currentendpointid=$(<$mastercontepfile_loc/mastercontepid.tmp)      
    fi
}

check_masterendpointid()
{
    if [ "$getmastercontendpointid" == "$currentendpointid" ]
    then
        echo "B. SKIPPING: MASTER CONTAINER ENDPOINTID IS CURRENT"     
        inscope_container_vars
    elif [ "$getmastercontendpointid" != "$currentendpointid" ]
    then
        echo "B. ALERT: MASTER container ENDPOINTID DOESN'T MATCH"
        recreatecont_notify
        echo
        inscope_container_vars        
    fi 
}

inscope_container_vars()
{
    echo "C. DETECTING: IN-SCOPE CONTAINERS"
    echo     
    #Cycle & fetch container info
    for ((a=0; a < "${#get_container_names[@]}"; a++)) 
    do
        pull_contnet_ids=($(docker inspect ${get_container_names[$a]} --format="{{ .HostConfig.NetworkMode }}" | sed -e 's/container://g'))
        pull_allmastercont_ids=($(<$mastercontepfile_loc/allmastercontid.tmp))
        while true
        do
            for ((u=0; u < "${#pull_allmastercont_ids[@]}"; u++)) 
            do  
                if [ "$pull_contnet_ids" == "${pull_allmastercont_ids[$u]}" ]
                then
                    list_inscope_cont_tmpl+=($(find $docker_tmpl_loc -type f -iname "*-${get_container_names[$a]}.xml"))
                    list_inscope_cont_ids+=(${get_container_ids[$a]})
                    list_inscope_contnames+=(${get_container_names[$a]})     
                    no=${#list_inscope_contnames[@]}
                    echo "$no ${get_container_names[$a]}"
                    echo "- ContainerID ${get_container_ids[$a]}"       
                    echo "- NetworkID: $pull_contnet_ids"              
                    echo "- Template Location: ${list_inscope_cont_tmpl[$b]}"; b=$((b + 1))       
                    echo   
                fi 
            done    
            break
        done    
    done
   
    if [ "${list_inscope_contnames}" == '' ]
    then
        echo "# RESULTS: None in-scope, checking for previous in-scope containers"
        echo
        list_inscope_cont_ids=($(<$mastercontepfile_loc/list_inscope_cont_ids.tmp))
        list_inscope_contnames=($(<$mastercontepfile_loc/list_inscope_cont_names.tmp))
        list_inscope_cont_tmpl=($(<$mastercontepfile_loc/list_inscope_cont_tmpl.tmp))
        if [ "${list_inscope_contnames}" == '' ]
        then
            echo "- No containers in scope."
            echo "- Make sure you have the containers routed through the MASTER container are running fine first."
        fi            
    fi    
    #post process inscope containers
    inscope_container_vars_post
 
}

inscope_container_vars_post(){
    echo "${list_inscope_cont_ids[@]}" > $mastercontepfile_loc/list_inscope_cont_ids.tmp;    
    echo "${list_inscope_contnames[@]}" > $mastercontepfile_loc/list_inscope_cont_names.tmp;    
    echo "${list_inscope_cont_tmpl[@]}" > $mastercontepfile_loc/list_inscope_cont_tmpl.tmp;
    if [ "${list_inscope_contnames}" != '' ]
    then
        echo "D. PROCESSING: IN-SCOPE CONTAINERS"
    fi
    echo           
        for ((c=0; c < "${#list_inscope_contnames[@]}"; c++)) 
        do  
        contname=${list_inscope_contnames[$c]}
        CONT_ID=${list_inscope_cont_ids[$c]}              
        CONT_TMPL=${list_inscope_cont_tmpl[$c]}            
        check_networkmodeid
    done
}

check_networkmodeid()
{
    contnetmode=$(docker inspect $contname --format="{{ .HostConfig.NetworkMode }}" | sed -e 's/container://g')
    if [ "$getmastercontendpointid" != "$currentendpointid" ]
    then
        rebuild_mod
        recreatecont_notify_complete_msg+=(${contname[@]})
    elif [ "$contnetmode" == "$mastercontid" ]
    then
        echo "- SKIPPING: $contname NETID = MASTER NETID"
    elif [ "$contnetmode" != "$mastercontid" ]
    then
        echo
        echo "- $contname NetModeID doesn't match with $mastercontname ContID"
        rebuild_mod
    fi
}

rebuild_mod()
{
    buildcont_cmd="$rundockertemplate_script -v $CONT_TMPL"    
    build_stage_var=('Stopping' 'Removing' 'Recreating')
    build_stage_cmd_var=("docker stop $contname" "docker rm $contname" "$buildcont_cmd")

    if [ "$getmastercontendpointid" != "$currentendpointid" ] || [ "$mastercontid" != "$contnetmode" ]
    then
        #Cycle through build commands
            for ((d=0; d < "${#build_stage_var[@]}"; d++)) 
            do
                build_stage=${build_stage_var[$d]}
                build_stage_cmd=${build_stage_cmd_var[$d]}
            echo
            echo "----------------------------"
            echo "  $build_stage $contname   "
            echo "----------------------------"
            echo
            $build_stage_cmd
            done
        was_rebuild=1  
    fi
    
    if [ "$was_run" == 0 ]
    then 
        echo "$getmastercontendpointid" > $mastercontepfile_loc/mastercontepid.tmp
    fi
}

app_pf()
{
    echo
    echo "E. PORT-FORWARD: Supported Apps"
    echo
    if [ "$rutorrent_pf" == "yes" ] 
    then
        echo "----------------------------"
        echo "  ruTorrent PF              "
        echo "----------------------------"         
        vpn_pf=$(docker exec $mastercontname /bin/sh -c "cat /forwarded_port")
        if [ "$vpn_pf" == "0" ] 
        then  
            mastercontconnectivity_mod
            startapp_mod
        fi      
        rutorrent_rc_loc=($(find $pf_loc/rutorrent/ -type f -iname "*rtorrent.rc"))
        rutorrent_pf_status=$(grep -q "port_range = $vpn_pf-$vpn_pf" "$rutorrent_rc_loc" ; echo $?)
        get_vpn_wan_ip=$(docker exec $mastercontname /bin/sh -c  "wget --timeout=30 http://ipinfo.io/ip -qO -")
        if [ "$rutorrent_pf_status" == "1" ] 
        then
            sed -i "s/^port_range.*/port_range = $vpn_pf-$vpn_pf/" $rutorrent_rc_loc
            sed -i "s/^network.port_range.set.*/network.port_range.set = $vpn_pf-$vpn_pf/" $rutorrent_rc_loc
            sed -i "s/^ip.*/ip = $get_vpn_wan_ip/" $rutorrent_rc_loc
            echo "- PORT-FORWARD: Replaced $rutorrent_cont_name container port-range with $vpn_pf"
            echo "- BREAK: Quick 5sec nap before restarting $rutorrent_cont_name"
            sleep 5
            docker restart $rutorrent_cont_name  &> /dev/null
            echo "- RESTARTED: $rutorrent_cont_name"
            if [ "$discord_notifications" == "yes" ]
            then        
                ./discord-notify.sh --webhook-url=$discord_url --username "$discord_username" --avatar "$rdndc_logo" --title "ruTorrent Port Forward" --description "- Port-Forward: Replaced $rutorrent_cont_name container port-range with $vpn_pf\n- Restarted $rutorrent_cont_name " --color "0x66ff33" --author-icon "$rdndc_logo" --footer "v$ver" --footer-icon "$rdndc_logo"  &> /dev/null
            fi
        elif [ "$rutorrent_pf_status" == "0" ]
        then
            echo "- PORT-FORWARD STATUS: $rutorrent_cont_name pf port set is current, using: $vpn_pf "                 
        fi
    fi
}

mastercontconnectivity_mod()
{
#Check if MASTER container network has connectivity
if [ "$mastercontconcheck" == "yes" ]
then
    docker exec $mastercontname ping -c $ping_count $ping_ip &> /dev/null
    if [ "$?" == 0 ]
    then
        echo "- CONNECTIVITY: OK"
    else
        docker exec $mastercontname ping -c $ping_count $ping_ip_alt &> /dev/null
        if [ "$?" == 0 ]
        then
            echo "- CONNECTIVITY: OK"
        else
            echo "- CONNECTIVITY: BROKEN"
            echo "---- restarting $mastercontname" container
            docker restart $mastercontname &> /dev/null
            echo "---- $mastercontname restarted"
            echo "---- going to sleep for $sleep_secs seconds"
            sleep $sleep_secs    
        fi    
    fi
fi
}

#Keep track of current & past master cotnainer IDs
masteridpool_mod()
{
if ! grep -Fxq "$mastercontid" $mastercontepfile_loc/allmastercontid.tmp
then
    echo "$mastercontid" >> $mastercontepfile_loc/allmastercontid.tmp
    tail -n $save_no_masterids $mastercontepfile_loc/allmastercontid.tmp > $mastercontepfile_loc/allmastercontid.tmp1 && mv $mastercontepfile_loc/allmastercontid.tmp1 $mastercontepfile_loc/allmastercontid.tmp
fi
}

startapp_mod()
{
echo
echo "---------------------------------"
echo "    Rebuild-DNDC v$ver     "
echo "---------------------------------"
echo

echo "-----------------------------------------------------------------------------------"
echo "# MASTER CONTAINER INFO"
echo "- CONTAINER-NAME: $mastercontname"
echo "- ENDPOINT-ID: $getmastercontendpointid"
echo "- NETWORKMODE-ID: $mastercontid"
mastercontconnectivity_mod
echo "-----------------------------------------------------------------------------------"
echo 

#check first run
first_run

#Check MASTER container Endpoint node, immediately rebuild if doesn't match
check_masterendpointid

#Check app port forwarding requirement
if [ "$rutorrent_pf" == "yes" ]
then
    app_pf
fi

echo
if [ "$was_rebuild" == 1 ]
then 
    recreatecont_notify_complete
    if [ "$was_run" == 0 ]
    then 
        masteridpool_mod
    fi
fi
echo 
echo "------------------------------------------"
echo " Run Completed: $datetime  "
echo "------------------------------------------"
echo
}

#Start app
startapp_mod