if {![namespace exist asn]} {package require asn}

#========================================================
# name: p7b_get_cert
# purpose: Get certificate(s) from p7b file
# input : data_var : p7b data pointer
# output : cert_numbers cert_data_list
#========================================================

proc p7b_get_cert {data_var} {
	upvar $data_var data
	if [catch {
		::asn::asnGetSequence data data
		::asn::asnGetObjectIdentifier data oid
		if {[join $oid .]!="1.2.840.113549.1.7.2"} {
			return [list 0 "Not PKCS-7 signedData"]
		}
		::asn::asnGetContext data contextNumber SignedData	
		::asn::asnGetSequence SignedData SignedData
		::asn::asnGetInteger SignedData ver	
		::asn::asnGetSet SignedData set1
		::asn::asnGetSequence SignedData ContentInfo
		::asn::asnGetObjectIdentifier ContentInfo oid		
		::asn::asnGetContext SignedData contextNumber certificates
		set cert_number 0
		set cert_list ""
		while {[string length $certificates]>0} {
			::asn::asnGetSequence certificates cert
			lappend cert_list [::asn::asnSequence $cert]			
			incr cert_number			
		}
	} re] {
		puts re=$re
		return [list 0 $re]
	}
	return [list $cert_number $cert_list]
}




#========================================================
# name: get_attribute
# purpose: Format certificate's attribute data for print
#
#========================================================

proc get_attribute {rawdata} {
	upvar $rawdata attribute
	::asn::asnGetSet attribute data	
	::asn::asnGetSequence data data
	::asn::asnGetObjectIdentifier data oid
	::asn::asnRetag data 4
	::asn::asnGetOctetString data value
	# "2.5.4.3"  tcommonName
	# "2.5.4.6"  tcountryName
	# "2.5.4.10" torganizationName
	# "2.5.4.11" torganizationalUnitName
	set oid [join $oid .]
	switch $oid {
		"2.5.4.3"  {return "\tCN = $value"}
		"2.5.4.6"  {return "\tC  = $value"}
		"2.5.4.10" {return "\tO  = $value"}
		"2.5.4.11" {return "\tOU = $value"}
		default {return "\t$oid = $value"}
	}
}

#========================================================
# name: format_utc_time
# purpose: Format UTCTime to YYYY-MM-DD-HH:mm:ss
#          ex: 2001-01-01-00:00:00
#========================================================

proc format_utc_time {utc} {
	if {[scan $utc %2d%2d%2d%2d%2d%2d Y M D h m s]!=6} {return}
	if {$Y>50} {
		incr Y 1900
	} else {
		incr Y 2000
	}
	if {$M<1 || $M>12} {return}
	if {$D<1 || $D>31} {return}
	if {$h<0 || $h>23} {return}
	if {$m<0 || $m>59} {return}
	if {$s<0 || $s>59} {return}	
	return "\t$Y-[format %02d $M]-[format %02d $D]-[format %02d $h]:[format %02d $m]:[format %02d $s]"
}

#========================================================
# name: parse_cvc
# purpose: Decode cvc data and print info and hexdump to 
#          new window
#========================================================

