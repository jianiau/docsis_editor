#========================================================
# name: move
# purpose: change item's position.TLV32/33(s) need be treat as one item
# input: direction (up/down)
#========================================================
proc move {direction} {
	global TREE columnID
	set item [$TREE selection get]
	set type [tree_get_type $item]
	set cvc 0	
	if {($type==32) || ($type==33) || ($type==81)||($type==82) } {
		foreach {top end} [get_cvc_index] {}
		set cvc 1
	}
	if {($item != 0) && ($item != "")} {
		if {$cvc} {
			set prev [$TREE item prevsibling $top]
			set next [$TREE item nextsibling $end]	
		} else {
			set prev [$TREE item prevsibling $item]
			set next [$TREE item nextsibling $item]
		}				
		set prev_type 999		
		catch {set prev_type [tree_get_type $prev]}
		if {($prev_type==32)||($prev_type==33) || ($prev_type==81)||($prev_type==82)} {
			foreach {temp_top temp_end} [get_cvc_index $prev] {}
			set prev [list $temp_top $temp_end]
		}
		set next_type 999
		catch {set next_type [tree_get_type $next]}
		if {($next_type==32)||($next_type==33)||($next_type==81)||($next_type==82)} {
			foreach {temp_top temp_end} [get_cvc_index $next] {}
			set next [list $temp_top $temp_end]
		}
		set type_item [get_type_item $item]
	} else {return}
	
	if {$direction == "up"} {
		if {$prev==""} {return}
		if {$cvc} {set item $end}
		if {[llength $prev]==1} {
			$TREE item nextsibling $item $prev
		} else {
			for {set i [lindex $prev 0]} {$i<=[lindex $prev 1]} {incr i} {
				$TREE item nextsibling $item $i
				set item $i
			}
		}
	} else {
		if {$next==""} {return}
		if {$cvc} {set item $top}
		if {[llength $next]==1} {
			$TREE item prevsibling $item $next
		} else {
			for {set i [lindex $next 1]} {$i>=[lindex $next 0]} {incr i -1} {
				$TREE item prevsibling $item $i
				set item $i
			}
		}						
	}
	# update the "type" items's data
	get_node_data $type_item
}


#========================================================
# name:place_toplevel
# purpose: According to mani window's position place the window 
#========================================================
proc place_toplevel {win_name {shift_x 50} {shift_y 50}} {
	# set x [expr [winfo x .] + $shift_x]
	# set y [expr [winfo y .] + $shift_y]
	# if {$x < 0} {
		# set x 0
	# }
	# if {$y < 0} {
		# set y 0
	# }
	# wm maxsize $win_name [winfo screenwidth $win_name] [winfo screenheight $win_name]
	# wm geometry $win_name +$x+$y
	# wm deiconify $win_name
	# tkwait visibility $win_name
	#Sleep 10
#	grab $win_name
	focus $win_name
	::tk::PlaceWindow $win_name widget .
	
}


#========================================================
# name:insert_gui
# purpose: init insert gui
#
# The gui will be useed many times, so when will not destroy
# it. Just hide it, when not in use.
#
#======================================================

