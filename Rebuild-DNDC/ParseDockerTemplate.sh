#ParseDockerTemplate.sh
#ver=2.2
#Author - unRAID forum member: skidelo
#Contributors - Alex R. Berg, eafx, JimmyGerms, Phil-Barker
#Source: https://forums.unraid.net/topic/40016-start-docker-template-via-command-line/
#This script relies on 'xmllint' which is installed by default in unRAID v6.0.1

#ChangeLog
#   - Fixed env variable parsing - eafx
#   - Added IP argument parsing - eafx
#   - Workaround for pulling Timezone  -eafx
#   - Added CPU pinning - JimmyGerms
#   - Fixed port, volume and env variable parsing - Phil Barker

#Variable declarations and initialization
docker="/usr/bin/docker run -d --label net.unraid.docker.managed=dockerman"
xmllint_path="/usr/bin/xmllint"
verbose=0
dryrun=0

usage() {
	echo "Please provide path to your <template.xml> file!"
	echo "This should be in '/boot/config/plugins/dockerMan/templates-user/' directory"
	echo "Optional Arguments:"
	echo "-h help"
	echo "-v verbose"
	echo "-y dry run"
	exit
}

while getopts "hvy" opt; do
    case $opt in
	h)
	    usage
	    exit
	    ;;
	v)
	    verbose=1
	    ;;
	y)
		echo "Dry-Run: Will not start dockers, just parse xml and build command."
	    dryrun=1
	    ;;
    esac
done
shift $(( $OPTIND -1 ))

numArgs=$#

#Check that an argument was given to script
if [[ $numArgs == 0 ]]; then
	usage
fi


#Function definitions
check_args(){
	#Check that the file actually exists
	if [[ ! -f $xmlFile ]]; then
		echo "File '$xmlFile' does not exist!"
		exit
	fi

	#Check that the .xml file's root node is <Container>
	xmllint --noout --xpath /Container $xmlFile > /dev/null 2>&1
	if [[ $? != 0 ]]; then
		echo "Invalid .xml file!"
		exit
	fi

	#Check that xmllint is installed
	if [[ ! -f $xmllint_path ]]; then
		echo "This script requires 'xmllint' to be installed!"
		exit
	fi
}

add_name(){
	name=$(xmllint --xpath "/Container/Name/text()" $xmlFile)
	container_name=$name
	docker_string+=" --name=\"$name\""
	echo "Name: $name"
}

add_ip(){
	MyIP=$(xmllint --xpath "/Container/MyIP/text()" $xmlFile 2> /dev/null)
	ip=$MyIP
	if [[ $ip != "" ]]; then
		docker_string+=" --ip=\"$ip\""
		[ "$verbose" = "1" ] && echo "Found IP:  --ip=\"$ip\""
	fi
}

add_cpuset(){
	status=0
	xmllint --noout --xpath "/descendant::CPUset/text()" $xmlFile > /dev/null 2>&1
	status=$?
	if [[ $status == 0 ]]; then
		cpus=$(xmllint --xpath "//CPUset/text()" $xmlFile)
		docker_string+=" --cpuset-cpus=\"$cpus\""
		[ "$verbose" = "1" ] && echo "Found CPU Pinning:  $cpus"
	fi
}

add_net(){
	call_add_ports=0
	nettest=$(xmllint --xpath "/Container/Networking/Mode/text()" $xmlFile 2> /dev/null)
	if [ -z "$nettest" ]; then
		net=$(xmllint --xpath "/Container/Network/text()" $xmlFile 2> /dev/null);
	else
		net=$(xmllint --xpath "/Container/Networking/Mode/text()" $xmlFile 2> /dev/null)
	fi
	if [[ $net != "none" ]]; then
		docker_string+=" --net=\"$net\""
		if [[ $net == bridge ]]; then
			call_add_ports=1
		fi
		[ "$verbose" = "1" ] && echo "Found Net:  --net=\"$net\""
	fi
}

add_privileged(){
	privileged=$(xmllint --xpath "/descendant::Privileged/text()" $xmlFile 2> /dev/null)
	if [[ $privileged == "true" ]]; then
		docker_string+=" --privileged=\"$privileged\""
		[ "$verbose" = "1" ] && echo "Found Privilege:  --privileged=\"$privileged\""
	fi
}

add_envars(){
	status=0
	numEnVars=1
	while [[ $status == 0 ]]; do
		xmllint --noout --xpath "/Container/Config[$numEnVars]" $xmlFile > /dev/null 2>&1
		status=$?
		if [[ $status == 0 ]]; then
			type=$(xmllint --xpath "/Container/Config[$numEnVars]/@Type" $xmlFile)
			type=`echo "$type" | cut -d'"' -f 2`
			if [[ $type == 'Variable' ]]; then
				name=$(xmllint --xpath "/Container/Config[$numEnVars]/@Target" $xmlFile | cut -d '"' -f 2)
				value=$(xmllint --xpath "/Container/Config[$numEnVars]/text()" $xmlFile | cut -d '"' -f 2)
				docker_string+=" -e $name=\"$value\""
				[ "$verbose" = "1" ] && echo "Found Environment:  -e $name=\"$value\""
			fi
			((numEnVars++))
		else
			break
		fi
	done
}

