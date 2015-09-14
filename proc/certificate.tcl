if {![namespace exist asn]} {package require asn}
proc asn::asnGetGeneralizedTime {data_var utc_var} {
    upvar 1 $data_var data $utc_var utc
    asnGetByte data tag
    if {$tag != 0x18} {
        return -code error \
            [format "Expected UTCTime (0x18), but got %02x" $tag]
    }
    asnGetLength data length
    asnGetBytes data $length bytes
    # this should be ascii, make it explicit
    set bytes [encoding convertfrom ascii $bytes]
    binary scan $bytes a* utc
    return
}
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
			set cert_info [get_cert_info [::asn::asnSequence $cert]]
			lappend cert_list [list $cert_info [::asn::asnSequence $cert]]
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
    if {[string length $utc]==13} {
		if {[scan $utc %2d%2d%2d%2d%2d%2d Y M D h m s]!=6} {return}
		if {$Y>50} {
			incr Y 1900
		} else {
			incr Y 2000
		}
	} else {
		scan $utc %4d%2d%2d%2d%2d%2d Y M D h m s
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
      wm withdraw .cvc
      wm transient .cvc .
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
#========================================================
# name: parse_cvc_chain
# purpose: Decode cvc chain data and print info  to
#          new window
#========================================================
proc parse_cvc_chain {data} {
	set ::parse_cvc_raw $data
	catch {destroy .cvcchain}
	toplevel .cvcchain
      wm withdraw .cvcchain
      wm transient .cvcchain .
	wm title .cvcchain "CVC info"
	wm geometry .cvcchain 640x400
	wm resizable .cvcchain 0 0
	menu .cvcchain.mbar -tearoff 0
	.cvcchain configure -menu .cvcchain.mbar
	menu .cvcchain.mbar.file -tearoff 0
	.cvcchain.mbar add cascade -menu .cvcchain.mbar.file -label File
	.cvcchain.mbar.file add command -label "Dump" -command {
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
	pack [ttk::notebook .cvcchain.nb] -padx 10 -pady 10
	pack [text .cvcchain.log -width 75 -font {"Courier New" 10 {}}] -padx 10 -pady 10
	pack [frame .cvcchain.fr]
	pack [text  .cvcchain.fr.hex -width 75 -font {"Courier New" 10 {}}] -side left -fill both -expand 1
	pack [::ttk::scrollbar .cvcchain.fr.sv -orient vertical -command [list .cvcchain.fr.hex yview]] -fill y -expand 1
	.cvcchain.fr.hex configure -yscrollcommand [list .cvcchain.fr.sv set]
	autoscroll::autoscroll .cvcchain.fr.sv
	.cvcchain.nb add .cvcchain.log -text "Info"
	.cvcchain.nb add .cvcchain.fr -text "Hex dump"
	place_toplevel .cvcchain	50 -50
	# start get cvc information
	set cvcinfo ""
	if [catch {
		# MFG CVC header
		::asn::asnGetSequence data cvcdata
		::asn::asnGetObjectIdentifier cvcdata oid
#		puts oid=[join $oid .] ; #1.2.840.113549.1.7.2
		::asn::asnGetContext cvcdata contextNumber SignedData
#		puts contextNumber=$contextNumber
		::asn::asnGetSequence SignedData SignedData
		::asn::asnGetInteger SignedData ver
		::asn::asnGetSet SignedData set1
		::asn::asnGetSequence SignedData ContentInfo
		::asn::asnGetObjectIdentifier ContentInfo oid
		::asn::asnGetContext SignedData contextNumber certificates
		set cert_ind 0
		while {[string length $certificates] >0} {
			incr cert_ind
			::asn::asnGetSequence certificates cert
			::asn::asnGetSequence cert tbsdata
			::asn::asnGetContext tbsdata contextNumber version
			::asn::asnRetag tbsdata 4
			::asn::asnGetOctetString tbsdata serial
			binary scan $serial H* serial
			set serial [string toupper $serial]
			set serial [regsub -all {..} $serial {& }]
			append cvcinfo "Certficate $cert_ind\n"
			append cvcinfo " Serial Number: $serial\n"
			::asn::asnGetSequence tbsdata data
			::asn::asnGetObjectIdentifier data oid
			append cvcinfo " Issuer:\n"
			::asn::asnGetSequence tbsdata Issuer
			while {[string length $Issuer]>0} {
				append cvcinfo [get_attribute Issuer]\n
			}
			# UTC Time
			::asn::asnGetSequence tbsdata data
			set utc_var1 [gettime data]
			set utc_var2 [gettime data]
			append cvcinfo " Validity\n"
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
			set Extensions_OPTIONAL $tbsdata
			append cvcinfo "\n"
		}
		#::asn::asnGetContext SignedData contextNumber crl
		#::asn::asnGetSet SignedData signinfo
	} err] {
		.cvcchain.log insert end "Get cvc info fail\n"
		.cvcchain.log insert end "err=$err\n"
	}
	.cvcchain.log insert end $cvcinfo
	binary scan $::parse_cvc_raw H* hexdata
	hexdump $hexdata ".cvcchain.fr.hex" "stdout"
}

proc gettime {data_var} {
	upvar $data_var data
	::asn::asnPeekTag data tag_var tagtype_var constr_var
	switch $tag_var {
		"23" {
			::asn::asnGetUTCTime data utc_var
		}
		"24" {
			::asn::asnGetGeneralizedTime data utc_var
		}
	}
	return $utc_var
}

proc get_cert_info {cert} {
	set data $cert
	::asn::asnGetSequence data cvcdata
	::asn::asnGetSequence cvcdata tbsdata
	::asn::asnGetContext tbsdata contextNumber version
	# Serial Number
	::asn::asnRetag tbsdata 4
	::asn::asnGetOctetString tbsdata serial
	#Signature
	::asn::asnGetSequence tbsdata data
	::asn::asnGetObjectIdentifier data signAlg
	set signAlg [join $signAlg .]
	::asn::asnGetSequence tbsdata Issuer
	::asn::asnGetSequence tbsdata data
	::asn::asnGetSequence tbsdata subject
	while {[string length $subject]>0} {
		set ret [get_attribute subject]
		puts ret=$ret
		regexp {O\s+=\s+(.+)} $ret match org_name
	}
	switch $signAlg {
		"1.2.840.113549.1.1.5" {
			set pki legacy
		}
		"1.2.840.113549.1.1.11" {
			set pki new
		}
		"default" {
			set pki unknow
		}
	}
	if [regexp {^[A-F0-9]{8}$} $org_name] {
		set cert_type mso
	} elseif {$org_name == "CableLabs" } {
		set cert_type cvcca
	} else {
		set cert_type mfg
	}
	puts "pki=$pki cert_type=$cert_type"
	return [list $pki $cert_type]
			
}

proc PKCS7_deg {certlist} {
	set signdata ""
	append signdata [::asn::asnInteger 1]
	append signdata [::asn::asnSet]
	append signdata [::asn::asnSequence [::asn::asnObjectIdentifier [list 1 2 840 113549 1 7 1]]]
	set certs ""
	foreach cert $certlist {
		append certs $cert
	}
	append signdata [::asn::asnContextConstr 0 $certs]
	append signdata [::asn::asnSet]
	set signdata [::asn::asnSequence $signdata]
	set signdata [::asn::asnContextConstr 0 $signdata]
	set temp [::asn::asnObjectIdentifier [list 1 2 840 113549 1 7 2]]
	return [::asn::asnSequence $temp $signdata] 
}

