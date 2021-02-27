#!/bin/bash
#Rebuild-DNDC
#author: https://github.com/elmerfdz
ver=4.0.7-u
#Run only one instance of script
SCRIPTNAME=`basename $0`
PIDFILE=/var/run/${SCRIPTNAME}.pid
if [ -f "$PIDFILE" ]; then
	PIDlife=$(find "$PIDFILE" -type f -mmin +5 | grep . > /dev/null 2>&1 ; echo $?)
	if [ "${PIDlife}" == '0' ]
	then
		echo
		echo "Healing..."
    		rm -rf $PIDFILE
	else
		echo
		echo "App healthy..."
	fi
fi
if [ -f ${PIDFILE} ]; then
   #verify if the process is actually still running under this pid
   OLDPID=`cat ${PIDFILE}`
   RESULT=`ps -ef | grep ${OLDPID} | grep ${SCRIPTNAME}`
   if [ -n "${RESULT}" ]; then
     echo
     echo "Script already running! Try again later."
     echo
     exit 255
   fi
fi
#grab pid of this process and update the pid file with it
PID=`ps -ef | grep ${SCRIPTNAME} | head -n1 |  awk ' {print $2;} '`
echo ${PID} > ${PIDFILE}
#NON-CONFIGURABLE VARS
contname=''
templatename=''
datetime=$(date)
buildcont_cmd="$rundockertemplate_script -v $docker_tmpl_loc/my-$templatename.xml"
mastercontid=$(docker inspect --format="{{.Id}}" $mastercontname)
getmastercontendpointid=$(docker inspect $mastercontname --format="{{ .NetworkSettings.EndpointID }}")
get_container_names=($(docker ps -a --format="{{ .Names }}"))
get_container_ids=($(docker ps -a --format="{{ .ID }}"))
save_no_mcontids=${save_no_mcontids:-20}



#NOTIFICATIONS - Recreate Complete
recreatecont_notify_complete()
{
    printf "F. REBUILD: STATUS\n "      
    printf " - Completed: ${recreatecont_notify_complete_msg[*]}\n"
    if [ "$unraid_notifications" == "yes" ]
    then    
        /usr/local/emhttp/webGui/scripts/notify -i "normal"  -s "Rebuild-DNDC"  -d "- REBUILD: ${recreatecont_notify_complete_msg[*]} Completed "
    fi
    if [ "$discord_notifications" == "yes" ]
    then        
        ./discord-notify.sh --webhook-url=$discord_url --username "$discord_username" --avatar "$rdndc_logo" --title "REBUILD - Completed!" --description "- ${recreatecont_notify_complete_msg[*]}" --color "0x66ff33" --author-icon "$rdndc_logo" --footer "v$ver" --footer-icon "$rdndc_logo"  &> /dev/null
    fi
    if [ "$gotify_notifications" == "yes" ]
    then        
        curl -X POST "$gotify_url" -F "title=Rebuild-dndc" -F "message=REBUILD - Completed! 
        - ${recreatecont_notify_complete_msg[*]}" -F "priority=5" &> /dev/null
    fi    
}

