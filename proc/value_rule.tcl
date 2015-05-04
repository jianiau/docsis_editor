
#========================================================
# name:get_value
# purpose: Get and check value from insert gui
# output: 1(Pass)/0(Fail)
#        length, readable data, hex data
#========================================================

proc get_value {tlvtype pleng ptext pdata} {
	global tlvdata p
	upvar $pleng nleng
	upvar $ptext ntext
	upvar $pdata ndata
	
	puts "tlvtype=$tlvtype"
	# puts "exist ? [info exist tlvdata($tlvtype,val_type)]"
	if [info exist tlvdata($tlvtype,val_type)] {		
		# puts "tlvdata($tlvtype,val_type)=$tlvdata($tlvtype,val_type)"
		set type $tlvdata($tlvtype,val_type)
		set leng $tlvdata($tlvtype,val_leng)
	} else {
		# user defined type
		if {[string length $::insert_user_val]==0} {return 0}
		switch $::insert_user_type {
			"int" {
				puts insert_user_val=$::insert_user_val
				if {![string is integer $::insert_user_val]} {return 0}
				set nleng 4
				set ntext $::insert_user_val
				set ndata [format %08x $::insert_user_val]
				if {[string length $ndata]!=8} {return 0}
				return 1
			}
			"ascii" {				
				if {![string is print $::insert_user_val]} {return 0}
				set nleng [string length $::insert_user_val]				
				set ntext $::insert_user_val
				binary scan $::insert_user_val H* ndata
				# set ndata $str
				return 1
			}
			"hex" {
				set str [join [split $::insert_user_val ".: "] ""]				
				if {![string is xdigit  $str]} {return 0}
				if [expr [string length $str]%2] {
					return 0
				}
				set leng [expr [string length $str]/2]
				set nleng $leng
				set ntext [string toupper $str]
				set ndata $str
				return 1
			}
		}
	}	
	puts "::set_gui_type=$::set_gui_type,type=$type"

	switch $type {
		"oooo" -
		"octet" {
			set str [join $::insert_v_val ""]
			puts "dbg str=$str leng=$leng expr [expr [string length $str]/2.0]"
			set leng [string length [binary format H* $str]]
			# if {[expr [string length $str]/2.0]!=$leng} {return 0}
			set nleng $leng
			set ntext $str
			set ndata $str
		}
		"tlv10" {
			set oid [split $::insert_tlv10_val .]			
			if [catch {::asn::asnObjectIdentifier $oid} data] {return 0}			
			if {$::insert_tlv10_wr} {
				append data \x01
				set ntext $::insert_tlv10_val/Disallow				
			} else {
				append data \x00
				set ntext $::insert_tlv10_val/Allow
			}
			set nleng [string length $data]			
			binary scan $data H* ndata
			return 1
		}
		"ipv4" {
			if [catch {::ip::normalize  $::insert_v_val} ipv4] {return 0}
			if [catch {::ip::version  $::insert_v_val} ver] {return 0}
			if {$ver!=4} {return 0}
			set hexip [string range [::ip::toHex $ipv4] 2 end]
			set nleng $leng
			set ntext $ipv4
			set ndata $hexip
			return 1
		}
		"ipv6" {
			if [catch {::ip::normalize  $::insert_v_val} ipv6] {return 0}
			if [catch {::ip::version  $::insert_v_val} ver] {return 0}
			if {$ver!=6} {return 0}
			set hexip [join [split $ipv6 ":"] ""]
			set ipv6 [::ip::contract $ipv6]
			set nleng $leng
			set ntext $ipv6
			set ndata $hexip
puts -------------			
			return 1
		}
		"snmp" {
			puts "::insert_s_oid  $::insert_s_oid"
			puts "::insert_s_val  $::insert_s_val"
			puts "::insert_s_type $::insert_s_type"

			set oid [split $::insert_s_oid .]
			if [catch {::asn::asnObjectIdentifier $oid} data] {return 0}
			switch $::insert_s_type {
				"int" {
					if [catch {
						append data [::asn::asnInteger $::insert_s_val]}
					] {return 0}
				}
				"uint" {
					if [catch {
						if {$::insert_s_val<0} {return 0}
						set vv [::asn::asnInteger $::insert_s_val]
						append data [::asn::asnRetag vv 0x42]
					}
					] {return 0}
				}
				"ascii" {
					set len [string length $::insert_s_val]
					if {$len<=0 || $len>254} {puts qqqzzzxxxsswsew ;return 0}
					append data [::asn::asnOctetString $::insert_s_val]
				}
				"hex" {					
					set ::insert_s_val [join [split $::insert_s_val ":. "] ""]
					if {![check_hex $::insert_s_val]} {return 0}
					append data [::asn::asnOctetString [binary format H* $::insert_s_val]]
				}
				"ip" {
					if {[::ip::version $::insert_s_val]!=4} {return}
					set ::insert_s_val [::ip::normalize $::insert_s_val]
					append data \x40\x04
					append data [binary format I [::ip::toInteger $::insert_s_val]]
				}
			}
			binary scan [::asn::asnSequence $data] H* ndata
			set nleng [expr [string length $ndata]/2]
			set ntext "$::insert_s_oid \($::insert_s_type\) $::insert_s_val"
			return 1
		}
		"text" {
			set min 1
			set max 254
			regexp {(\d+)-(\d+)} $leng match min max
			binary scan [binary format a* $::insert_v_val] H* hex
			set nleng [string length $::insert_v_val]
			if {($nleng>=$min)&&($nleng<=$max)} {
				set ntext $::insert_v_val
				set ndata $hex
				return 1
			}
			return 0
		}
		"int" {
			if [catch {format %0[expr 2*$leng]x $::insert_v_val} new] {
				# puts new=$new
				return 0
			}
			if {[expr [string length $new]/2.0]!=$leng} {
				# puts "why leng=$leng new=$new"
				return 0
			}
			puts "leng=$leng ::insert_v_val=$::insert_v_val new=$new"
			set nleng $leng
			set ntext $::insert_v_val
			set ndata $new
			if {![check_rule $tlvtype $ndata]} {
				return 0
			}	
			return 1
		}
		"bool" {
			if {($::insert_v_val==0) || ($::insert_v_val==1)} {
				set nleng 1
				set ntext $::insert_v_val
				set ndata 0$::insert_v_val
				return 1
			} else {
				tk_messageBox -message "Please input 0 or 1" -type ok -icon warning
				return 0
			}
		}
		"ip/port" {
			set err 0
			if {[regexp {(.+)/(\d+)} $::insert_v_val match ip port]} {
				if {$port<0 || $port>65535} {
					set err 1
				} else {
					set port [expr $port]
				}
				switch [::ip::version $ip] {
					"4" {
						set ip [::ip::normalize $ip]
						set ntext $ip/$port
						set nleng 6
						set ndata [string range [::ip::toHex $ip] 2 end][format %04x $port]
					}
					"6" {
						set ip [::ip::normalize $ip]						
						set ntext [::ip::contract $ip]/$port
						set nleng 18
						set ndata [join [split $ip ":"] ""][format %04x $port]
					}
					default {
						set err 1
					}
				}
			} else {
				set err 1
			}
			if {$err} {
				return 0
			}			
			return 1
		}

		default {
			puts "type:$type not finished"
			return 0
		}
	}
	# if {![check_rule $tlvtype $ndata]} {
		# return 0
	# }	
	return 1
}


