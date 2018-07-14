#!/bin/bash

# edit this list, or set GSD_SITES to add your custom sites
BASE_SITES="reddit.com forums.somethingawful.com somethingawful.com digg.com break.com news.ycombinator.com infoq.com bebo.com twitter.com facebook.com blip.com youtube.com vimeo.com delicious.com flickr.com friendster.com hi5.com linkedin.com livejournal.com meetup.com myspace.com plurk.com stickam.com stumbleupon.com yelp.com slashdot.com"
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
echo $DIR

SITES="$GSD_SITES $BASE_SITES $(<$DIR/blacklist)"

HOSTFILE="/etc/hosts"
ALIAS=10.0.0.1
REDIRECT_SERVER="127.0.0.1"
PORT="6790"

# expects as first argument the amount of seconds to count down
countdown() {
	now=$(date +%s)
	end=$((now + $1))
	while (( now < end )); do   
		printf "%s\r" "$(date -u -j -f %s $((end - now)) +%T)"  
		sleep 0.25  
		now=$(date +%s)
	done
	echo
}

cleanup() {
	kill -9 $(cat /tmp/gsd_app)
	exit 1
}

if [ ! -w $HOSTFILE ]; then
    echo "cannot write to $HOSTFILE, try running with sudo"
    exit 1
fi

# clean up previous entries from /etc/hosts
sed -i -e '/#gsd$/d' $HOSTFILE

# while working iterate over session cycle (25-5)
if [ "$1" != "--play" ]
then
	working=true
fi

trap cleanup INT TERM
# write hosts file if 'work' mode
# on switch back to play no kill is necessary
while [ "$working" = "true" ]
do
	# run server for image on localhost:port
	node "$DIR/app.js" "$PORT" &
	echo $!  > /tmp/gsd_app # store node pid in file to be deleted later

	# set up an alias that every website redirects to but that in itself redirects to localhost:port
	ifconfig lo0 $ALIAS alias
	echo "rdr pass on lo0 inet proto tcp from any to $ALIAS port 80 -> $REDIRECT_SERVER port $PORT" | pfctl -ef -

    for SITE in $SITES; do
	    echo "$ALIAS\t$SITE\t#gsd" >> $HOSTFILE
	    echo "$ALIAS\twww.$SITE\t#gsd" >> $HOSTFILE
    done

	if [ "$(uname -s)" == "Darwin" ]; then
		dscacheutil -flushcache
		for BROWSER in chromium Chrome iceweasel; do
			pkill -s TERM -f $BROWSER
			#killall -9 $BROWSER > /dev/null 2>&1
		done
	elif [ "$(uname -s)" == "Linux" ]; then
		for BROWSER in chromium firefox iceweasel; do
			killall $BROWSER > /dev/null 2>&1
		done
	fi

	# Adds a Countdown/Session timer that is activatable by -t <minutes>
	if [ "$1" == "-t" ]
	then
		# second argument should be time in minutes
		seconds=$((60*$2))
		echo "Session started - Let's get to work!"
		countdown $seconds

		# after countdown ring a bell and clean up the hostfile again (Mac OS X Specific)
		sed -i -e '/#gsd$/d' $HOSTFILE
		printf \\a

		# use AppleScript to get a user decision (continue working after break or finish)
		osascript -e 'tell app "System Events" to set answer to the button returned of (display dialog "Session Finished! Take a break?" buttons {"No", "Break"} default button 2)' | tail -n 1 > /tmp/gsd_out
		decision=$(cat /tmp/gsd_out)

		# if the decision was to take a break countdown 5 minutes, alert and go back to working
		if [ "$decision" == "Break" ]
		then
			echo "Break started - Lean back!"
			countdown $((5))
			printf \\a
			osascript -e 'tell app "System Events" to set answer to the button returned of (display dialog "Break Finsished! Go on working?" buttons {"No", "Yes"} default button 2)' | tail -n 1 > /tmp/gsd_out
			decision2=$(cat /tmp/gsd_out)

			if [ "$decision2" == "No" ]
			then
				working=false
			fi
		else
			working=false
		fi
	else
		working=false
	fi
done