#NOTIFICATIONS - Recreate Notify
recreatecont_notify()
{
    if [ "$getmastercontendpointid" != "$currentendpointid" ]
    then 
        printf "  - REBUILDING: $mastercontname container ENDPOINTID DOESN'T MATCH\n"
        if [ "$unraid_notifications" == "yes" ]
        then              
            /usr/local/emhttp/webGui/scripts/notify -i "warning" -s "Rebuild-DNDC"  -d "- REBUILDING: $mastercontname container EndpointID doesn't match" 
        fi
        if [ "$discord_notifications" == "yes" ]
        then          
            ./discord-notify.sh --webhook-url=$discord_url --username "$discord_username" --avatar "$rdndc_logo" --title "REBUILD - In Progress..." --description "- $mastercontname container EndpointID doesn't match!" --color "0xb30000" --author-icon "$rdndc_logo" --footer "v$ver" --footer-icon "$rdndc_logo"  &> /dev/null
        fi
        if [ "$gotify_notifications" == "yes" ]
        then          
            curl -X POST "$gotify_url" -F "title=Rebuild-dndc" -F "message=REBUILD - In Progress...
            - $mastercontname container EndpointID doesn't match!" -F "priority=5" &> /dev/null
        fi        
    elif [ "$contnetmode" != "$mastercontid" ]
    then
        printf "  - REBUILDING: ${recreatecont_notify_complete_msg[*]}\n"
        if [ "$unraid_notifications" == "yes" ]
        then           
            /usr/local/emhttp/webGui/scripts/notify -i "warning"  -s "Rebuild-DNDC"  -d "- REBUILDING: ${recreatecont_notify_complete_msg[*]} "
        fi
        if [ "$discord_notifications" == "yes" ]
        then            
            ./discord-notify.sh --webhook-url=$discord_url --username "$discord_username" --avatar "$rdndc_logo" --title "REBUILD - In Progress..." --description "- ${recreatecont_notify_complete_msg[*]}" --color "0xe68a00" --author-icon "$rdndc_logo" --footer "v$ver" --footer-icon "$rdndc_logo"  &> /dev/null
        fi
        if [ "$gotify_notifications" == "yes" ]
        then          
            curl -X POST "$gotify_url" -F "title=Rebuild-dndc" -F "message=REBUILD - In Progress...
            - ${recreatecont_notify_complete_msg[*]}" -F "priority=5" &> /dev/null
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
        printf "A. FIRST-RUN: SETUP COMPLETE\n"
        if [ "$unraid_notifications" == "yes" ]
        then              
            /usr/local/emhttp/webGui/scripts/notify -i "normal"  -s "Rebuild-DNDC"  -d "- FIRST-RUN: Setup Complete "
        fi
        if [ "$discord_notifications" == "yes" ]
        then        
            ./discord-notify.sh --webhook-url=$discord_url --username "$discord_username" --avatar "$rdndc_logo" --title "FIRST-RUN" --description "- Setup Complete" --color "0x66ff33" --author-icon "$rdndc_logo" --footer "v$ver" --footer-icon "$rdndc_logo"  &> /dev/null
        fi
        if [ "$gotify_notifications" == "yes" ]
        then        
            curl -X POST "$gotify_url" -F "title=Rebuild-dndc" -F "message=FIRST-RUN
            - Setup Complete" -F "priority=5" &> /dev/null
        fi        
        was_run=1
    elif [ -d "$mastercontepfile_loc" ] && [ -e "$mastercontepfile_loc/mastercontepid.tmp" ] 
    then
        printf "A. SKIPPING: FIRST RUN SETUP\n" 
        was_run=0
        getmastercontendpointid=$(docker inspect $mastercontname --format="{{ .NetworkSettings.EndpointID }}")
        currentendpointid=$(<$mastercontepfile_loc/mastercontepid.tmp)      
    fi
}

#Check Master Container Endpoint ID
check_masterendpointid()
{
    if [ "$getmastercontendpointid" == "$currentendpointid" ]
    then
        printf "B. SKIPPING: MASTER CONTAINER ENDPOINTID IS CURRENT\n"     
        inscope_container_vars
    elif [ "$getmastercontendpointid" != "$currentendpointid" ]
    then
        printf "B. ALERT: MASTER container ENDPOINTID DOESN'T MATCH\n"
        recreatecont_notify
        echo
        inscope_container_vars        
    fi 
}

#Detecting In-scope Containers For Rebuild - Main 
inscope_container_vars()
{
    printf "C. DETECTING: IN-SCOPE CONTAINERS\n"
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
                    printf " $no.${get_container_names[$a]}\n"
                    printf "  - ContainerID ${get_container_ids[$a]}\n"       
                    printf "  - NetworkID: $pull_contnet_ids\n"              
                    printf "  - Template Location: ${list_inscope_cont_tmpl[$b]}\n" 
                    b=$((b + 1))   
                    echo   
                fi 
            done    
            break
        done    
    done

    #Pulling Previously Detected In-scope Containers - Fallback Option
    if [ "${list_inscope_contnames}" == '' ]
    then
        printf "# RESULTS: None in-scope, checking for previous in-scope containers\n"
        echo
        list_inscope_cont_ids=($(<$mastercontepfile_loc/list_inscope_cont_ids.tmp))
        list_inscope_contnames=($(<$mastercontepfile_loc/list_inscope_cont_names.tmp))
        list_inscope_cont_tmpl=($(<$mastercontepfile_loc/list_inscope_cont_tmpl.tmp))
        if [ "${list_inscope_contnames}" == '' ]
        then
            printf " - No containers in scope.\n"
            printf " - Make sure you have the containers routed through the MASTER container are running fine first.\n"
        fi            
    fi    
    #post process inscope containers
    inscope_container_vars_post 
}

