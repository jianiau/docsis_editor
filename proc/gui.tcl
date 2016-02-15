#=========================================================
# main gui
#=========================================================
wm title . "DOCSIS Config Editor"
# wm geometry . 500x400+100+50
wm minsize . 660 440
wm resizable . 1 1

#set width  [winfo width  .]
#set height [winfo height .]
set width  660
set height 440
set x [expr int( ( [winfo screenwidth  .]-$width )*0.5)]
set y [expr int( ( [winfo screenheight .]-$height)*0.5)]
. configure -menu .mbar
wm geometry . ${width}x${height}+$x+$y

# menu
menu .mbar -tearoff 0
#. configure -menu .mbar
menu .mbar.file -tearoff 0
menu .mbar.edit -tearoff 0
menu .mbar.tool -tearoff 0
menu .mbar.help -tearoff 0

# file
.mbar add cascade -menu .mbar.file -label File -underline  0
.mbar.file add command -label "New" -underline 0 -command {
	$TREE item element configure root $columnID elemText1 -text "File: <No File>"		
	$TREE item delete 0 end
	# foreach  child [$TREE item children root] {
		# $TREE item delete $child
	# }
	add_node root 3 1 1 01
}
.mbar.file add command -label "Load" -underline 0 -command {load_config}
.mbar.file add command -label "Save" -underline 0 -command {save_config}
.mbar.file add separator
.mbar.file add command -label "Wizard" -underline 0 -command {wizard}
# edit
.mbar add cascade -menu .mbar.edit -label Edit -underline  0
.mbar.edit add command -label "snmp enable" -command {quick_add_snmp_53_55}
.mbar.edit add command -label "service flow" -command {quick_add_service_flow}
.mbar.edit add command -label "secure fw upgrade" -command {quick_add_fw_upgrade}
# .mbar.edit add command -label "Save" -underline 0 -command {}

# tool
.mbar add cascade -menu .mbar.tool -label Tool
.mbar.tool add command -label "hex dump" -command {	
	catch {destroy .hex}	
	toplevel .hex
	wm withdraw .hex
	wm transient .hex .
	wm resizable .hex 0 0	
	wm title .hex "Hex Dump"
	pack [frame .hex.fr] -padx 10 -pady 10
	pack [text .hex.fr.log -width 73 -font {"Courier New" 10 {}}] -side left -fill both -expand 1	
	pack [::ttk::scrollbar .hex.fr.sv -orient vertical -command [list .hex.fr.log yview]] -fill y -expand 1
	.hex.fr.log configure -yscrollcommand [list .hex.fr.sv set]	
	autoscroll::autoscroll .hex.fr.sv	
	# wm geometry  .hex 540x300
	hexdump [dbg1] ".hex.fr.log" ""
	place_toplevel .hex
}

# Help
.mbar add cascade -menu .mbar.help -label Help
.mbar.help add command -label "About" -command {
	catch {destroy .about}	
	toplevel .about
	wm withdraw .about
	wm resizable .about 0 0
	wm transient .about .
	wm title .about "About"
	pack [label .about.lb -font {Arial 10 {}} \
	-text "DOCSIS Config Editor v$version\nAuthor: Jimmy Huang\nhttp://jianiau.blogspot.tw/p/program.html"
	] -padx 10 -pady 10	-fill both -expand 1
	# wm geometry  .hex 540x300
	place_toplevel .about
}
#==============================

frame .fr_l
frame .fr_r

set TREE [treectrl .fr_l.t -bg white \
	-highlightthickness 0 \
	-selectmode single \
	-showroot yes \
	-showline 1 \
	-showrootbutton 1 \
	-showbuttons 1 \
	-showheader 0\
	-scrollmargin 0 \
]
set sv [::ttk::scrollbar .fr_l.sv -orient vertical -command [list $TREE yview]]
set sh [::ttk::scrollbar .fr_l.sh -orient horizontal -command [list $TREE xview]]
$TREE configure -yscrollcommand [list $sv set]
$TREE configure -xscrollcommand [list $sh set]
autoscroll::autoscroll $sv
autoscroll::autoscroll $sh

frame .fr_r.fr_1
frame .fr_r.fr_2
frame .fr_r.fr_3

ttk::button .fr_r.fr_1.bt_1 -text "Load..." -command {load_config}

ttk::button .fr_r.fr_1.bt_2 -text "Save..." -command {save_config}

ttk::button .fr_r.fr_2.bt_5 -text "insert" -state disable -command {
	insert_gui_update insert
}
ttk::button .fr_r.fr_2.bt_6 -text "insert child" -state disable -command {
	insert_gui_update insertchild
}
ttk::button .fr_r.fr_2.bt_7 -text "Delete"  -command {
	set node [$TREE selection get]
	if {$node!=0} {
		if {$node==""} {return}
		set type_item [get_type_item $node]
		set del_list [next_delete_node $node]
		puts del_list=$del_list
		foreach del_node $del_list {
			$TREE item delete $del_node
		}
		# $TREE item delete $node
		# set ::waitdelete ok
		# Do not update, when delete type
		if {$type_item!=$node} {
			catch {get_node_data $type_item}
		}
		if {[$TREE item count]==1} {
			add_node root 3 1 1 01
			$TREE selection add 1
			$TREE selection anchor
		}
	}
}

