#!/bin/bash -v

MY_DIR=`dirname $0`
parse_make="${MY_DIR}/parse_make.rb"
set_finder_comment="${MY_DIR}/set_finder_comment"
append_finder_comment="${MY_DIR}/append_finder_comment"

${parse_make} --cpu-config > cpu_config.h
${parse_make} --sound-config > sound_config.h

find mame -print | xargs ${set_finder_comment} ""
${parse_make} --cpu-sources | xargs ${set_finder_comment} osx-cpu
${parse_make} --debug-cpu-sources | xargs ${set_finder_comment} osx-debug-cpu
${parse_make} --sound-sources | xargs ${set_finder_comment} osx-sound
${parse_make} --driver-sources | xargs ${set_finder_comment} osx-driver

${parse_make} --tiny --cpu-sources --sound-sources --driver-sources \
	| xargs ${append_finder_comment} osx-tiny