#Saving Detected In-scope Containers - For Fallback Option
inscope_container_vars_post(){
    echo "${list_inscope_cont_ids[@]}" > $mastercontepfile_loc/list_inscope_cont_ids.tmp;    
    echo "${list_inscope_contnames[@]}" > $mastercontepfile_loc/list_inscope_cont_names.tmp;    
    echo "${list_inscope_cont_tmpl[@]}" > $mastercontepfile_loc/list_inscope_cont_tmpl.tmp;
    if [ "${list_inscope_contnames}" != '' ]
    then
        printf "D. PROCESSING: IN-SCOPE CONTAINERS\n"
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

#Check Master Container Network & Endpoint IDs
check_networkmodeid()
{
    contnetmode=$(docker inspect $contname --format="{{ .HostConfig.NetworkMode }}" | sed -e 's/container://g')
    if [ "$getmastercontendpointid" != "$currentendpointid" ]
    then
        rebuild_mod
        recreatecont_notify_complete_msg+=(${contname[@]})
    elif [ "$contnetmode" == "$mastercontid" ]
    then
        printf " - SKIPPING: $contname NETID = MASTER NETID\n"
    elif [ "$contnetmode" != "$mastercontid" ]
    then
        echo
        printf " - $contname NetModeID doesn't match with $mastercontname ContID\n"
        rebuild_mod
        recreatecont_notify_complete_msg+=(${contname[@]})
    fi
}

#Rebuild In-scope Containers
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
            echo '----------------------------'
            printf "  $build_stage: $contname\n "
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

#Port Forwarding For Supported Apps
get_pf_mod()
{
    check_pff_exists=$(docker exec $mastercontname /bin/sh -c "[[ -f /forwarded_port ]]" ; echo $?)
    if [ "$check_pff_exists" == "0" ]
    then
        check_pf_num_exists=$(docker exec $mastercontname /bin/sh -c "cat /forwarded_port" ; echo $?)
        if [ "$check_pff_exists" == "0" ]
        then
           vpn_pf=$(docker exec $mastercontname /bin/sh -c "cat /forwarded_port")
        else
            echo "- Port Foward file is empty "
            vpn_pf=0
        fi
    elif [ "$check_pff_exists" == "1" ]
    then
         echo "- Port file doesn't exist, will attempt to restart $mastercontname container"
         vpn_pf=0
    fi
}
get_vpnwanip_mod()
{
    check_vpnwanipf_exists=$(docker exec $mastercontname /bin/sh -c "[[ -f /tmp/gluetun/ip ]]" ; echo $?)
    if [ "$check_vpnwanipf_exists" == "0" ]
    then
        check_pf_num_exists=$(docker exec $mastercontname /bin/sh -c "cat /tmp/gluetun/ip" ; echo $?)
        if [ "$check_vpnwanipf_exists" == "0" ]
        then
            while true
            do
                vpn_wanip_chk1=$(docker exec $mastercontname /bin/sh -c  "curl -s https://ipv4.icanhazip.com")
                vpn_wanip_chk2=$(docker exec $mastercontname /bin/sh -c  "curl -s https://ipecho.net/plain")
                if [ "$vpn_wanip_chk1" == "$vpn_wanip_chk2" ]
                then
                    vpn_wanip=$vpn_wanip_chk1
                    break
                fi
           done
        else
            echo "- WAN IP file is empty "
            vpn_wanip=0
        fi
    elif [ "$check_vpnwanipf_exists" == "1" ]
    then
         echo "- WAN IP file doesn't exist, will attempt to restart $mastercontname container"
         vpn_wanip=0
    fi
}

app_pf()
{
    echo
    printf "E. PORT-FORWARD: Supported Apps\n"
    echo
    if [ "$rutorrent_pf" == "yes" ] 
    then
        printf ' ruTorrent\n'         
        get_pf_mod
        get_vpnwanip_mod
        while [ "$vpn_pf" == "0" ] || [ "$vpn_wanip" == "0" ]
        do 
            printf " - Looks like $mastercontname container has failed to port forward, attempting to fix.\n"
            if [ "$discord_notifications" == "yes" ]
            then
                ./discord-notify.sh --webhook-url=$discord_url --username "$discord_username" --avatar "$rdndc_logo" --title "Attempting To Fix Port Forwarding" --description "- Looks like the $mastercontname container was unable to port foward, attempting to fix.\n- Restarting $mastercontname container" --color "0xb30000" --author-icon "$rdndc_logo" --footer "v$ver" --footer-icon "$rdndc_logo"  &> /dev/null
            fi
            if [ "$gotify_notifications" == "yes" ]
            then        
                curl -X POST "$gotify_url" -F "title=Rebuild-dndc" -F "message=Attempting To Fix Port Forwarding
                - Looks like the $mastercontname container was unable to port foward, attempting to fix
                - Restarting $mastercontname container" -F "priority=5" &> /dev/null
            fi                
            unset list_inscope_cont_ids
            unset list_inscope_contnames
            unset list_inscope_cont_tmpl
            unset recreatecont_notify_complete_msg
            docker restart $mastercontname  &> /dev/null
            printf " - BREAK: Quick 20sec nap before checking the $mastercontname container for WAN connectivity\n"            
            sleep 20  
            mastercontconnectivity_mod
            get_pf_mod
            if [ "$vpn_pf" != "0" ] 
            then
                if [ "$discord_notifications" == "yes" ]
                then 
                    ./discord-notify.sh --webhook-url=$discord_url --username "$discord_username" --avatar "$rdndc_logo" --title "Port Forwarding Fixed" --description "- Looks like $mastercontname container has succeeded in port forwarding.\n- Forwarded Port: $vpn_pf" --color "0x66ff33" --author-icon "$rdndc_logo" --footer "v$ver" --footer-icon "$rdndc_logo"  &> /dev/null
                fi
                if [ "$gotify_notifications" == "yes" ]
                then        
                    curl -X POST "$gotify_url" -F "title=Rebuild-dndc" -F "message=Port Forwarding Fixed
                    - Looks like $mastercontname container has succeeded in port forwarding
                    - Forwarded Port: $vpn_pf" -F "priority=5" &> /dev/null
                fi                    
                startapp_mod
                break
            fi    
        done     
        rutorrent_rc_loc=$(find $pf_loc/rutorrent/ -type f -iname "*rtorrent.rc")
        rutorrent_pf_status=$(grep -w "port_range = $vpn_pf-$vpn_pf" "$rutorrent_rc_loc" ; echo $?)
        rutorrent_ip_status=$(grep -w "ip = $vpn_wanip" "$rutorrent_rc_loc" ; echo $?)        
        if [ "$rutorrent_pf_status" == "1" ] || [ "$rutorrent_ip_status" == "1" ]
        then
            if [ "$rutorrent_pf_status" == "1" ]
            then
                sed -i "s/^port_range.*/port_range = $vpn_pf-$vpn_pf/" $rutorrent_rc_loc
                sed -i "s/^network.port_range.set.*/network.port_range.set = $vpn_pf-$vpn_pf/" $rutorrent_rc_loc
                printf " - PORT-FORWARD: Replaced rTorrent Bittorrent port-range with $vpn_pf\n"
            fi 
            if [ "$rutorrent_ip_status" == "1" ]
            then               
                sed -i "s/^ip.*/ip = $vpn_wanip/" $rutorrent_rc_loc
                printf " - REPORTED WAN IP: Replaced IP with $vpn_wanip\n"
            fi
            printf " - BREAK: Quick 5sec nap before restarting $rutorrent_cont_name\n"
            sleep 5
            docker restart $rutorrent_cont_name  &> /dev/null
            printf " - RESTARTED: $rutorrent_cont_name\n"
            if [ "$discord_notifications" == "yes" ]
            then
                if [ "$rutorrent_pf_status" == "1" ] && [ "$rutorrent_ip_status" == "1" ]
                then
                    ./discord-notify.sh --webhook-url=$discord_url --username "$discord_username" --avatar "$rdndc_logo" --title "ruTorrent Enhancements" --description "- Port-Forward: Replaced Bittorrent port-range with $vpn_pf\n- Reported WAN IP: Replaced WAN IP with $vpn_wanip\n- Restarted $rutorrent_cont_name " --color "0x66ff33" --author-icon "$rdndc_logo" --footer "v$ver" --footer-icon "$rdndc_logo"  &> /dev/null
                elif [ "$rutorrent_ip_status" == "1" ]
                then
                    ./discord-notify.sh --webhook-url=$discord_url --username "$discord_username" --avatar "$rdndc_logo" --title "ruTorrent Enhancements" --description "- Reported WAN IP: Replaced with $vpn_wanip\n- Restarted $rutorrent_cont_name " --color "0x66ff33" --author-icon "$rdndc_logo" --footer "v$ver" --footer-icon "$rdndc_logo"  &> /dev/null
                elif [ "$rutorrent_pf_status" == "1" ]
                then
                    ./discord-notify.sh --webhook-url=$discord_url --username "$discord_username" --avatar "$rdndc_logo" --title "ruTorrent Enhancements" --description "- Port-Forward: Replaced $rutorrent_cont_name container port-range with $vpn_pf\n- Restarted $rutorrent_cont_name " --color "0x66ff33" --author-icon "$rdndc_logo" --footer "v$ver" --footer-icon "$rdndc_logo"  &> /dev/null
                fi                     
            fi
            if [ "$gotify_notifications" == "yes" ]
            then
                if [ "$rutorrent_pf_status" == "1" ] && [ "$rutorrent_ip_status" == "1" ]
                then
                    curl -X POST "$gotify_url" -F "title=Rebuild-dndc" -F "message=ruTorrent Enhancements 
                    - Port-Forward: Replaced Bittorrent port-range with $vpn_pf
                    - Reported WAN IP: Replaced WAN IP with $vpn_wanip
                    - Restarted $rutorrent_cont_name" -F "priority=5" &> /dev/null
                elif [ "$rutorrent_ip_status" == "1" ]
                then
                    curl -X POST "$gotify_url" -F "title=Rebuild-dndc" -F "message=ruTorrent Enhancements 
                    - Reported WAN IP: Replaced with $vpn_wanip
                    - Restarted $rutorrent_cont_name" -F "priority=5" &> /dev/null
                elif [ "$rutorrent_pf_status" == "1" ]
                then
                    curl -X POST "$gotify_url" -F "title=Rebuild-dndc" -F "message=ruTorrent Enhancements 
                    - Port-Forward: Replaced $rutorrent_cont_name container port-range with $vpn_pf
                    - Restarted $rutorrent_cont_name" -F "priority=5" &> /dev/null
                fi                     
            fi            
            
        elif [ "$rutorrent_pf_status" != "1" ] || [ "$rutorrent_ip_status" != "1" ]
        then
            printf " - PORT-FORWARD STATUS: Current ($vpn_pf)\n"
            printf " - REPORTED WAN IP STATUS: Current ($vpn_wanip)\n"            
            printf " - SKIPPING\n"                 
        fi
    fi
}


#Check Master Container WAN connectivity
mastercontconnectivity_mod()
{
if [ "$mastercontconcheck" == "yes" ]
then
    docker exec $mastercontname ping -c $ping_count $ping_ip &> /dev/null
    if [ "$?" == 0 ]
    then
       printf " - CONNECTIVITY: OK\n"
    else
        docker exec $mastercontname ping -c $ping_count $ping_ip_alt &> /dev/null
        if [ "$?" == 0 ]
        then
            printf " - CONNECTIVITY: OK\n"
        else
            printf " - CONNECTIVITY: BROKEN\n"
            printf " ---- restarting $mastercontname container\n"
            docker restart $mastercontname &> /dev/null
            printf " ---- $mastercontname restarted\n"
            printf " ---- going to sleep for $sleep_secs seconds\n"
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
    tail -n $save_no_mcontids $mastercontepfile_loc/allmastercontid.tmp > $mastercontepfile_loc/allmastercontid.tmp1 && mv $mastercontepfile_loc/allmastercontid.tmp1 $mastercontepfile_loc/allmastercontid.tmp
fi
}

#App Run layout & Workflow
startapp_mod()
{
echo
echo '---------------------------------'
printf "    Rebuild-DNDC v$ver\n"
echo '---------------------------------'
echo

echo '-----------------------------------------------------------------------------------'
printf " # MASTER CONTAINER INFO\n"
printf " - CONTAINER-NAME: $mastercontname\n"
printf " - ENDPOINT-ID: $getmastercontendpointid\n"
printf " - NETMODE-ID: $mastercontid\n"
mastercontconnectivity_mod
echo '-----------------------------------------------------------------------------------'
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

}

#Rebuild Complete Notification & Store Master ContainerID to ID tracker pool
signoffapp_mod()
{
if [ "$was_rebuild" == 1 ]
then 
    echo
    recreatecont_notify_complete
    if [ "$was_run" == 0 ]
    then 
        masteridpool_mod
    fi
fi
echo 
echo '--------------------------------------------'
printf "Run Completed: $datetime  \n"
echo '--------------------------------------------'
echo
}

#Start app
startapp_mod
#Sign-off app
signoffapp_mod

#PID cleanup
if [ -f ${PIDFILE} ]; then
    rm ${PIDFILE}
fi
