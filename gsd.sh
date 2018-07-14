#!/usr/bin/env bash

# edit this list, or set GSD_SITES to add your custom sites
BASE_SITES="reddit.com forums.somethingawful.com somethingawful.com digg.com break.com news.ycombinator.com infoq.com bebo.com twitter.com facebook.com blip.com youtube.com vimeo.com delicious.com flickr.com friendster.com hi5.com linkedin.com livejournal.com meetup.com myspace.com plurk.com stickam.com stumbleupon.com yelp.com slashdot.com"
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
echo $DIR

SITES="$GSD_SITES $BASE_SITES $(<$DIR/blacklist)"

HOSTFILE="/etc/hosts"

if [ ! -w $HOSTFILE ]; then
    echo "cannot write to $HOSTFILE, try running with sudo"
    exit 1
fi

# clean up previous entries from /etc/hosts
sed -i -e '/#gsd$/d' $HOSTFILE

# write hosts file if 'work' mode
# on switch back to play no kill is necessary
if [ "$1" != "--play" ]
then
    for SITE in $SITES; do
	    echo "127.0.0.1\t$SITE\t#gsd" >> $HOSTFILE
	    echo "127.0.0.1\twww.$SITE\t#gsd" >> $HOSTFILE
    done
    echo "work mode enabled, run with --play to disable"

	if [ "$(uname -s)" == "Darwin" ]; then
		dscacheutil -flushcache
		for BROWSER in chromium Google Chrome firefox iceweasel; do
			pkill -s TERM -f $BROWSER
			#killall -9 $BROWSER > /dev/null 2>&1
		done
	elif [ "$(uname -s)" == "Linux" ]; then
		for BROWSER in chromium firefox iceweasel; do
			killall $BROWSER > /dev/null 2>&1
		done
	fi
fi