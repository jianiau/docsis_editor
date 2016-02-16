


#========================================================
# name:add_node
# purpose: Add new node to the tree in the end of parent (node_p)
# input : node_p : parent node id
#         type: type value
#         leng: data length in byte
#         value: readable value for print
#         rawdata: raw data in hex format
# output : new node's id
#========================================================

proc add_node {node_p type leng value rawdata} {
	global TREE columnID tlvdata newtlvdata
	set NODE [$TREE item create -button auto -open 1 -parent $node_p]
    $TREE item style set $NODE $columnID style1
	set name [tpye2name $type]
	if {$name=="unknow"} {
		foreach {t c s} [split $type .] {}
		if {$t!="" && $c==""} {
			set reply [my_dialog .foo "Unknow Type" "Does $type has child ?" \
			"" 1 Yes No]
			set newtlvdata($type,name) "Type-$type"
			set newtlvdata($type,val_type) new
			if {!$reply} {
				set newtlvdata($type,childs) ""
				set value ""
			}
		} elseif {$s==""} {
			set reply [my_dialog .foo "Unknow Type" "Does $type has subtype ?" \
			"" 1 Yes No]
			set newtlvdata($type,name) "Type-$type"
			if {!$reply} {
				set newtlvdata($type,subtypes) ""				
				set value ""
			}
		}
	}
    $TREE item element configure $NODE $columnID elemText1 \
	-text "[tpye2name $type] ($type)" -data $type
	$TREE item element configure $NODE $columnID elemText2 \
	-text "\[Len=$leng\] :" -data $leng
	$TREE item element configure $NODE $columnID elemText3 -text $value -data $rawdata
	update	
	return $NODE
}

#========================================================
# name:readdata
# purpose: Get and delete n bytes from data
# input : raw : raw data in binary format
#         byte: read byte number
# output : n bytes data
#========================================================

proc readdata {raw byte} {
	upvar $raw data
	if {[string length $data]<$byte} {return [list 0 ""]}
	set val [string range $data 0 [expr $byte-1]]
	set data [string range $data $byte end]
	return [list 1 $val]
}



proc build_tree {val {parent "."} {node root}} {
	global columnID
	while {[string length $val]>0} {
		# parse tlv data
		if {![tlv_get val tt ll ret]} {break}
		if {($parent==".") && (($tt==0)||($tt==255))} {
			puts "tt=$tt , break"
			break				
		}
		if {$parent!="."} {set tt $parent.$tt}			
		set vv [format_value $tt $ret]
		if {$tt==11} {
			foreach {oid type value} $vv {}
			set vv "$oid \($type\) $value"
			set vv "[string trim [snmp_translate -OXs $oid] \{\}] \($type\) $value"
			puts $oid
			puts [snmp_translate -OXs $oid]
		}
		# store data in hex mode
		binary scan $ret H* hexvalue		
		set newnode [add_node $node $tt $ll $vv $hexvalue]
		if [have_subtype $tt] {
			catch {build_tree $ret $tt $newnode}
		}
	
	}
}
proc tlv_get {cfg_var type_var leng_var value_var} {
	upvar $cfg_var cfg
	upvar $type_var type
	upvar $leng_var leng
	upvar $value_var value
	set err 0
	if {[string length $cfg]<1} {puts "type";return 0}
	::asn::asnGetByte cfg type
	if {$type==0 || $type==255} {return 1}
	if {[string length $cfg]<1} {puts "leng";return}
	::asn::asnGetByte cfg leng
	if {[string length $cfg]<$leng} {puts "value";return 0}
	::asn::asnGetBytes cfg $leng value
	return 1
}
#========================================================
# name:have_subtype
# purpose: Check if the type have child/subtype
# input : type
# output : 1(Yes)/0(No)
#========================================================