proc insert_gui {} {
	global TREE tlvdata p sel_type sel_child sel_subtype
	# insert_val
	if [winfo exist .insert] {
		place_toplevel $p
		return
	}
	set p [toplevel .insert]
	wm withdraw $p
	wm resizable $p 0 0
	wm minsize $p 500 0
	wm title $p "TLV Data"	
	if {[winfo viewable [winfo toplevel [winfo parent $p]]]} {
		wm transient $p [winfo toplevel [winfo parent $p]]
    }
	ttk::frame $p.fr_t
	grid [ttk::label $p.fr_t.lb_type -text "Type"] -row 0 -column 0 -sticky wn -padx 5 -pady 5
	grid [ttk::label $p.fr_t.lb_child -text "Child"] -row 1 -column 0 -sticky wn -padx 5 -pady 5
	grid [ttk::label $p.fr_t.lb_subtype -text "Subtype"] -row 2 -column 0 -sticky wn -padx 5 -pady 5
	grid [ttk::combobox $p.fr_t.cb_type -value $tlvdata(types_name) -textvariable sel_type] -row 0 -column 1 -sticky wen -padx 5 -pady 5
	grid [ttk::combobox $p.fr_t.cb_child -textvariable sel_child -values "" -state disable] -row 1 -column 1 -sticky wen -padx 5 -pady 5
	grid [ttk::combobox $p.fr_t.cb_subtype -textvariable sel_subtype -values "" -state disable] -row 2 -column 1 -sticky wen -padx 5 -pady 5
	grid [ttk::button $p.bt_ok -text OK] -row 4 -column 0 -sticky w -padx 5 -pady 20 -columnspan 2
	grid $p.fr_t -row 0 -column 0 -sticky news
	grid columnconfigure $p.fr_t 1 -weight 1
	text $p.val -height 10
	#=============================================
	# snmp edit frame
	#=============================================
	ttk::frame $p.fr_s
	grid [ttk::label $p.fr_s.lb_o -text "SNMP OID"] -row 0 -column 0 -sticky wn -padx 5 -pady 5
	grid [ttk::entry $p.fr_s.en_o -textvariable ::insert_s_oid] -row 0 -column 1 -sticky new -padx 5 -pady 5
	grid [ttk::label $p.fr_s.lb_v -text "Value"] -row 1 -column 0 -sticky wn -padx 5 -pady 5
	grid [ttk::entry $p.fr_s.en_v -textvariable ::insert_s_val] -row 1 -column 1 -sticky new -padx 5 -pady 5
	grid [ttk::label $p.fr_s.lb_t -text "Type"] -row 2 -column 0 -sticky wn -padx 5 -pady 5
	set snmp_types [list int unint ascii hex ip ]
	# grid [ttk::combobox $p.fr_s.en_t -value $snmp_types -textvariable ::insert_s_type -state readonly] -row 2 -column 1 -sticky new -padx 5 -pady 5
	grid [ttk::frame $p.fr_s.fr ] -row 2 -column 1 -sticky news -padx 5 -pady 5
	grid [ttk::radiobutton $p.fr_s.fr.rb_1 -variable ::insert_s_type -value int -text Integer32]   -row 0 -column 0 -padx 5 -pady 5
	grid [ttk::radiobutton $p.fr_s.fr.rb_2 -variable ::insert_s_type -value uint -text UInteger32] -row 0 -column 1 -padx 5 -pady 5
	grid [ttk::radiobutton $p.fr_s.fr.rb_3 -variable ::insert_s_type -value ascii -text "ASCII"] -row 0 -column 2 -padx 5 -pady 5
	grid [ttk::radiobutton $p.fr_s.fr.rb_4 -variable ::insert_s_type -value hex -text "Hex"] -row 0 -column 3 -padx 5 -pady 5
	grid [ttk::radiobutton $p.fr_s.fr.rb_5 -variable ::insert_s_type -value ip -text "IpAddr"] -row 0 -column 4 -padx 5 -pady 5
	grid columnconfigure $p.fr_s 1 -weight 1
	# grid columnconfigure $p.fr_s.fr 0 -weight 1
	# grid rowconfigure $p.fr_s.fr 0 -weight 1
	set ::insert_s_oid ""
	set ::insert_s_val ""
	set ::insert_s_type int
	bind $p.fr_s.en_v <Return> {$p.bt_ok invoke}	
	#=============================================
	# file edit frame
	#=============================================
	ttk::frame $p.fr_f
	grid [ttk::label $p.fr_f.lb -text "Value"] -row 0 -column 0 -sticky wn -padx 5
	# grid [text $p.fr_f.val -height 10] -row 0 -column 1 -sticky news
	grid [ttk::entry $p.fr_f.val -textvariable ::insert_f_val] -row 0 -column 1 -sticky news
	grid [ttk::button $p.fr_f.bt_open -text "Browse" -command get_cvcfile] -row 0 -column 2 -padx 5 -sticky we
	grid columnconfigure $p.fr_f 1 -weight 1
	bind $p.fr_f.val <Return> {$p.bt_ok invoke}
	#=============================================
	# normal edit frame
	#=============================================
	ttk::frame $p.fr_v
	grid [ttk::label $p.fr_v.lb -text "Value     "] -row 0 -column 0 -sticky wn -padx 5
	grid [ttk::entry $p.fr_v.en_val -textvariable ::insert_v_val] -row 0 -column 1 -sticky new -padx 5
	set ::insert_v_val ""
	grid columnconfigure $p.fr_v 1 -weight 1
	grid columnconfigure $p 0 -weight 1
	bind $p.fr_v.en_val <Return> {$p.bt_ok invoke}
	#=============================================
	# TLV10 edit frame
	#=============================================
	ttk::frame $p.fr_tlv10
	grid [ttk::label $p.fr_tlv10.lb -text "Value     "] -row 0 -column 0 -sticky wn -padx 5
	grid [ttk::entry $p.fr_tlv10.en_val -textvariable ::insert_tlv10_val] -row 0 -column 1 -sticky new -padx 5
	grid [ttk::radiobutton $p.fr_tlv10.rb_yes -value 0 -text Allow -variable ::insert_tlv10_wr] -row 0 -column 2 -padx 5
	grid [ttk::radiobutton $p.fr_tlv10.rb_no  -value 1 -text Disallow  -variable ::insert_tlv10_wr] -row 0 -column 3 -padx 5
	set ::insert_tlv10_val ""
	set ::insert_tlv10_wr 0
	grid columnconfigure $p.fr_tlv10 1 -weight 1
	grid columnconfigure $p 0 -weight 1
	bind $p.fr_v.en_val <Return> {$p.bt_ok invoke}
	#=============================================
	# user defined edit frame
	#=============================================
	ttk::frame $p.fr_user
	grid [ttk::label $p.fr_user.lb -text "Value    "] -row 0 -column 0 -sticky wn -padx 5
	grid [ttk::entry $p.fr_user.en_val -textvariable ::insert_user_val] -row 0 -column 1 -sticky new -padx 5
	set ::insert_v_val ""
	grid [ttk::frame $p.fr_user.fr ] -row 4 -column 1 -sticky news -padx 5 -pady 5
	grid [ttk::radiobutton $p.fr_user.fr.rb_1 -variable ::insert_user_type -value int -text Integer] -row 0 -column 0 -padx 5 -pady 5
	grid [ttk::radiobutton $p.fr_user.fr.rb_2 -variable ::insert_user_type -value hex -text "Hex String"] -row 0 -column 1 -padx 5 -pady 5
	grid [ttk::radiobutton $p.fr_user.fr.rb_3 -variable ::insert_user_type -value ascii -text "String"] -row 0 -column 2 -padx 5 -pady 5
	set ::insert_user_type hex
	grid columnconfigure $p.fr_user 1 -weight 1
	grid columnconfigure $p 0 -weight 1
	bind $p.fr_user.en_val <Return> {$p.bt_ok invoke}
	#---------------------------------------------
	grid rowconfigure $p 3 -weight 1	
    update idletasks
	place_toplevel $p
	wm protocol $p WM_DELETE_WINDOW {
		wm withdraw $p
		grab release $p
	}
	insert_bind
}

