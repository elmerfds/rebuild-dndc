#!/bin/bash
#RecreateVPNcontainers
#author: https://github.com/elmerfdz
ver=3.0.6.5

#VARS
VPNCONTNAME=vpn #VPN Container name, replace that with your VPN container name
CONTNAME=''
TEMPLATENAME=''
vpnepfile_loc='/tmp/user.scripts/recreatevpnconts'
RUNDOCKERTEMPLATE_SCRIPT='/tmp/user.scripts/tmpScripts/ParseDockerTemplate/script'
BUILDCONT_CMD="$RUNDOCKERTEMPLATE_SCRIPT -v /boot/config/plugins/dockerMan/templates-user/my-$TEMPLATENAME.xml"
vpncontid=$(docker inspect --format="{{.Id}}" $VPNCONTNAME)
getvpncontendpointid=$(docker inspect $VPNCONTNAME --format="{{ .NetworkSettings.EndpointID }}")
docker_tmpl_loc='/boot/config/plugins/dockerMan/templates-user'
get_container_names=($(docker ps -a --format="{{ .Names }}"))
get_container_ids=($(docker ps -a --format="{{ .ID }}"))

recreatecont_notify_complete()
{
    /usr/local/emhttp/webGui/scripts/notify -i "normal"  -s "RecreateVPNcontainers"  -d "- REBUILDING: ${recreatecont_notify_complete_msg[*]} Completed "
}

recreatecont_notify()
{
    if [ "$getvpncontendpointid" != "$currentendpointid" ]
    then
        /usr/local/emhttp/webGui/scripts/notify -i "warning" -s "RecreateVPNcontainers"  -d "- REBUILDING: $VPNCONTNAME VPN container Endpoint doesn't match" 
    elif [ "$contnetmode" != "$vpncontid" ]
    then
	    /usr/local/emhttp/webGui/scripts/notify -i "warning"  -s "RecreateVPNcontainers"  -d "- REBUILDING: ${recreatecont_notify_complete_msg[*]} "	
    fi 	
}

first_run()
{
    if [ ! -d "$vpnepfile_loc" ] || [ ! -e "$vpnepfile_loc/vpnepid.tmp" ] || [ ! -e "$vpnepfile_loc/list_inscope_cont_ids.tmp" ] || [ ! -e "$vpnepfile_loc/list_inscope_cont_tmpl.tmp" ] || [ ! -e "$vpnepfile_loc/list_inscope_cont_names.tmp" ]  
    then
        mkdir -p "$vpnepfile_loc" && touch "$vpnepfile_loc/vpnepid.tmp" && touch "$vpnepfile_loc/list_inscope_cont_ids.tmp" && touch "$vpnepfile_loc/list_inscope_cont_tmpl.tmp" && touch "$vpnepfile_loc/list_inscope_cont_names.tmp"
        echo "$getvpncontendpointid" > $vpnepfile_loc/vpnepid.tmp
        echo "A. FIRST-RUN: SETUP COMPLETE"
        /usr/local/emhttp/webGui/scripts/notify -i "normal"  -s "RecreateVPNcontainers"  -d "- FIRST-RUN: Setup Complete "
        was_run=1
    elif [ -d "$vpnepfile_loc" ] && [ -e "$vpnepfile_loc/vpnepid.tmp" ] 
    then
        echo "A. SKIPPING: FIRST RUN SETUP" 
        was_run=0
        currentendpointid=$(<$vpnepfile_loc/vpnepid.tmp)      
    fi
}