add_timezone(){
	#bindtime=$(xmllint --xpath "//BindTime/text()" $xmlFile 2> /dev/null)
    #if [[ $bindtime == "true" ]]; then
	#       timezone=$(cat /boot/config/ident.cfg | grep timeZone | sed -e 's/timeZone=//' -e 's/\r//g')
	#       docker_string+=" -e TZ=$timezone"
	#       [ "$verbose" = "1" ] && echo "Found TimeZone:  -e TZ=$timezone"
	#fi
		docker_string+=" -e TZ=\"$TZ\""
		[ "$verbose" = "1" ] && echo "Found TimeZone:  -e TZ=\"$TZ\""
}

add_ports(){
	status=0
	numPorts=1
	while [[ $status == 0 ]]; do
		xmllint --noout --xpath "/Container/Config[$numPorts]" $xmlFile > /dev/null 2>&1
		status=$?
		if [[ $status == 0 ]]; then
			type=$(xmllint --xpath "/Container/Config[$numPorts]/@Type" $xmlFile)
			type=`echo "$type" | cut -d'"' -f 2`
			if [[ $type == 'Port' ]]; then
				hostPort=$(xmllint --xpath "/Container/Config[$numPorts]/@Target" $xmlFile | cut -d '"' -f 2)
				containerPort=$(xmllint --xpath "/Container/Config[$numPorts]/text()" $xmlFile)
				protocol=$(xmllint --xpath "/Container/Config[$numPorts]/@Mode" $xmlFile | cut -d '"' -f 2)
				currentArg=" -p $hostPort:$containerPort/$protocol"
				docker_string+=$currentArg
				[ "$verbose" = "1" ] && echo "Found Port: $currentArg"
			fi
			((numPorts++))
	    else
	    break
	fi
	done
}

add_volumes(){
	status=0
	numVolumes=1
	while [[ $status == 0 ]]; do
		xmllint --noout --xpath "/Container/Config[$numVolumes]" $xmlFile > /dev/null 2>&1
		status=$?
		if [[ $status == 0 ]]; then
			type=$(xmllint --xpath "/Container/Config[$numVolumes]/@Type" $xmlFile | cut -d '"' -f 2)
			if [[ $type == 'Path' ]]; then
				hostDir=$(xmllint --xpath "/Container/Config[$numVolumes]/text()" $xmlFile)
				containerDir=$(xmllint --xpath "/Container/Config[$numVolumes]/@Target" $xmlFile | cut -d '"' -f 2)
				mode=$(xmllint --xpath "/Container/Config[$numVolumes]/@Mode" $xmlFile | cut -d '"' -f 2)
				#TO DO: Succesfully wrap hostDir and containerDir in double quotes to allow
				#for spaces in filenames.  Using escape characters does not work here.
				#Docker complains about the volume mapppings not being an 'absolute path'.
				#This is because bash wraps strings with escape characters in strong quotes,
				#making it so Docker receives the argument with escape characters included.
				docker_string+=" -v \"$hostDir\":\"$containerDir\":$mode"
				[ "$verbose" = "1" ] && echo "Found volume:  -v \"$hostDir\":\"$containerDir\":$mode"
			fi
			((numVolumes++))
		else
			break
		fi
	done
}

add_extraparams(){
	status=0
	xmllint --noout --xpath "/descendant::ExtraParams/text()" $xmlFile > /dev/null 2>&1
	status=$?
	if [[ $status == 0 ]]; then
		extraparams=$(xmllint --xpath "/descendant::ExtraParams/text()" $xmlFile)
		docker_string="$docker_string $extraparams"
		[ "$verbose" = "1" ] && echo "Found Extra params:  $extraparams"
	fi
}

add_repository(){
	repository=$(xmllint --xpath "/Container/Repository/text()" $xmlFile)
	docker_string+=" $repository"
	[ "$verbose" = "1" ] && echo "Found Repo:  $repository"
}



# First check all files before loading any
for xmlFile in "$@"
do
    check_args
done


for xmlFile in "$@"
do
	#Main - Call each function
	#Each function adds to the 'docker run' argument
	#list, based on what is in the .xml file.
	docker_string="$docker"

	add_name
	add_cpuset
	add_net
	add_ip
	add_privileged
	add_envars
	add_timezone
	add_ports
	add_volumes
	add_extraparams
	add_repository

	# we could check for existing container with something like this


	#Run the docker image with arguments based on .xml file
	[ "$verbose" = "1" ] || [ "$dryrun" = "1" ] && echo "$docker_string"

	if [ $(docker ps -f name=$container_name | wc -l) = "1" ] ; then
		# Run through bash or eval to get \" converted into quoted strings and avoid errors like 'strconv.ParseBool: parsing "\"true\"": invalid syntax'
		[ "$dryrun" = "0" ] && eval $docker_string && wait $!;
	    status=$?
	    if [[ $status != 0 ]]; then
		echo "Command was: $docker_string"
		echo "Note this script does not parse xml encoded strings correctly (like &#xF8;), which may cause docker to fail."
		fi
	else
		echo "Container already exists: $container_name"
	fi
	echo
done