#========================================================
# name:insert_bind
# purpose: create insert_gui binding event
#============================================================= 
#	1. According to combobox selection, change childre's selection
#	2. According to combobox selection(type), change edit frame
#	3. Support direct input value
#	4. Create new type
#=============================================================
proc insert_bind {} {
	global tlvdata p sel_type sel_child sel_subtype newtlvdata
	bind $p.fr_t.cb_type <<ComboboxSelected>> {
		if [regexp {\((\d+)\)} $sel_type match tt] {
			if [info exist tlvdata($tt,childs)] {
				$p.fr_t.cb_child configure -values $tlvdata($tt,childs_name) -state normal
				$p.fr_t.cb_child set [lindex $tlvdata($tt,childs_name) 0]
			} else {
				$p.fr_t.cb_child configure -values "" -state disable
				set sel_child ""
			}
			grid forget $p.fr_s
			grid forget $p.fr_f
			grid forget $p.fr_v
			grid forget $p.fr_user
			grid forget $p.fr_tlv10
			switch $tt {
				"10" {
					grid $p.fr_tlv10 -row 3 -column 0 -sticky new -columnspan 1
					set ::set_gui_type tlv10
				}
				"11" {
					grid $p.fr_s -row 3 -column 0 -sticky new -columnspan 1
					set ::set_gui_type snmp
				}
				"32" -
				"33" -
				"81" -
				"82" {
					grid $p.fr_f -row 3 -column 0 -sticky new -columnspan 1
					set ::set_gui_type file
				}
				default {
					if [info exist tlvdata($tt,name)] {
						grid $p.fr_v -row 3 -column 0 -sticky new -columnspan 1
						set ::set_gui_type value
					} else {
						grid $p.fr_user -row 3 -column 0 -sticky new -columnspan 1
						set ::set_gui_type user
					}
				}
			}
		}
		update
	}
	bind $p.fr_t.cb_child <<ComboboxSelected>> {
		if [regexp {\((\d+)\)} $sel_child match cc] {
			if [info exist tlvdata($tt.$cc,subtypes)] {
				$p.fr_t.cb_subtype configure -values $tlvdata($tt.$cc,subtypes_name) -state normal
				$p.fr_t.cb_subtype set [lindex $tlvdata($tt.$cc,subtypes_name) 0]
			} else {
				$p.fr_t.cb_subtype configure -values "" -state disable
				set sel_subtype ""
			}
		}
	}
	bind $p.fr_t.cb_type <Return> {
		if {![check_type sel_type]} {return}
		if [info exist tlvdata($sel_type,name)] {
			set ind [lsearch $tlvdata(types) $sel_type]
			ttk::combobox::SelectEntry $p.fr_t.cb_type $ind
			update
		} else {
			set newtlvdata($sel_type,name) "Type-$sel_type"
			set reply [my_dialog .foo "Unknow Type" "Does $sel_type has child ?" \
			"" 1 Yes No]
			if {!$reply} {
				$p.fr_t.cb_child configure -values "" -state normal
				set newtlvdata($sel_type,childs) ""
			}
			set sel_type "\($sel_type\) Type-$sel_type"
			grid forget $p.fr_s
			grid forget $p.fr_f
			grid forget $p.fr_v
			grid forget $p.fr_user
			grid $p.fr_user -row 3 -column 0 -sticky new -columnspan 1
			set ::set_gui_type user
			update
		}
	}
	bind $p.fr_t.cb_child <Return> {
		if {![check_type sel_child]} {return}
		regexp {\((\d+)\)} $sel_type match tt		
		if [info exist tlvdata($tt.$sel_child,name)] {
			set ind [lsearch $tlvdata($tt,childs) $sel_child]
			ttk::combobox::SelectEntry $p.fr_t.cb_child $ind
			update
		} else {
			set newtlvdata($tt.$sel_child,name) "Type-$tt.$sel_child"
			set reply [my_dialog .foo "Unknow Type" "Does $sel_child has subtype ?" \
			"" 1 Yes No]
			if {!$reply} {
				$p.fr_t.cb_subtype configure -values "" -state normal
				set newtlvdata($tt.$sel_child,subtypes) ""
			}
			set sel_child "\($sel_child\) Type-$tt.$sel_child"
			grid forget $p.fr_s
			grid forget $p.fr_f
			grid forget $p.fr_v
			grid forget $p.fr_user
			grid $p.fr_user -row 3 -column 0 -sticky new -columnspan 1
			set ::set_gui_type user
			update
		}
	}
	bind $p.fr_t.cb_subtype <Return> {
		if {![check_type sel_subtype]} {return}
		regexp {\((\d+)\)} $sel_type match tt
		regexp {\((\d+)\)} $sel_child match cc		
		if [info exist tlvdata($tt.$cc.$sel_subtype,name)] {
			set ind [lsearch $tlvdata($tt.$cc,subtypes) $sel_subtype]
			ttk::combobox::SelectEntry $p.fr_t.cb_subtype $ind
			update
		} else {
			# check new type is value , TBD
			set newtlvdata($tt.$cc.$sel_subtype,name) "Type-$tt.$cc.$sel_subtype"
			set sel_subtype "\($sel_subtype\) Type-$tt.$cc.$sel_subtype"
			grid forget $p.fr_s
			grid forget $p.fr_f
			grid forget $p.fr_v
			grid forget $p.fr_user
			grid forget $p.fr_tlv10
			grid $p.fr_user -row 3 -column 0 -sticky new -columnspan 1
			set ::set_gui_type user
			update
		}
	}
}

