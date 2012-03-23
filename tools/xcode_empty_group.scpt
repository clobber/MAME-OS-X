#!/bin/sh
exec <"$0" || exit; read v; read v; exec /usr/bin/osascript - "$@"; exit

on empty_group(theGroupName)
	tell application "Xcode"
		set myProject to project "mameosx"
		set myRoot to root group of myProject
		set myMameGroup to group "mame" of myRoot
		set myGroup to group theGroupName of myMameGroup
		
		tell myGroup
			delete (every group whose name is "auto")
			make new group with properties {name:"auto", path: "" path type:group relative}
		end tell
	end tell
end empty_group

on run argv
	set theGroupName to item 1 of argv
	empty_group(theGroupName)
	return "Done"
end run