#========================================================
# name:format_value
# purpose: format raw binary data to readable date for print
# input : type (3 / 22.1 / 22.9.1 ...)
#         val: raw binary data
# output : readable string
#========================================================

proc format_value {type val} {
#puts xxxxxxx	
	global tlvdata
		if [have_subtype $type] {
		return ""
	}
	if [info exist tlvdata($type,val_type)] {
		foreach {val_type val_leng} [split $tlvdata($type,val_type) ,] {}	
	} else {
		set val_type hex
	}
	switch $val_type {
		"int" {
			binary scan $val H* ret
			set ret [expr 0x$ret]
		}
		"bool" {
			binary scan $val H* ret
			set ret [expr 0x$ret]
		}
		"text" {
			binary scan $val a* ret
		}
		"ipv4" {
			binary scan $val H2H2H2H2 ip1 ip2 ip3 ip4
			set ret [expr 0x$ip1].[expr 0x$ip2].[expr 0x$ip3].[expr 0x$ip4]
		}
		"ipv6" {			
			binary scan $val H4H4H4H4H4H4H4H4 ip1 ip2 ip3 ip4 ip5 ip6 ip7 ip8			
			set ipv6 [::ip::contract $ip1:$ip2:$ip3:$ip4:$ip5:$ip6:$ip7:$ip8]
			set ret [::ip::contract $ipv6]
		}
		"tlv10" {			
			::asn::asnGetObjectIdentifier val oid						
			if {[string eq $val \x00]} {
				set ret [join $oid .]/Allow
			} else {
				set ret [join $oid .]/Disllow
			}
			
		}
		"snmp" {
			::asn::asnGetSequence val data
			::asn::asnGetObjectIdentifier data oid
			binary scan $oid a* oid
			# binary scan $data H* data
			set oid [join $oid .]
			::asn::asnPeekByte data type
			# puts type=$type
			set typename ""
#puts "snmp type=$type"

			switch $type {
				"2" {
					set typename int
					::asn::asnGetInteger data val
				}
				"4" {					
					::asn::asnGetOctetString data val
					if {![string is ascii $val]} {
						set typename hex
						binary scan $val H* val						
					} else {
						set typename ascii
					}
				}
				"64" {
					set typename ip
					readdata data 2
					binary scan $data H2H2H2H2 ip1 ip2 ip3 ip4 port
					set val [expr 0x$ip1].[expr 0x$ip2].[expr 0x$ip3].[expr 0x$ip4]
				}
				"65" -
				"66" -				
				"67" {
					set typename uint
					#binary scan $data H* val
					::asn::asnRetag data 2
					::asn::asnGetInteger data val
					#set val $tt
					#set val [expr 0x$val]
				}
				default {
					binary scan $data H* val
				}
			}

			set ret [list $oid $typename $val]
		}
		"ip/port" {
			if {[string length $val]==6} {
				binary scan $val H2H2H2H2H4 ip1 ip2 ip3 ip4 port
				set ret [expr 0x$ip1].[expr 0x$ip2].[expr 0x$ip3].[expr 0x$ip4]/[expr 0x$port]
			} else {
				binary scan $val H4H4H4H4H4H4H4H4H4 ip1 ip2 ip3 ip4 ip5 ip6 ip7 ip8 port
				set ipv6 $ip1:$ip2:$ip3:$ip4:$ip5:$ip6:$ip7:$ip8
				set ret [::ip::contract $ipv6]/[expr 0x$port]
			}
		}
		default {
			binary scan $val H* ret
		}
	}
	return $ret
}

proc check_rule {type hex_value} {
	switch $type {
		"1" {
			puts "WWWWWW 11111111 hex_value=$hex_value"
			if {[expr 0x$hex_value % 62500] != 0} {
				# tk_messageBox -message "The receive frequency must be a multiple of 62500 Hz" -type ok -icon warning				
				::tk::MessageBox -message "The receive frequency must be a multiple of 62500 Hz" -type ok -icon warning								
				return 0
			}			
		}
	
	}
	return 1
}

proc check_hex {value} {
	set value [join [split $value ":. "] ""]
	if {![string is xdigit $value]} {return 0}
	set len [string length $value]
	if {($len==0) || [expr $len%2]} {return 0}
	return 1
}