proc parse_cvc {data} {
	set ::parse_cvc_raw $data
	catch {destroy .cvc}	
	toplevel .cvc	
#	wm withdraw .cvc
#	wm transient .cvc .
	wm title .cvc "CVC info"
	wm geometry .cvc 640x400
	wm resizable .cvc 0 0
	
	menu .cvc.mbar -tearoff 0
	.cvc configure -menu .cvc.mbar
	menu .cvc.mbar.file -tearoff 0
	.cvc.mbar add cascade -menu .cvc.mbar.file -label File
	.cvc.mbar.file add command -label "Dump" -command {
		set savefile ""
		set savefile [tk_getSaveFile -defaultextension cer \
		-initialdir $::file_init_dir \
		-filetypes [list {{DER X.509} .cer} {* *}]]
		if {$savefile!=""} {
			set fd [open $savefile w]
			fconfigure $fd -translation binary
			puts -nonewline $fd $::parse_cvc_raw
			close $fd
			set ::parse_cvc_raw ""
		}
	}
puts --------------------++++++++++	
	pack [ttk::notebook .cvc.nb] -padx 10 -pady 10
	pack [text .cvc.log -width 75 -font {"Courier New" 10 {}}] -padx 10 -pady 10	
	pack [frame .cvc.fr]
	pack [text  .cvc.fr.hex -width 75 -font {"Courier New" 10 {}}] -side left -fill both -expand 1	
	pack [::ttk::scrollbar .cvc.fr.sv -orient vertical -command [list .cvc.fr.hex yview]] -fill y -expand 1
	.cvc.fr.hex configure -yscrollcommand [list .cvc.fr.sv set]	
	autoscroll::autoscroll .cvc.fr.sv	
	.cvc.nb add .cvc.log -text "Info"
	.cvc.nb add .cvc.fr -text "Hex dump"	
	place_toplevel .cvc	50 -50
	
	# start get cvc information
	set cvcinfo ""
	if [catch {
		# MFG CVC header
		::asn::asnGetSequence data cvcdata
		# tbs NFG CVC header
		::asn::asnGetSequence cvcdata tbsdata
		#version \x02\x01\x02
		::asn::asnGetContext tbsdata contextNumber version
		# Serial Number
		::asn::asnRetag tbsdata 4
		::asn::asnGetOctetString tbsdata serial
		binary scan $serial H* serial
		set serial [string toupper $serial]
		set serial [regsub -all {..} $serial {& }]
		append cvcinfo "\n Serial Number: $serial\n"		
		#Signature
		#oid 1.2.840.113549.1.1.5
		::asn::asnGetSequence tbsdata data
		::asn::asnGetObjectIdentifier data oid
		#Issuer SEQUENCE
		# puts "Issuer:"
		append cvcinfo " Issuer:\n"
		::asn::asnGetSequence tbsdata Issuer
		while {[string length $Issuer]>0} {
			append cvcinfo [get_attribute Issuer]\n
		}
		# UTC Time
		::asn::asnGetSequence tbsdata data	
		::asn::asnGetUTCTime data utc_var1
		::asn::asnGetUTCTime data utc_var2	
		# puts "Validity:"
		append cvcinfo " Validity\n"
		# puts $utc_var1
		# puts $utc_var2
		append cvcinfo [format_utc_time $utc_var1]\n
		append cvcinfo [format_utc_time $utc_var2]\n
		#Subject SEQUENCE
		::asn::asnGetSequence tbsdata subject
		# puts "Subject:"
		append cvcinfo " Subject:\n"
		while {[string length $subject]>0} {
			append cvcinfo [get_attribute subject]\n
		}
		::asn::asnGetSequence tbsdata PublicKeyInfo
		::asn::asnGetSequence PublicKeyInfo data
		::asn::asnGetObjectIdentifier data oid
		::asn::asnGetBitString PublicKeyInfo data
		set publickey [binary format B* $data]
		# binary scan $publickey H* zz
		# puts publickey=$zz
		set Extensions_OPTIONAL $tbsdata
		# binary scan $Extensions_OPTIONAL H* zz
		# puts  Extensions_OPTIONAL=$zz
		::asn::asnGetSequence cvcdata sign_seq
		::asn::asnGetObjectIdentifier sign_seq oid
		# puts oid=$oid
		::asn::asnGetBitString cvcdata data	
		set Signature_value [binary format B* $data]
		# binary scan $Signature_value H* zz
		# should be zero
		# puts leng=[string length $cvcdata]
		# return
	} err] {
		.cvc.log insert end "Get cvc info fail\n"
		.cvc.log insert end "err=$err\n"		
	}
	.cvc.log insert end $cvcinfo
	binary scan $::parse_cvc_raw H* hexdata	
	hexdump $hexdata ".cvc.fr.hex" "stdout"
}