#========================================================
# name:insert_gui_update
# purpose: according main gui's action, update insert gui
# 1.Update combobox items,state
# 2.Update value edit frame
#========================================================

proc insert_gui_update {{mode edit}} {
	global TREE tlvdata p columnID sel_type sel_child sel_subtype newtlvdata

	if [catch {set type [tree_get_type]}] {
		.fr_r.fr_2.bt_5 configure -state disable
		.fr_r.fr_2.bt_6 configure -state disable
		return 0
	}
	set value [tree_get_sel_value]
	set raw_value [tree_get_sel_value_data]
	puts "#### DBG: raw_value=$raw_value"
	foreach {t c s} [split $type .] {}
	puts "insert: mode=$mode tcs=$t $c $s"
	
	# not support edit mic value
	if {$t==6 || $t==7} {
		if {$mode=="edit"} {
			::tk::MessageBox -message "Can not edit this type" -type ok -icon warning
			# tk_messageBox -message "Can not edit this type" -type ok -icon warning
			return
		}
	}
	
	# If the selection is 32/33
	# in edit mode: show info, not support edit
	# IN insert mode : change the selection to the last item of 32/33
	if {$t==32|| $t==33} {
		if {$mode=="edit"} {			
			get_cvc_item
			return
		}
		if {$mode=="insert"} {
			set now [$TREE selection get]
			set end [lindex [get_cvc_index] 1]
			if {$now!=$end} {
				$TREE selection add [lindex [get_cvc_index] 1]
				$TREE selection anchor
				$TREE selection clear $now
			}	
		}		
	}
	
	if {$t==81|| $t==82} {
		if {$mode=="edit"} {			
			get_cvc_chain_item
			return
		}
		if {$mode=="insert"} {
			set now [$TREE selection get]
			set end [lindex [get_cvc_index] 1]
			if {$now!=$end} {
				$TREE selection add [lindex [get_cvc_index] 1]
				$TREE selection anchor
				$TREE selection clear $now
			}	
		}		
	}
	
	# enable insert gui
	insert_gui
	# clear all data
	set ::insert_s_oid  ""
	set ::insert_s_val  ""
	set ::insert_s_type int
	set ::insert_user_type int
	set ::insert_user_val ""
	set ::insert_f_val ""
	set ::insert_tlv10_val ""
	set ::insert_tlv10_wr 0
	$p.fr_t.cb_type set ""
	$p.fr_t.cb_child set ""
	$p.fr_t.cb_subtype set ""
	$p.fr_t.cb_type configure -state disable
	$p.fr_t.cb_child configure -state disable
	$p.fr_t.cb_subtype configure -state disable

	$p.bt_ok configure -command "
		insert [set mode]
	"
	switch $mode {
		"insert" {
			set ::insert_v_val ""
			if {$s!=""} {
				$p.fr_t.cb_type configure -state disable
				set ind [lsearch $tlvdata(types) $t]
				if {$ind!=-1} {
					ttk::combobox::SelectEntry $p.fr_t.cb_type $ind
				} else {
					set sel_type "\($t\) Type-$t"
				}
				update
				$p.fr_t.cb_child configure -state disable
				if [info exist newtlvdata($t,childs)] {
					set ind -1
				} else {
					set ind [lsearch $tlvdata($t,childs) $c]
				}
				if {$ind!=-1} {
					ttk::combobox::SelectEntry $p.fr_t.cb_child $ind
				} else {
					set sel_child "\($c\) Type-$c"
					$p.fr_t.cb_subtype configure -state normal
					grid $p.fr_user -row 3 -column 0 -sticky new -columnspan 1
				}
				update
				return
			}
			if {$c!=""} {
				$p.fr_t.cb_type configure -state disable
				set ind [lsearch $tlvdata(types) $t]
				if {$ind!=-1} {
					ttk::combobox::SelectEntry $p.fr_t.cb_type $ind
				} else {
					set sel_type "\($t\) Type-$t"
					$p.fr_t.cb_child configure -state normal
					$p.fr_t.cb_subtype configure -state normal
					grid $p.fr_user -row 3 -column 0 -sticky new -columnspan 1
				}
				update
				return
			}
			ttk::combobox::SelectEntry $p.fr_t.cb_type 0
			$p.fr_t.cb_type configure -state enable
			focus $p.fr_t.cb_type
			ttk::entry::Select $p.fr_t.cb_type 0 line
			update
		}
		"insertchild" {
			set ::insert_v_val ""
			$p.fr_t.cb_type configure -state disable
			set ind [lsearch $tlvdata(types) $t]
			if {$ind!=-1} {
				ttk::combobox::SelectEntry $p.fr_t.cb_type $ind
			} else {
				set sel_type "\($t\) Type-$t"
				$p.fr_t.cb_child configure -state normal
				grid $p.fr_user -row 3 -column 0 -sticky new -columnspan 1
			}
			update
			if {$c!=""} {
				$p.fr_t.cb_child configure -state disable
				if [info exist newtlvdata($t,childs)] {
					set ind -1
				} else {
					set ind [lsearch $tlvdata($t,childs) $c]
				}
				if {$ind!=-1} {
					ttk::combobox::SelectEntry $p.fr_t.cb_child $ind
				} else {
					set sel_child "\($c\) Type-$c"
					$p.fr_t.cb_subtype configure -state normal
					grid $p.fr_user -row 3 -column 0 -sticky new -columnspan 1
				}
				update
			}
		}
		"edit" {
			grid forget $p.fr_s
			grid forget $p.fr_f
			grid forget $p.fr_v
			grid forget $p.fr_user
			grid forget $p.fr_tlv10

			$p.fr_t.cb_type configure -state disable
			$p.fr_t.cb_child configure -state disable
			$p.fr_t.cb_subtype configure -state disable
			if {![info exist newtlvdata($type,name)]} {
				if {$t!=""} {
					set ind [lsearch $tlvdata(types) $t]
					ttk::combobox::SelectEntry $p.fr_t.cb_type $ind
					update
				}
				if {$c!=""} {
					set ind [lsearch $tlvdata($t,childs) $c]
					ttk::combobox::SelectEntry $p.fr_t.cb_child $ind
					update
				}
				if {$s!=""} {
					set ind [lsearch $tlvdata($t.$c,subtypes) $s]
					ttk::combobox::SelectEntry $p.fr_t.cb_subtype $ind
				}
				insert_value_update $value
			} else {
				if [info exist tlvdata($t,name)] {
					set ind [lsearch $tlvdata(types) $t]
					ttk::combobox::SelectEntry $p.fr_t.cb_type $ind
					update
				} else {
					catch {set sel_type $newtlvdata($t,name)}
				}
				if [info exist tlvdata($t.$c,name)] {
					set ind [lsearch $tlvdata($t,childs) $c]
					ttk::combobox::SelectEntry $p.fr_t.cb_child $ind
					update
				} else {
					catch {set sel_child $newtlvdata($t.$c,name)}
				}
				catch {set sel_subtype $newtlvdata($t.$c.$s,name)}				
				set ::set_gui_type user
				grid $p.fr_user -row 3 -column 0 -sticky new -columnspan 1
				insert_value_update $raw_value
			}
		}
	}
}

