#! /usr/bin/wish

set appPath [file normalize [info script]]
if {[file type $appPath] == "link"} {set appPath [file readlink $appPath]}
set rootpath [file dirname $appPath]



lappend ::auto_path [file join $rootpath lib]

package require treectrl
package require autoscroll
package require tile
package require md5
package require asn
package require ip
if [catch {package require tkdnd}] {
  set ::WITH_DND 0
} else {
  set ::WITH_DND 1
}

package require netsnmptcl

if [info exist env(MIBDIRS)] {
	snmp_loadmib -mall -M$env(MIBDIRS)
} else {
	snmp_loadmib -mall -M [file join $rootpath mibs]
}

image create photo logo -file [file join $rootpath editor.png]
wm iconphoto . -default logo

foreach tcl_file [glob -nocomplain -directory [file join $rootpath proc] -type {f} *.tcl] {
	source $tcl_file
}

update
wm deiconify .
set ::file_init_dir [pwd]
set ::version 1.02

loadtlvdata
add_node root 3 1 1 01
