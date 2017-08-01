#!/bin/sh
MY_DEVICE=switch6
RELAY_CTRL=/sys/class/leds/tp-link:blue:relay/brightness

#send relay status via mqtt
sendstatus(){
	#get relay status
	STATUS=$(cat $RELAY_CTRL)
	#send MQTT status message
	case "$STATUS" in
		1) #on
			mosquitto_pub -h mqtt.lan -t "stat/$MY_DEVICE/POWER" -m "on"
		;;
		0) #off
			mosquitto_pub -h mqtt.lan -t "stat/$MY_DEVICE/POWER" -m "off"
		;;
	esac
}


#Receive MQTT command and control the relay or respond with the current status
msghandle(){
while :
do
	mosquitto_sub -v -h mqtt.lan -t "cmnd/$MY_DEVICE/power" -q 1 | while read -r MSG;
	do
		#Use wildcard to ignore most of verbrose messages
		case "$MSG" in
			#set relay status
			*on) echo "on"
				echo 1 > $RELAY_CTRL
				mosquitto_pub -h mqtt.lan -t "stat/$MY_DEVICE/POWER" -m "on"
			;;
			*off) echo "off"
				echo 0 > $RELAY_CTRL
				mosquitto_pub -h mqtt.lan -t "stat/$MY_DEVICE/POWER" -m "off"
			;;
			#Report the current status
			*) echo "else"
			sendstatus
			;;
		esac
	#Use verbose mode to make it easier to receive null messages
	done
done
}

#run message handler in the background
msghandle &

#Return the relay status every 3 seconds
while :
do
	sendstatus
	sleep 3
done

exit 0