#========================================================
# name:insert_value_update
# purpose: set the value to .insert 's edit value frame
#========================================================

proc insert_value_update {value} {
	# global TREE tlvdata p columnID sel_type sel_child sel_subtype
	global p
	switch $::set_gui_type {
		"snmp" {
			$p.fr_s.en_o delete 0 end
			$p.fr_s.en_v delete 0 end
			$p.fr_s.en_o insert end [lindex $value 0]
			$p.fr_s.en_v insert end [lindex $value 2]
			regexp {\((.+)\)} [lindex $value 1] match typename
			set ::insert_s_type $typename
		}
		"file" {
		}
		"tlv10" {
			regexp {(.+)/(.+)} $value match oid allow
			set ::insert_tlv10_val $oid
			if {$allow=="Allow"} {
				set ::insert_tlv10_wr 0
			} else {
				set ::insert_tlv10_wr 1
			}
		}
		"value" {
			set ::insert_v_val $value
		}
		"user" {
			set ::insert_user_type hex			
			set ::insert_user_val $value
		}
	}
}

#========================================================
# name:insert
# purpose: In "edit" mode, update new value
#		   else, insert new node to the tree
#========================================================

proc insert {{mode insert}} {
	global TREE tlvdata p columnID
	global sel_type sel_child sel_subtype
	set item [$TREE selection get end]	
	# set current_sel_type [$TREE item element cget $item $columnID elemText1 -data]
	set current_sel_type [tree_get_type $item]
	foreach {t c s} [split $current_sel_type .] {}	
	switch $mode {
		"edit" {
			if {[get_value $current_sel_type ll vv dd]} {
				$TREE item element configure $item $columnID elemText2 -text \[Len=$ll\] -data $ll
				$TREE item element configure $item $columnID elemText3 -text $vv -data $dd
				set type_item [get_type_item $item]
				get_node_data $type_item
				update
			} else {
				return
			}
		}
		default {
			set insert_level 1
			if {$c!=""} {
				set insert_level 2
			}
			if {$s!=""} {
				set insert_level 3
			}
			update
			set sel_t ""
			set sel_c ""
			set sel_s ""
			if [catch {
				regexp {\((\d+)\)} $sel_type match sel_t
				regexp {\((\d+)\)} $sel_child match sel_c
				regexp {\((\d+)\)} $sel_subtype match sel_s				
			} ret ] {puts "dbg ret=$ret"}
			set new_level 0
			if {$sel_t!=""} {incr new_level}
			if {$sel_c!=""} {incr new_level}
			if {$sel_s!=""} {incr new_level}			
			if {$new_level>0} {
				set insert_type $sel_t
				set insert_type_t $sel_t
			}
			if {$new_level>1} {
				set insert_type $sel_t.$sel_c
				set insert_type_c $sel_t.$sel_c
			}
			if {$new_level>2} {
				set insert_type $sel_t.$sel_c.$sel_s
				set insert_type_s $sel_t.$sel_c.$sel_s
			}
			
			if {$sel_t==32 || $sel_t==33} {
				if {$::insert_f_val==""} {return}
				if {![file exist $::insert_f_val]} {return}	
				add_cvc $sel_t -file $::insert_f_val $item				
				wm withdraw $p
				grab release $p
				set ::insert_f_val ""
				return
			}
			
			if {$sel_t==81 || $sel_t==82} {
				if {$::insert_f_val==""} {return}
				if {![file exist $::insert_f_val]} {return}	
				add_cvc $sel_t -file $::insert_f_val $item				
				wm withdraw $p
				grab release $p
				set ::insert_f_val ""
				return
			}
			
			set parent [$TREE item parent $item]
			if {![info exist insert_type]} {return}
			if {[get_value $insert_type ll vv dd]} {
				switch [expr $new_level-$insert_level] {
					"0" {
						# Insert type/child/subtype in the same order as selected item
						set newnode [add_node $parent $insert_type $ll $vv $dd]
						$TREE item nextsibling $item $newnode
					}
					"2" {
						if {$mode=="insert"} {
							# Insert type-child-subtype to root
							set newnode [add_node $parent $insert_type_t 0 "" ""]
							$TREE item nextsibling $item $newnode
							set newnode [add_node $newnode $insert_type_c 0 "" ""]
							set newnode [add_node $newnode $insert_type_s $ll $vv $dd]
						} else {
							# Insert child-subtype to selected type
							set newnode [add_node $item $insert_type_c 0 "" ""]
							set newnode [add_node $newnode $insert_type_s $ll $vv $dd]
						}
					}
					"1" {
						if {$mode=="insert"} {
							if {$parent==0} {
								# Insert type and child to root
								set newnode [add_node $parent $insert_type_t 0 "" ""]
								$TREE item nextsibling $item $newnode
								set newnode [add_node $newnode $insert_type_c $ll $vv $dd]
							} else {
								# Insert child and subtype to selected type
								set newnode [add_node $parent $insert_type_c 0 "" ""]
								$TREE item nextsibling $item $newnode
								set newnode [add_node $newnode $insert_type_s $ll $vv $dd]
							}
						} else {
							if {$parent==0} {
								# Insert child to type
								set newnode [add_node $item $insert_type_c $ll $vv $dd]
							} else {
								# Insert subtype to child
								set newnode [add_node $item $insert_type_s $ll $vv $dd]
							}
						}
					}
				}
				set type_item [get_type_item $newnode]
				get_node_data $type_item
			} else {
				return
			}
		}
	}
	wm withdraw $p
	grab release $p
}

