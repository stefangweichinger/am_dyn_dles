#! /bin/bash

####################################################################################################
#
# NAME: 	am_create_sized_dles.sh
#
# April, 22nd, 2010 by Stefan G. Weichinger
#
# PURPOSE:
#
# read in files of given directory, and generate several text-files for use as
# so-called include-lists with the amanda backup suite
#
# each include-list contains only files summing up to less than a given target-size
# so that all the files in one list should fit nicely on one target tape
#
# the initial problem to solve was to fully backup a mythtv-backend-server, which holds hundreds of
# video files. these get deleted and created in a very dynamic way, so it was necessary to 
# generate fitting include-lists for every run
#
# USAGE: /usr/local/bin/am_create_sized_dles.sh DIRECTORY AMANDA-config
#
# generates include-files into /etc/amanda/CONFIG/includes
#
# which can be used in your DLE via
#
# TODO
####################################################################################################

### initialization

# initial size of include-list
SIZE_LIST=0

# suffix starts with 0
FILE_SUFFIX=0

FILE_PREFIX="include"

# remove existing output-files
rm /tmp/$FILE_PREFIX.* 2> /dev/null
rm /tmp/checklist      2> /dev/null

# maximum size of one DLE
# TARGET_DLE_SIZE=100000000 # 100 GB
#TARGET_DLE_SIZE=100000000
TARGET_DLE_SIZE=100000

###

CONFIG="$1"

#INCLUDES_DIR="/etc/amanda/$1/includes"
##== Once you have transfered $1 to CONFIG, don't use it again.
INCLUDES_DIR="/etc/amanda/$CONFIG/includes"
#debug:
#echo "incl-dir: $INCLUDES_DIR"

#SOURCEDIR="/mnt/myth1"
SOURCEDIR="$2"

DLE_NAME=${SOURCEDIR//\//_}
echo "dlename: $DLE_NAME"

SIZE_OVERALL=`du -s $SOURCEDIR`
# 761370132

#################################

# save and change IFS
OLDIFS=$IFS
IFS=$'\n' 

## read all files and their sizes into an array

#DIR_CONTENT=( $(find $SOURCEDIR -type f))
DIR_CONTENT=( $(du -k $SOURCEDIR/*))

# restore it
IFS=$OLDIFS

# get length of an array
tLen=${#DIR_CONTENT[@]}


# use for loop read all filenames
	for (( i=0; i<${tLen}; i++ ))

	# debugg
	#for (( i=0; i<10; i++ ))

	do

	# debug: echo whole line
	# echo "LINE: ${DIR_CONTENT[$i]}"


	# extract size
	# SIZE_ELEMENT=`expr "${DIR_CONTENT[$i]}" : '\(\S*\s\)'`
##== Seems to me the expr was leaving behind the whitespace
##== character that terminated the size column.  May not cause
##== any problem, but why chance it.
##== For Name_Element you use shell builtins, why not here?
	# SIZE_ELEMENT="${DIR_CONTENT[$i]%\t*}"
##== Some of my systems don't recognize \t there (use $'\t')
##== and some du's put out spaces instead of tabs (use [ \t]).
##== File names may have spaces or tabs (use %% for "left most).
##== So combining these:
	SIZE_ELEMENT="${DIR_CONTENT[$i]%%[ $'\t']*}"
	# debug
	# echo "SIZE: $SIZE_ELEMENT"

	# extract name
	# NAME_ELEMENT=${DIR_CONTENT[$i]#*\t}
##== Same comments as above
	NAME_ELEMENT=${DIR_CONTENT[$i]#*[ $'\t']}
	# debug
	# echo "NAME1: $NAME_ELEMENT"

	# extract only the filename without leading path
	NAME_ELEMENT=${NAME_ELEMENT##*/}
	# debug
	# echo "NAME2: $NAME_ELEMENT"
	
	# debug: generate one file containing all lines for cross-check
	echo $NAME_ELEMENT >> /tmp/checklist

	# sum up the size so far
	let "SIZE_LIST=$SIZE_LIST+$SIZE_ELEMENT"
##== there is a logic problem here.  On the element that trips over
##== the limit, you have the size in the current list but the name
##== goes to the new list with size zero.  Move this into a revised
##== if statement as below.
	# debug
	# echo "SIZE_LIST: $SIZE_LIST"

	##
	# if [ "$SIZE_LIST" -lt "$TARGET_DLE_SIZE" ]
	if (( SIZE_LIST + SIZE_ELEMENT <= TARGET_DLE_SIZE ))
	then
	  ((SIZE_LIST+=SIZE_ELEMENT))
	  echo "./$NAME_ELEMENT" >> /tmp/$FILE_PREFIX.$DLE_NAME.$FILE_SUFFIX
	else
		# start next list: increase suffix, echo filename into new list
		# reset size-counter
		let "FILE_SUFFIX += 1"
		echo "./$NAME_ELEMENT" >> /tmp/$FILE_PREFIX.$DLE_NAME.$FILE_SUFFIX
		SIZE_LIST=$SIZE_ELEMENT
	fi

	done

	cp /tmp/$FILE_PREFIX.* $INCLUDES_DIR