ttk::button .fr_r.fr_3.bt_3 -text up -command {
	move up
}
ttk::button .fr_r.fr_3.bt_4 -text down -command {
	move down
}

grid rowconfigure . 0 -weight 1
grid columnconfigure . 0 -weight 1
# grid columnconfigure . 1 -weight 1
grid rowconfigure .fr_l 0 -weight 1 
grid columnconfigure .fr_l 0 -weight 1
grid rowconfigure .fr_r 0 -weight 1
grid rowconfigure .fr_r 1 -weight 1
grid rowconfigure .fr_r 2 -weight 1
# grid rowconfigure .fr_r 3 -weight 1
# grid rowconfigure .fr_r 4 -weight 1
# grid rowconfigure .fr_r 5 -weight 1
grid .fr_l -row 0 -column 0 -sticky news -padx 15 -pady 10
grid .fr_r -row 0 -column 1 -sticky news -padx 15 -pady 10
grid .fr_l.t -row 0 -column 0 -sticky news
grid .fr_l.sv -row 0 -column 1 -sticky ns
grid .fr_l.sh -row 1 -column 0 -sticky we

grid .fr_r.fr_1 -sticky news
grid .fr_r.fr_2 -sticky news
grid .fr_r.fr_3 -sticky news
grid .fr_r.fr_1.bt_1
grid .fr_r.fr_1.bt_2 
grid .fr_r.fr_2.bt_5 
grid .fr_r.fr_2.bt_6 
grid .fr_r.fr_2.bt_7 
grid .fr_r.fr_3.bt_3 
grid .fr_r.fr_3.bt_4 


set columnID [$TREE column create]
$TREE configure -treecolumn $columnID

set w [listbox .listbox]
set SystemHighlight [$w cget -selectbackground]
set SystemHighlightText [$w cget -selectforeground]

$TREE element create elemRect rect -fill  [list $::SystemHighlight {selected}]
# -fill [list $::SystemHighlight {selected}]
$TREE element create elemText1 text -font {{Arial 10 {}}} -fill [list black {selected} black {}]
$TREE element create elemText2 text -font {{Arial 10 {}}} -fill [list black {selected} black {}]
$TREE element create elemText3 text -font {{Arial 10 {}}} -fill [list black {selected} blue {}]

$TREE style create style1
$TREE style elements style1 {elemRect elemText1 elemText2 elemText3}
# $TREE style configure style1
$TREE style layout style1 elemRect -union {elemText1 elemText2 elemText3}
$TREE style layout style1 elemText1 -ipadx 5
$TREE style layout style1 elemText3 -ipadx 5
$TREE item configure root -button yes
$TREE item style set root $columnID style1
$TREE item element configure root $columnID elemText1 -text "File: <No File>"
$TREE item element configure root $columnID elemText2 -text ""
$TREE item element configure root $columnID elemText3 -text ""

# according to selected type, change gui (insert/insert child)
$TREE notify bind $TREE <Selection> {
	if [catch {
	if {%S==0} {	
		.fr_r.fr_2.bt_5 configure -state disable
		.fr_r.fr_2.bt_6 configure -state disable		
		return
	}
	set type [$TREE item element cget %S $columnID elemText1 -data]
	if {[have_subtype $type]} {
		.fr_r.fr_2.bt_5 configure -state enable
		.fr_r.fr_2.bt_6 configure -state enable
	} else {
		.fr_r.fr_2.bt_5 configure -state enable
	    .fr_r.fr_2.bt_6 configure -state disable
	}
	} ret ] {puts ret=$ret}
}

# goto edit mode
bind $TREE <Double-1> {
	set id [$TREE identify %x %y]
	if {$id==""} {return}
	if [regexp {item (\d+)} $id match item] {
		puts item=$item
		# puts [$TREE item cget $item option]
		set t [$TREE item element cget $item $columnID elemText1 -data]
		set l [$TREE item element cget $item $columnID elemText2 -data]
		set v [$TREE item element cget $item $columnID elemText3 -text]
	}
	if {$t==""} {
		return
	}
	if {![have_subtype $t]} {
		insert_gui_update
	}
}


bind $TREE <Button-3> {
	set id [$TREE identify %x %y]
	if {$id==""} {return}
	if [regexp {item (\d+)} $id match item] {
		puts item=$item
		# puts [$TREE item cget $item option]
		set t [$TREE item element cget $item $columnID elemText1 -data]
		set l [$TREE item element cget $item $columnID elemText2 -data]
		set v [$TREE item element cget $item $columnID elemText3 -data]
		puts "data t=$t"
		puts "data l=$l"
		puts "data v=$v"
	}
	if {$t==""} {
		return
	}
}

tkdnd::drop_target register $TREE DND_Files
bind $TREE <<Drop:DND_Files>> {
	if {[file exist %D] && [file readable %D]} {
		load_config 1 %D
	}
}
