#! /bin/bash

# ***************************************************************************
#
# ANT startup file
#
# Copyright 2017 by John Wiley & Sons Inc. All Rights Reserved.
#
# ***************************************************************************

#if [ "$JAVA_HOME"="" ]; then
#	echo ERROR: JAVA_HOME not found in your environment.
#	echo Please, set the JAVA_HOME variable in your environment to match
#	echo the location of the Java Virtual Machine you want to use.
#else
	MY_ANT_HOME=$ANT_HOME
	ANT_HOME=./ant
	echo Starting Ant...
	echo System ANT_HOME=$MY_ANT_HOME
	echo Using local ANT_HOME=$ANT_HOME
	"$ANT_HOME/bin/ant" $1 $2 $3 $4 $5 $6
	ANT_HOME=$MY_ANT_HOME
#fi
