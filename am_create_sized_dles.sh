#! /bin/bash
#
####################################################################################################
#
# NAME: 		am_create_sized_dles.sh
#
# April, 22nd, 2010 	first draft by Stefan G. Weichinger
# 			corrections by Jon LaBadie
#
# May, 27th, 2010	add commandline-options, sgw
#
# PURPOSE:
#
# read in files of given directory, and generate several text-files for use as
# include-lists with the amanda backup suite
#
# each include-list contains only files totalling to less than a given target-size
# so that all the files in one list should fit nicely on one target tape
#
# the initial problem to solve was to fully backup a mythtv-backend-server, which holds hundreds of
# video files. these get deleted and created in a very dynamic way, so it was necessary to 
# generate fitting include-lists for every run
#
# USAGE: /usr/local/bin/am_create_sized_dles.sh DIRECTORY AMANDA-config
#
# generates include-files into /etc/amanda/CONFIG/includes
# which can be used in your DLE via
#
# TODO
# * 	Line 26. Should the destination dir (/etc/amanda/CONFIG/includes)
# 		 be a configurable item?
#
####################################################################################################

### initialization

# set variable to some value to enable debug-behavior
DEBUG=

# maximum size (in KB) of one DLE.  default: 100000000 (100GB)
#TARGET_DLE_SIZE=100000000
TARGET_DLE_SIZE=98000000
    
# initial size of include-list
SIZE_LIST=0

# suffix starts with 0
FILE_SUFFIX=0
FILE_PREFIX="include"


# remove pre-existing include-files?
# default is set here
REMOVE_INCLUDES="1"

## read options
E_OPTERROR=85

if [ $# -eq "0" ]    # command-line args required ...
then
  echo "Usage: ${0##*/} [-r] [-s SizeLimit] -c ConfigName -d Directory"
  exit $E_OPTERROR          # Exit and explain usage.
                            # Usage: scriptname -options
                            # Note: dash (-) necessary
fi  

while getopts ":c:d:rs:" option; do
  case $option in
    c     ) CONFIG=$OPTARG;;
    d     ) SOURCEDIR="$OPTARG";;
    r     ) REMOVE_INCLUDES="1";;
    s     ) TARGET_DLE_SIZE=$OPTARG;;
    *     ) echo "Unimplemented option chosen.";;   # Default.
  esac
done

## END read options

# array counter
AR_CNT=1

# amanda config dir - TODO
AM_CONF_DIR="/etc/amanda"

INCLUDES_DIR="/etc/amanda/$CONFIG/includes"
DLE_NAME=${SOURCEDIR//\//_}
SIZE_OVERALL=`du -s $SOURCEDIR`

# file to write DLEs to
DLE_LIST="/etc/amanda/$CONFIG/dles.list.$DLE_NAME"
AM_SERVER="mythtv.oops.intern"
DLE_DUMPTYPE="mythtv-tar"

# remove existing tmp-files
rm /tmp/$FILE_PREFIX.* 2> /dev/null
rm /tmp/checklist      2> /dev/null

# remove actual include-files
if [ "$REMOVE_INCLUDES" = "1" ]; then
	#echo "removing include-files"
	rm $INCLUDES_DIR/$FILE_PREFIX.$DLE_NAME.* 2> /dev/null
fi

# remove dle-list
if [ -e $DLE_LIST ]; then
 	[ -n "$DEBUG" ] && echo "removing DLE-list"
	rm $DLE_LIST 2> /dev/null
fi

#################################

# save and change IFS
OLDIFS=$IFS
IFS=$'\n' 

## read all files and their sizes into an array

## TODO: Command will not get any "dot-files"
DIR_CONTENT=( $(du -k $SOURCEDIR/*))

# restore IFS to previously saved value
IFS=$OLDIFS

# get length of an array
tLen=${#DIR_CONTENT[@]}

# use for loop read all filenames
for (( i=0; i<${tLen}; i++ ))

do

# extract size
SIZE_ELEMENT="${DIR_CONTENT[$i]%%[ $'\t']*}"

# extract name
NAME_ELEMENT=${DIR_CONTENT[$i]#*[ $'\t']}

# extract only the filename without leading path
NAME_ELEMENT=${NAME_ELEMENT##*/}

# debug: generate one file containing all lines for cross-check
 [ -n "$DEBUG" ] && echo $NAME_ELEMENT >> /tmp/checklist


if (( SIZE_LIST + SIZE_ELEMENT <= TARGET_DLE_SIZE ))
	then
((SIZE_LIST+=SIZE_ELEMENT))
	echo "./$NAME_ELEMENT" >> /tmp/$FILE_PREFIX.$DLE_NAME.$FILE_SUFFIX

	# add name of include-file to an array
	ARRAY[$AR_CNT]="$FILE_PREFIX.$DLE_NAME.$FILE_SUFFIX"
	[ -n "$DEBUG" ] && echo $AR_CNT WERT: ${ARRAY[$AR_CNT]}  
	let AR_CNT++

	else
# start next list: increase suffix, echo filename into new list
# reset size-counter
	let "FILE_SUFFIX += 1"
	echo "./$NAME_ELEMENT" >> /tmp/$FILE_PREFIX.$DLE_NAME.$FILE_SUFFIX
	
	# add name of include-file to an array
	ARRAY[$AR_CNT]="$FILE_PREFIX.$DLE_NAME.$FILE_SUFFIX"
	 [ -n "$DEBUG" ] && echo $AR_CNT value: ${ARRAY[$AR_CNT]}  
	let AR_CNT++

	SIZE_LIST=$SIZE_ELEMENT
	fi

	done

	# copy generated include-lists to the actual directory inside the config-dir
	cp /tmp/$FILE_PREFIX.* $INCLUDES_DIR

	### generating the DLEs for the disklist
	## get only unique entries out of DLE-array
	IFS='
	'
	ARRAY=( $( printf "%s\n" "${ARRAY[@]}" | awk 'x[$0]++ == 0' ) )
	NUM_OF_EL=${#ARRAY[@]}

	## loop through array ...
	for (( i = 0 ; i < NUM_OF_EL ; i++ ))
	do
	[ -n "$DEBUG" ] && echo "Element [$i]: ${ARRAY[$i]}"

	# generate actual DLE including the include-list
	DLE_TMPL="$AM_SERVER $DLE_NAME.$i $SOURCEDIR {\n$DLE_DUMPTYPE\ninclude list \"$INCLUDES_DIR/${ARRAY[$i]}\"\n}\n"

	# and write it to the list
	echo -e $DLE_TMPL >> $DLE_LIST

	done

	exit