#=====================================
# update leng:
#	1.goto type node
#	2.update

proc get_type_item {item} {
	global TREE
	set parent -1
	while {[$TREE item parent $item]!=0} {
		set item [$TREE item parent $item]
	}
	return $item
}

proc get_cvcfile {} {	
	set file [tk_getOpenFile]
	if {$file != ""} {
		set ::insert_f_val $file
	}
}


#========================================================
# name:next_delete_node
# purpose: Select to next item
# input: node (current selected item)
# output: del_list (the items that will be deleted)
#========================================================

proc next_delete_node {node} {
	global TREE columnID	
	set del_list ""
	if {$node==""} {return}
	set type [tree_get_type $node]
	if {($type==32)||($type==33)||($type==81)||($type==82)} {
		foreach {top end} [get_cvc_index $node] {}
		set node $end
		for {set i $top} {$i<=$end} {incr i} {lappend del_list $i}
	} else {
		lappend del_list $node
	}
	set new [$TREE item nextsibling $node]
	if {$new!=""} {
		$TREE selection add $new
		$TREE selection anchor
		return $del_list
	}
	set new [$TREE item prevsibling $node]
	if {$new!=""} {
		$TREE selection add $new
		$TREE selection anchor
		return $del_list
	}
	set new [$TREE item parent $node]
	if {$new!=0} {
		return [next_delete_node $new]
	}
}