check_vpnendpointid()
{
    if [ "$getvpncontendpointid" == "$currentendpointid" ]
    then
        echo "B. SKIPPING: VPN CONTAINER ENDPOINT IS CURRENT"     
        echo
        inscope_container_vars
    elif [ "$getvpncontendpointid" != "$currentendpointid" ]
    then
        echo "B. ALERT: VPN container Endpoint doesn't match"
        echo
        #recreatecont_notify_warning
        #recreatecont_notify
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
    	if [ "$pull_contnet_ids" == "$vpncontid" ]
    	then
            list_inscope_cont_tmpl+=($(find $docker_tmpl_loc -type f -iname "*-${get_container_names[$a]}.xml"))
			list_inscope_cont_ids+=(${get_container_ids[$a]})
			list_inscope_contnames+=(${get_container_names[$a]})     
            #let no=$a+1
            no=${#list_inscope_contnames[@]}
			echo "$no. ${get_container_names[$a]}"
            echo "- ContainerID: ${get_container_ids[$a]}"       
			echo "- NetworkID: $pull_contnet_ids"              
			echo "- Template Location: ${list_inscope_cont_tmpl[$b]}"; b=$((b + 1))       		
			echo   
    	fi 		
	done
   
    if [ "${list_inscope_contnames}" == '' ]
    then
        echo "# RESULTS: None in-scope, checking for previous in-scope containers"
        echo
        list_inscope_cont_ids=($(<$vpnepfile_loc/list_inscope_cont_ids.tmp))
        list_inscope_contnames=($(<$vpnepfile_loc/list_inscope_cont_names.tmp))
        list_inscope_cont_tmpl=($(<$vpnepfile_loc/list_inscope_cont_tmpl.tmp))
        if [ "${list_inscope_contnames}" == '' ]
        then
            echo "- No containers in scope."
            echo "- Make sure you have the containers routed through the VPN are running fine first."
        fi            
     fi    
    #post process inscope containers
    inscope_container_vars_post
 
}

inscope_container_vars_post(){
    echo "${list_inscope_cont_ids[@]}" > $vpnepfile_loc/list_inscope_cont_ids.tmp;    
    echo "${list_inscope_contnames[@]}" > $vpnepfile_loc/list_inscope_cont_names.tmp;    
    echo "${list_inscope_cont_tmpl[@]}" > $vpnepfile_loc/list_inscope_cont_tmpl.tmp;
    if [ "${list_inscope_contnames}" != '' ]
    then
        echo "D. PROCESSING: IN-SCOPE CONTAINERS"
    fi
    echo           
	for ((c=0; c < "${#list_inscope_contnames[@]}"; c++)) 
	do  
        CONTNAME=${list_inscope_contnames[$c]}
        CONT_ID=${list_inscope_cont_ids[$c]}              
        CONT_TMPL=${list_inscope_cont_tmpl[$c]}            
        check_networkmodeid
    done
}

check_networkmodeid()
{
    contnetmode=$(docker inspect $CONTNAME --format="{{ .HostConfig.NetworkMode }}" | sed -e 's/container://g')
    if [ "$getvpncontendpointid" != "$currentendpointid" ]
    then
        rebuild_mod
        recreatecont_notify_complete_msg+=(${CONTNAME[@]})
        #was_rebuild=1        
        #recreatecont_notify_complete  
    elif [ "$contnetmode" == "$vpncontid" ]
    then
        echo "- SKIPPING: $CONTNAME NETID = VPN NETID"
    elif [ "$contnetmode" != "$vpncontid" ]
    then
        echo
        echo "- $CONTNAME NetModeID doesn't match with $VPNCONTNAME VPN ContID"
        #recreatecont_notify
        rebuild_mod
        #was_rebuild=1        
        #recreatecont_notify_complete
    fi
}

rebuild_mod()
{
    BUILDCONT_CMD="$RUNDOCKERTEMPLATE_SCRIPT -v $CONT_TMPL"    
    build_stage_var=('Stopping' 'Removing' 'Recreating')
    build_stage_cmd_var=("docker stop $CONTNAME" "docker rm $CONTNAME" "$BUILDCONT_CMD")

    if [ "$getvpncontendpointid" != "$currentendpointid" ] || [ "$vpncontid" != "$contnetmode" ]
    then
            #Cycle through build commands
	        for ((d=0; d < "${#build_stage_var[@]}"; d++)) 
	        do
	            build_stage=${build_stage_var[$d]}
	            build_stage_cmd=${build_stage_cmd_var[$d]}
                echo
                echo "---------------------------"
                echo "  $build_stage $CONTNAME   "
                echo "---------------------------"
                echo
                $build_stage_cmd
	        done
            was_rebuild=1  
    fi
    
    if [ "$was_run" == 0 ]
    then 
        echo "$getvpncontendpointid" > $vpnepfile_loc/vpnepid.tmp
    fi
}


echo
echo "-----------------------------------"
echo "|  Recreate VPN Containers v$ver  |"
echo "-----------------------------------"
echo

echo "----------------------------------------"
echo "# VPN CONTAINER INFO"
echo "- CONTAINER-NAME: $VPNCONTNAME"
echo "- ENDPOINT-ID: $getvpncontendpointid"
echo "- NETWORKMODE-ID: $vpncontid"
echo "----------------------------------------"
echo 

#check first run
first_run

#Check VPN Endpoint node, immediately rebuild if doesn't match
check_vpnendpointid

echo
if [ "$was_rebuild" == 1 ]
then 
    echo "- Re-created: ${recreatecont_notify_complete_msg[@]}"
    recreatecont_notify_complete
fi
echo 
echo "----------------"
echo "| Run Complete |"
echo "----------------"
echo