proc have_subtype {type} {
	global tlvdata newtlvdata
	foreach {t c s} [split $type .] {}
	if {$s!=""} {
		return 0
	} elseif {$c!=""} {
		if [info exist tlvdata($t.$c,subtypes)] {
			return 1
		}
		if [info exist newtlvdata($t.$c,subtypes)] {
			return 1
		}
	} else {
		if [info exist tlvdata($t,childs)] {
			return 1
		}
		if [info exist newtlvdata($t,childs)] {
			return 1
		}
	}
	return 0
}

#========================================================
# name:tpye2name
# purpose: Lookup database for type's name
# input : type
# output : name
#========================================================

proc tpye2name {type} {
	global tlvdata newtlvdata
	if {![info exist tlvdata($type,name)]} {
		if {[info exist newtlvdata($type,name)]} {
			return $newtlvdata($type,name)
		} else {
			return unknow
		}	
	}
	return $tlvdata($type,name)
}


#========================================================
# name:loadtlvdata
# purpose: load tlv database
# input : external file "tlv.txt"
# output : global array "tlvdata"
#========================================================

proc loadtlvdata {} {
	global tlvdata rootpath
	set fd [open [file join $rootpath proc tlv.txt] r]
	while {![eof $fd]} {
		if {[gets $fd line]>0} {
			foreach {type child subtype val_type val_leng name} [split $line \t] {}
			if [regexp # $type] {continue}
			if {$subtype} {
				lappend tlvdata($type.$child,subtypes) $subtype
				lappend tlvdata($type.$child,subtypes_name) "\($subtype\) $name"
				set tlvdata($type.$child.$subtype,name) $name
				set tlvdata($type.$child.$subtype,val_type) $val_type
				set tlvdata($type.$child.$subtype,val_leng) $val_leng
			} elseif {$child} {
				lappend tlvdata($type,childs) $child
				lappend tlvdata($type,childs_name) "\($child\) $name"
				set tlvdata($type.$child,name) $name
				set tlvdata($type.$child,val_type) $val_type
				set tlvdata($type.$child,val_leng) $val_leng
			} else {
				if {($type!="6") && ($type!="7")} {					
					lappend tlvdata(types) $type
					lappend tlvdata(types_name) "\($type\) $name"
				}
				set tlvdata($type,name) $name
				set tlvdata($type,val_type) $val_type
				set tlvdata($type,val_leng) $val_leng
			}
		}
	}
	close $fd
}




proc tree_get_type {{item ""}} {
	global TREE columnID
	if {$item==""} {
		set item [$TREE selection get end]
	}
	return [$TREE item element cget $item $columnID elemText1 -data]	
}


proc tree_get_sel_value {} {
	global TREE tlvdata p columnID sel_type sel_child sel_subtype
	set item [$TREE selection get end]	
	return [$TREE item element cget $item $columnID elemText3 -text]
}

proc tree_get_sel_value_data {} {
	global TREE tlvdata p columnID sel_type sel_child sel_subtype
	set item [$TREE selection get end]	
	return [$TREE item element cget $item $columnID elemText3 -data]
}
#=========================================================
# Finish config file
#
#=========================================================
proc get_node_data {node} {
	global TREE tlvdata columnID
	set t [$TREE item element cget $node $columnID elemText1 -data]
	set l [$TREE item element cget $node $columnID elemText2 -data]
	set v [$TREE item element cget $node $columnID elemText3 -data]
	set t [lindex [split $t .] end]
	set t [format %02x $t]
	set l [format %02x $l]
	set childs [$TREE item children $node]
	if {$childs==""} {
		$TREE item element configure $node $columnID elemText2 -data [expr 0x$l] -text "\[Len=[expr 0x$l]\] :"		
		return $t$l$v
	} else {
		set temp ""
		foreach child $childs {
			append temp [get_node_data $child]
		}
		set newl [format %02x [expr [string length $temp]/2]]
		$TREE item element configure $node $columnID elemText2 -data [expr 0x$newl] -text "\[Len=[expr 0x$newl]\] :"
		$TREE item element configure $node $columnID elemText3 -data $temp
		return $t$newl$temp
	}
}

proc save_config {} {
	global TREE columnID
	catch {destroy .key }
	set old_filename [$TREE item element cget 0 $columnID elemText1 -text]
	if {$old_filename=="File: <No File>"} {set old_filename ""}
	set savefile [tk_getSaveFile -initialfile $old_filename -defaultextension cfg -initialdir $::file_init_dir -filetypes [list {{Configurations Files} .cfg} {* *}]]
	if {$savefile==""} {return}	
	set ::mickey [get_user_input "Authorization String" "Please enter the Authorization String Below. \
	Note that this\nstring is case sensitive." "DOCSIS"]

	set temp ""
	set mictype {1 2 3 4 17 43 6 18 19 20 22 23 24 25 28 29 26 35 36 37 40}
	set alltypes [$TREE item children 0]
	
	# remove type 6/7
	foreach tt $alltypes {
		set temp_type [$TREE item element cget $tt $columnID elemText1 -data]
		if {($temp_type==6)||($temp_type==7)} {
			$TREE item delete $tt $tt
		} else {
			lappend typelist $temp_type
		}
	}
	
	set alltypes [$TREE item children 0]
	foreach item $alltypes {
		set type [tree_get_type $item]		
		set tlv_hex [get_node_data $item]
		if {[lsearch $mictype $type]>=0} {
			set cmtsmicdata($type) [append cmtsmicdata($type) $tlv_hex]
		}
		append temp $tlv_hex
	}
	# append cmmic
	set cmmic [md5::md5 -hex [binary format H* $temp]]
	set cmtsmicdata(6) "0610$cmmic"	
	append temp 0610$cmmic
	add_node root 6 16 "$cmmic" "$cmmic"
	set cfg $temp
	set temp ""
	foreach type $mictype {
		if [info exist cmtsmicdata($type)] {
			append temp $cmtsmicdata($type)
		}
	}
	set cmtsmic [md5::hmac -hex -key $::mickey [binary format H* $temp]]
	append cfg 0710$cmtsmic
	append cfg ff
	add_node root 7 16 "$cmtsmic" "$cmtsmic"
	set zz [open $savefile w]
	fconfigure $zz -encoding binary -translation binary
	puts -nonewline $zz [binary format H* $cfg]
	close $zz
	$TREE item element configure root $columnID elemText1 -text [file tail $savefile]
	set ::file_init_dir [file dirname $savefile]
}


proc dbg1 {} {
	global TREE columnID
	set itemlist [$TREE item range 0 end]
	set temp ""
	puts ****************************************************************
	foreach item $itemlist {
		if {$item==0} {continue}
		set pp [$TREE item parent $item]
		if {$pp!=0} {
			puts -nonewline "    "
				if {[$TREE item parent $pp]!=0} {
				puts -nonewline "    "
			}
		} else {
			append temp [format %02x [$TREE item element cget $item $columnID elemText1 -data]]
			append temp [format %02x [$TREE item element cget $item $columnID elemText2 -data]]
			append temp [$TREE item element cget $item $columnID elemText3 -data]
		}				
		puts -nonewline "[$TREE item element cget $item $columnID elemText1 -data]\t"
		puts -nonewline "[$TREE item element cget $item $columnID elemText2 -data]  "
		puts -nonewline "[$TREE item element cget $item $columnID elemText3 -data]\n"
	}
	puts ****************************************************************
	return $temp
}

# check the value is 1~254
proc check_type {val} {
	upvar $val newval
	puts val=$val	
	if {[string length $newval]==0} {return 0}
	if {![string is integer $newval]} {return 0}
	if {($newval<1) || ($newval>254)} {return 0}
	set newval [expr $newval]
	puts newval=$newval
	return 1
}



proc get_cvc_index {{item ""}} {
	global TREE columnID
	if {$item==""} {
		set item [$TREE selection get end]
	}
	set type [$TREE item element cget $item $columnID elemText1 -data]
	set top $item
	set prev [$TREE item prevsibling $top]
	puts "dbg top=$top"
	if {$prev!=""} {
		while {[$TREE item element cget $prev $columnID elemText1 -data]==$type} {
			puts "dbg while loop top=$top"
			set top $prev
			set prev [$TREE item prevsibling $top]
			if {$prev==""} {break}
		}
	}
	set end $item
	set next [$TREE item nextsibling $end]
	if {$next!=""} {
		while {[$TREE item element cget $next $columnID elemText1 -data]==$type} {
			set end $next
			set next [$TREE item nextsibling $end]
			# puts dbgnext=$next
			if {$next==""} {break}
		}
	}
	return [list $top $end]
}

proc get_cvc_item {} {
	global TREE columnID
	foreach {top end} [get_cvc_index] {}
	set temp ""
	for {set i $top} {$i<=$end} {incr i} {
		append temp [$TREE item element cget $i $columnID elemText3 -data]
	}
	if [catch {parse_cvc [binary format H* $temp]} rrr] {
		puts "decode cvc fail:$rrr"
		catch {destroy .cvc}
	}
}

proc get_cvc_chain_item {} {
	global TREE columnID
	foreach {top end} [get_cvc_index] {}
	set temp ""
	for {set i $top} {$i<=$end} {incr i} {
		append temp [$TREE item element cget $i $columnID elemText3 -data]
	}
	if [catch {parse_cvc_chain [binary format H* $temp]} rrr] {
		puts "decode cvc chain fail:$rrr"
		catch {destroy .cvcchain}
	}
}

proc Sleep {ms} {
	after $ms {
		set aa 1
	}
	vwait aa
}

proc hexdump {hex_string {log_win ""} {ch ""}} {		
	set addr 0
	set value_for_gui1 ""
	set leng [string length $hex_string]
	append value_for_gui " ┌────────────────────────────────────────────────────┬────────────────┐\n"
	append value_for_gui " │     00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F│0123456789ABCDEF│\n"
	append value_for_gui " ├────────────────────────────────────────────────────┼────────────────┤\n"
	append value_for_ch " ┌────────────────────────────────────────────────────┬────────────────┐\n"
	append value_for_ch " │     00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F│0123456789ABCDEF│\n"
	append value_for_ch " ├────────────────────────────────────────────────────┼────────────────┤\n"
	while {$leng/2>=$addr} {		
		set hex [string range $hex_string [expr $addr*2] [expr $addr*2+31]]
		set ascii [binary format H* $hex]
		regsub -all -- {[^[a-zA-Z0-9]} $ascii {.} ascii
		regsub -all -- {..} $hex {& } hex		
		append value_for_gui " │[format {%04x %s} $addr $hex]"
		append value_for_ch " │[format {%04x %s} $addr $hex]"
		set yy [string length " │[format {%04x %s} $addr $hex]"]		
		for {set i 0} {$i<[expr 55-$yy]} {incr i} {
			append value_for_gui " "
			append value_for_ch " "
		}		
		set value_for_gui [string range $value_for_gui 0 end-1]
		append value_for_gui "│$ascii"
		append value_for_ch \x08
		append value_for_ch "│" 		
		append value_for_ch "$ascii"
		for {set i 0} {$i<[expr 16-[string length $ascii]]} {incr i} {
			append value_for_gui " "
			append value_for_ch " "
		}
		append value_for_gui "│\n"
		append value_for_ch "│\n"
		incr addr 16
	}
	append value_for_gui " └────────────────────────────────────────────────────┴────────────────┘\n"
	append value_for_ch " └────────────────────────────────────────────────────┴────────────────┘"
	#append value_for_ch " ├────────────────────────────────────────────────────┼────────────────┤\n"
	if {$log_win!=""} {
		$log_win insert end $value_for_gui
	}
	if {$ch!=""} {
		puts $ch $value_for_ch
	}
}