#========================================================
# name:load_config
# purpose: Read config file, and build the tree
# input: node (current selected item)
# output: del_list (the items that will be deleted)
#========================================================
proc load_config {{drag 0} {filename ""}} {
	global TREE columnID newtlvdata	
	if {! $drag} {
		set types {
			{{cfg Files}   {.cfg}}
			{{All Files}        *}
		}
		set filename [tk_getOpenFile -filetypes $types -initialdir $::file_init_dir]
	}
	if {$filename != ""} {
		$TREE item element configure root $columnID elemText1 -text [file tail $filename]		
		# .fr_l.t item delete 0 end
		$TREE item delete 0 end
		set fd [open $filename r]
		fconfigure $fd -encoding binary -translation binary
		catch {unset newtlvdata}
		build_tree [read $fd]
		close $fd
		set ::file_init_dir [file dirname $filename]
	}
}

#========================================================
# name:wizard
# purpose: Create a basic config file in few steps
#========================================================
proc wizard {} {
	global TREE columnID
	$TREE item element configure root $columnID elemText1 -text "File: <No File>"
	foreach  child [$TREE item children root] {
		$TREE item delete $child
	}
	add_node root 3 1 1 01
	add_node root 18 1 16 10
	if [my_dialog .foo "TLV29" "BPI enable ?" "" 1 Yes No] {
		add_node root 29 1 0 00
	} else {
		add_node root 29 1 1 01
	}
	if [my_dialog .foo "Provision mode" "Class of Service or Service Flow" "" 1 "Class of Service" "Service Flow"] {
		quick_add_service_flow
	} else {
		set temp [add_node root 4 3 "" 010101]
		add_node $temp 4.1 1 1 01
		get_node_data $temp
	}
	if {![my_dialog .foo "" "Enable snmp?" "" 0 Yes No]} {
		quick_add_snmp_53_55
	}
	if {![my_dialog .foo "" "Secure firmware upgrade?" "" 1 Yes No]} {
		quick_add_fw_upgrade
	}
}

proc get_user_input {{title ""} {msg ""} {default_value ""}} {
	namespace eval _get_input {}
	catch {destroy .pop_entry}
	set p [toplevel .pop_entry]
	wm transient $p [winfo toplevel [winfo parent $p]]	
	wm title $p $title
	wm resizable $p 0 0
	wm minsize $p 280 40
	place_toplevel $p 50 50	
	pack [ttk::frame $p.fr ] -fill both -expand 1
	pack [ttk::label $p.fr.lb -text $msg] -padx 10 -pady 5 -fill both -expand 1
	pack [ttk::entry $p.fr.en -textvariable ::get_user_input_ret] -padx 10 -pady 5 -fill both -expand 1	
	pack [ttk::frame $p.fr2 ] -fill both -expand 1
	grid [ttk::button $p.fr2.bt_ok -text "OK" -command "set ::uset_input_wait 1"] -row 0 -column 0 -padx 5 -pady 5
	grid [ttk::button $p.fr2.bt_cancel -text "Cancel" -command "set ::uset_input_wait 0"] -row 0 -column 1 -padx 5 -pady 5
	focus $p.fr.en
	# set ::get_user_input_ret ""
	set ::get_user_input_ret $default_value
	bind $p.fr.en <Return> {
		# set uset_input_wait 1
		.pop_entry.fr2.bt_ok invoke
	}
	bind $p <Destroy> {
		# set ::get_user_input_ret ""
		set ::uset_input_wait 0
		# .pop_entry.fr2.bt_cancel invoke
	}
	vwait ::uset_input_wait
	if {$::uset_input_wait} {
		set ret $::get_user_input_ret
	} else {
		set ret ""
	}
	destroy .pop_entry
	return $ret
}


#========================================================
# name:quick_add_snmp_53_55
# purpose: Enable snmp via tlc53/55
#========================================================

proc quick_add_snmp_53_55 {} {
	# public
	set temp [add_node root 53 0 "" ""]
	add_node $temp 53.1 6 public 7075626c6963
	set temp2 [add_node $temp 53.2 0 "" ""]
	add_node $temp2 53.2.1 6 0.0.0.0/0 000000000000
	add_node $temp2 53.2.2 6 0.0.0.0/0 000000000000
	set temp2 [add_node $temp 53.2 0 "" ""]
	add_node $temp2 53.2.1 18 ::/0 000000000000000000000000000000000000
	add_node $temp2 53.2.2 18 ::/0 000000000000000000000000000000000000
	add_node $temp 53.3 1 2 02
	add_node $temp 53.4 17 docsisManagerView 646f637369734d616e6167657256696577
	get_node_data $temp
	# private
	set temp [add_node root 53 0 "" ""]
	add_node $temp 53.1 7 private 70726976617465
	set temp2 [add_node $temp 53.2 0 "" ""]
	add_node $temp2 53.2.1 6 0.0.0.0/0 000000000000
	add_node $temp2 53.2.2 6 0.0.0.0/0 000000000000
	set temp2 [add_node $temp 53.2 0 "" ""]
	add_node $temp2 53.2.1 18 ::/0 000000000000000000000000000000000000
	add_node $temp2 53.2.2 18 ::/0 000000000000000000000000000000000000
	add_node $temp 53.3 1 2 02
	add_node $temp 53.4 17 docsisManagerView 646f637369734d616e6167657256696577
	get_node_data $temp
	add_node root 55 1 1 01
}


#========================================================
# name:quick_add_fw_upgrade
# purpose: Add cvc(TLV32)/server(TLV21/58)/File name(TLV9)
#          to config file
#========================================================

proc quick_add_fw_upgrade {} {
	# set file [tk_getOpenFile -title "Select Manufacturer Code Verification Certificate"]
	set types {
		{{p7b Files}   {.p7b}}
		{{All Files}        *}
	}
	set filename [tk_getOpenFile -title "Select Signed File" -filetypes $types]
	if {$filename!=""} {
		set p7bfile [open $filename r]
		fconfigure $p7bfile -translation binary -encoding binary
		# while {![eof $cvcfile]} {
			# binary scan [read $cvcfile 254] H* hexstr
			# set ll [expr [string length $hexstr]/2]
			# add_node 0 32 $ll $hexstr $hexstr
		# }
		set p7b_data [read $p7bfile]
		close $p7bfile
		foreach {ret cert_list} [p7b_get_cert p7b_data] {}
puts cert_list=[lindex [lindex $cert_list 0] 0]
		switch $ret {
			"1" {
				foreach {pki cert_type} [lindex [lindex $cert_list 0] 0] {}
				if {$pki=="legacy" && $cert_type=="mfg"} {
					add_cvc 32 -data [lindex [lindex $cert_list 0] 1]
				} else {
					return
				}
				
			}
			"2" {
				foreach {pki0 cert_type0} [lindex [lindex $cert_list 0] 0] {}
				foreach {pki1 cert_type1} [lindex [lindex $cert_list 1] 0] {}
				if {($pki0 != $pki1) || ($cert_type0==$cert_type1)} {return}
				if {$pki0=="legacy"} {
					if {$cert_type0=="mfg"} {
						add_cvc 32 -data [lindex [lindex $cert_list 0] 1]
						add_cvc 33 -data [lindex [lindex $cert_list 1] 1]
					} else {
						add_cvc 32 -data [lindex [lindex $cert_list 1] 1]
						add_cvc 33 -data [lindex [lindex $cert_list 0] 1]
					}					
				} else {
				    set certlist ""
					lappend certlist [lindex [lindex $cert_list 0] 1]
					lappend certlist [lindex [lindex $cert_list 1] 1]
					set tlv81 [PKCS7_deg $certlist]
					add_cvc 81 -data $tlv81
				}
				
			}
			"3" {
			}
		}		
		
		set ret [get_user_input "Server Address" "SW Upgrade IPv4/IPv6 TFTP Server"]
		if {$ret!=""} {
			switch -- [::ip::version $ret]  {
				"4" {
					add_node root 21 4 [::ip::normalize $ret] [string range [::ip::toHex $ret] 2 end]
				}
				"6" {
					if [catch {::ip::normalize $ret} ipv6] {
						tk_messageBox -message "Invalid IP address" -type ok -icon warning
						return
					}
					set hexip [join [split $ipv6 ":"] ""]
					set ipv6 [::ip::contract $ipv6]
					add_node root 58 16 $ipv6 $hexip
				}
				default {
					tk_messageBox -message "Invalid IP address" -type ok -icon warning
					return
				}
			}
		}
		set ret [get_user_input "Filename" "SW Upgrade Filename" [file tail $filename]]
		if {([string length $ret]>0)&&([string length $ret]<255)} {
			set ll [string length $ret]
			binary scan $ret H* hex
			add_node root 9 $ll $ret $hex
		}		
	}
}

proc quick_add_service_flow {} {
	set temp [add_node root 24 7 "" ""]
	add_node $temp 24.1 2 1 0001
	add_node $temp 24.6 1 7 07
	get_node_data $temp
	set temp [add_node root 25 7 "" ""]
	add_node $temp 25.1 2 6 0006
	add_node $temp 25.6 1 7 07
	get_node_data $temp
}

#
# type: 32 or 33
# input : -data or -file
# input_data : if -data : data / if -file :filepath
# insert_item : insert location

proc add_cvc {type input input_data {insert_item 0}} {
	global TREE
	switch -- $input {
		"-data" {
			set data $input_data
		}
		"-file" {
			if [file exist $input_data] {
				set fd [open $input_data r]
				fconfigure $fd -translation binary
				set data [read $fd]
			} else {
				return
			}
		}
		"default" {
			return
		}
	}
	while {[string length $data]} {
		::asn::asnGetBytes data 254 raw		
		binary scan $raw H* hexstr
		set leng [string length $raw]		
		set newnode [add_node 0 $type $leng $hexstr $hexstr]
		if {$insert_item!=0} {
			$TREE item nextsibling $insert_item $newnode
			set insert_item $newnode
		}
	}	
}
