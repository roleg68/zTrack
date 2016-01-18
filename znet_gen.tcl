# zn_LibraryList [zn_GetNetlist]



# set dd  [ zn_SearchModule [zn_GetNetlist] my_tb ]

# zm_GetName [ zn_GetTop [zn_GetNetlist] ] 

# zn_SetTop [zn_GetNetlist]  $dd


# db1 eval {CREATE TABLE t1( module text , myxcy int)}

# db1 eval {INSERT INTO t1 VALUES('hello' , 1 ) }
# db1 eval {SELECT myxcy FROM t1 ORDER BY module } {
#     puts " myxcy=$myxcy"
# }



# set iii = [ zm_InstanceList [ zn_SearchModule [zn_GetNetlist] my_tb ] ]
# lindex $iii 1


# lindex [ zm_InstanceList [ zn_SearchModule [zn_GetNetlist] my_tb ] ]   1


# set dut_mid [ zn_SearchModule [zn_GetNetlist]  dut  ]
# zm_InstanceNameList $dut_mid

# # netlist  # zn_LibraryList       # list of librarys  # <netlist obj> 
# # library  # zl_ModuleList        # list of modules   # <library obj> 
# # module   # zm_GetOwner          # library           # <module obj> 

# zn_SearchModule [zn_GetNetlist] counter1
# zm_InstanceList [zn_SearchModule [zn_GetNetlist] muxcy ] 


# zn_GetLibraryNumber  [zn_GetNetlist]

# zn_LibraryNameList  [zn_GetNetlist]

# foreach zn_LibraryList [zn_GetNetlist]

# zm_IsXilinx [ zx_OR5 ]
puts "--------------------------------"



set nzlinx_prim 0

proc append_to_unkown_xilinx_primitive { db_name module_prop_table  m_id ref_m_id } {

    append unkown_xilinx_primitive "$module_prop_table" "_unkown_xilinx_primitive"    
 
    append module_prop_table_util "$module_prop_table" "_util" 

#    $db_name eval " CREATE TABLE $unkown_xilinx_primitive ( module text , ref_module text )"



    if {  [ zm_IsXilinx $m_id] == 1 } { 

	set mod_name  [ zm_GetName $m_id ]
	set ref_mode_nmae [ zm_GetName $ref_m_id   ] 

	set sl " SELECT module FROM $module_prop_table_util where ( (module='$mod_name') and   (lib='xcve') and (flops==0) and (latches=0) and (luts=0) and (muxes=0) and (gates=0) and (clocks=0) and  (ramluts=0) and (mems=0) and (iosys=0) and (sys=0) and (dsps=0) and (pwr=0) and (gnd=0));"
	
	#puts " $mod_name $ref_mode_nmae"

  	$db_name eval $sl  module_l {
	    $db_name eval "INSERT INTO $unkown_xilinx_primitive VALUES('$mod_name','$ref_mode_nmae')"

	   #puts " $mod_name $ref_mode_nmae"
  	}
	
    } else { 
	
	foreach  inst_i [ zm_InstanceList $m_id] {
	    
	    set sub_module_id [ zi_GetModule $inst_i ]
	    set sub_mod_name  [ zm_GetName $sub_module_id ]
	    set sub_mod_inst_name  [ zi_GetName $inst_i ]
	    set sub_mod_lib_name  [ zl_GetName  [zm_GetOwner $sub_module_id ] ]
	    set obj_id  [ zi_GetObjectId $inst_i ]
	    
	    
	    append_to_unkown_xilinx_primitive $db_name $module_prop_table $sub_module_id $m_id
	}
    }
    
}

proc create_util_con_tables { db_name module_prop_table } { ##module_inst_table
    global nzlinx_prim
    
    append module_prop_table_con "$module_prop_table" "_con" 
    append module_prop_table_util "$module_prop_table" "_util" 
   
    $db_name eval " CREATE TABLE $module_prop_table_util ( module text , lib text , flops int, latches int,luts  int,muxes int,gates  int,clocks int,ramluts int,mems int,iosys int,sys  int,dsps int, pwr int, gnd int, CONSTRAINT lib_module_unique UNIQUE (  module, lib  ) ON CONFLICT ABORT  )"
  
    $db_name eval " CREATE TABLE $module_prop_table_con ( module text , lib text , inBits int, outBits int, inoutBits int, clocks int , resets int, CONSTRAINT lib_module_unique UNIQUE (  module, lib  ) ON CONFLICT ABORT  )"

    #array set pattr ""

    $db_name eval "INSERT INTO $module_prop_table_util VALUES('DUMMY_TEMPLATE_','DUMMY_TEMPLATE_', 0,0,0,0,0,0,0,0,0,0,0,0,0)"
    $db_name eval "INSERT INTO $module_prop_table_con VALUES('DUMMY_TEMPLATE_','DUMMY_TEMPLATE_', 0,0,0,0,0)"
    
    
    puts "Working for the table, int \:  $module_prop_table"

    cost_from_alex $db_name "$module_prop_table_util"

    #puts $rr 
    puts "Working for the table\:  $module_prop_table"


    #return 
    foreach lid [zn_LibraryList [zn_GetNetlist] ] {
	foreach m_id [ zl_ModuleList $lid ] {
	    #puts [ zm_GetName $m_id ]
	    #puts [ zm_IsXilinx $m_id] 
	    
	    set module_name  [ zm_GetName $m_id ]
	    set lib_name  [ zl_GetName  [zm_GetOwner $m_id ] ]

	    ## Fill connectivity table

	    # init to zeros
	    $db_name eval "SELECT * FROM $module_prop_table_con WHERE module='DUMMY_TEMPLATE_' AND lib='DUMMY_TEMPLATE_';" pconn {  }

	    foreach pvector [ zm_PortList $m_id ] {
		
		set pname [ zp_GetName $pvector ]
		#set pType [ zp_GetType  $pvector] \#\#\module 
		
		if { [ zp_IsIn  $pvector ]  == 1 } {
		    incr pconn(inBits) 1;
		} 
		if { [ zp_IsOut  $pvector ]  == 1 } {
		    incr pconn(outBits) 1; 
		} 	
		if { [ zp_IsInOut $pvector ]  == 1 } {
		    incr pconn(inoutBits) 1; 
		} 	
		
	    }

	    $db_name eval "INSERT INTO $module_prop_table_con VALUES('$module_name','$lib_name',$pconn(inBits),$pconn(outBits),$pconn(inoutBits),$pconn(clocks),$pconn(resets));"

	    ## Fill utlization table
	    array set x {} ;unset x ;array set x {};
	    get_prop_row $db_name  "$module_prop_table_util"  $m_id
	    
	}
    }
    

    set nrows   [ $db_name eval " SELECT COUNT(*) FROM $module_prop_table_util ; " ]
    puts " NROWS $nrows "

    #$db_name eval "DROP TABLE $module_prop_table"
    
}
# get the prop row, create it if not exist, recurcive 

proc get_prop_row { db_name module_prop_table  m_id   } { 

    set module_name  [ zm_GetName $m_id ]
    set lib_name  [ zl_GetName  [zm_GetOwner $m_id ] ]

    ## check the module exist 
    $db_name eval "SELECT * FROM $module_prop_table WHERE module='$module_name' AND lib='$lib_name';"   pvalues {
	#parray pvalues
	#puts ""
    }
    if {[array size pvalues] > 1 } { 
	#puts "exist in table, return row "
	
    } else {
	
	#parray pvalues
	#puts [array size pvalues]

	## init pattr to the default values 
	$db_name eval " SELECT * FROM $module_prop_table WHERE module='DUMMY_TEMPLATE_' AND lib='DUMMY_TEMPLATE_';" pattr {  }

	#puts " EMPTY "
	if {  [ zm_IsXilinx $m_id] == 1 } { 
	    ## puts " TODO ------ zm_IsXilinx  $module_name  $lib_name TODO get cost " 
	    
	    ## $db_name eval "INSERT INTO $module_prop_table  VALUES('$module_name','$lib_name', 0,0,0,0,0,0,0,0,0,0,0)"
	    
	} else {
	    foreach  inst_i [ zm_InstanceList $m_id] {

		set sub_module_id [ zi_GetModule $inst_i ]
		set sub_mod_name  [ zm_GetName $sub_module_id ]
		set sub_mod_inst_name  [ zi_GetName $inst_i ]
		set sub_mod_lib_name  [ zl_GetName  [zm_GetOwner $sub_module_id ] ]
		set obj_id  [ zi_GetObjectId $inst_i ]
		#puts "$obj_id  $sub_mod_name $sub_mod_inst_name"
		
		get_prop_row  $db_name $module_prop_table  $sub_module_id 

		# the selection can not be empty 
		$db_name eval "SELECT *  FROM $module_prop_table WHERE module='$sub_mod_name' AND lib='$sub_mod_lib_name';" sub_pvalues {
		    ## incr
		    foreach key [array names pattr] {
			
			if {[string is integer -strict $pattr($key)]} {
			    #puts " PARARRA   $pattr($key)  "
			    incr pattr($key)  $sub_pvalues($key);
			}
		    }
		    
		    #parray sub_pvalues
		    #puts ""
		    ###### incr  pvalues(myxcy) $sub_pvalues(myxcy)
		    #puts $sub_pvalues(myxcy)
		}
		# must exit 
		if { [array size sub_pvalues] < 2 } {error "ouch... too hot!"}
	    }
	}
	## add 
	## puts " INSERT INTO $module_prop_table VALUES('$module_name','$lib_name',$pvalues(myxcy))"
	### $db_name eval " INSERT INTO $module_prop_table VALUES('$module_name','$lib_name',$pvalues(myxcy))"

	set sqlCmd "INSERT INTO $module_prop_table  VALUES('$module_name','$lib_name',$pattr(flops),$pattr(latches),$pattr(luts),$pattr(muxes),$pattr(gates),$pattr(clocks),$pattr(ramluts),$pattr(mems),$pattr(iosys),$pattr(sys),$pattr(dsps),$pattr(pwr),$pattr(gnd))"
	
	#puts $sqlCmd
	
	$db_name eval  $sqlCmd
	
    } 
}



proc count_lines { db_name module_prop_table } {
    set nrow_intable  [ $db_name eval " SELECT COUNT(*) FROM $module_prop_table ; " ]
    
    for {set i 0} {$i < $nrow_intable} {incr i} {
	
	$db_name eval "SELECT * FROM $module_prop_table WHERE module='hello' AND lib='hello';"
    }      
}


proc sdsd  { } {
    set dut_mid [ zn_SearchModule [zn_GetNetlist]  dut  ]
    foreach p [zm_PortList $dut_mid  ] {
	foreach attr [ zp_AttributeNameList $p ] {
	    puts $attr
	}
    }
} 

proc delete_all_tables { db_name } { 

    set tables_name {}

    $db_name eval "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name;" tables {
	
	lappend tables_name $tables(name)
    }
    
    foreach t  $tables_name  {
	#puts $t
	puts "DROP TABLE $t "
	$db_name eval "DROP TABLE $t;"
	
    }

    
}




#################################

proc cost_from_alex { db_name table_name } { 
 array set COST_FUNC ""

set COST_FUNC(fd)     [list flops 1]; 
set COST_FUNC(fd_1)   [list flops 1]; 
set COST_FUNC(fde)    [list flops 1]; 
set COST_FUNC(fde_1)  [list flops 1]; 
set COST_FUNC(fds)    [list flops 1]; 
set COST_FUNC(fds_1)  [list flops 1]; 
set COST_FUNC(fdse)   [list flops 1]; 
set COST_FUNC(fdse_1) [list flops 1]; 
set COST_FUNC(fdc)    [list flops 1]; 
set COST_FUNC(fdc_1)  [list flops 1]; 
set COST_FUNC(fdce)   [list flops 1]; 
set COST_FUNC(fdce_1) [list flops 1]; 
set COST_FUNC(fdcpe)  [list flops 1]; 
set COST_FUNC(fdcp)   [list flops 1];
set COST_FUNC(fdcp_1) [list flops 1];
set COST_FUNC(fdr)    [list flops 1];
set COST_FUNC(fdr_1)  [list flops 1];
set COST_FUNC(fdrs)   [list flops 1];
set COST_FUNC(fdrs_1) [list flops 1];
set COST_FUNC(fdre)   [list flops 1];
set COST_FUNC(fdre_1) [list flops 1];
set COST_FUNC(fdp)    [list flops 1];
set COST_FUNC(fdp_1)  [list flops 1];
set COST_FUNC(fdpe)   [list flops 1];
set COST_FUNC(fdpe_1) [list flops 1];
set COST_FUNC(fdcpe_1) [list flops 1];

set COST_FUNC(ld)     [list latches 1]; 
set COST_FUNC(ld_1)   [list latches 1]; 
set COST_FUNC(lde)    [list latches 1];
set COST_FUNC(lde_1)  [list latches 1];

set COST_FUNC(lut1)     [list luts 1]; 
set COST_FUNC(lut2)    [list luts 1];
set COST_FUNC(lut3)     [list luts 1]; 
set COST_FUNC(lut4)    [list luts 1];
set COST_FUNC(lut5)     [list luts 1]; 
set COST_FUNC(lut6)    [list luts 1];
set COST_FUNC(lut6_2)   [list luts 1]; 
set COST_FUNC(srl16e)   [list luts 1]; 
set COST_FUNC(srlc32e)  [list luts 1]; 
set COST_FUNC(srlc16e) [list luts 1];
set COST_FUNC(srl16e)  [list luts 1];

set COST_FUNC(ram256x1s) [list ramluts 4];
set COST_FUNC(ram256x1d) [list ramluts 4];
set COST_FUNC(ram128x1s) [list ramluts 2];
set COST_FUNC(ram128x1d) [list ramluts 2];
set COST_FUNC(ram64x1s)  [list ramluts 1];
set COST_FUNC(ram64x1d)  [list ramluts 1];
set COST_FUNC(ram32x1s)  [list ramluts 1];

set COST_FUNC(inv)  [list gates 1];
set COST_FUNC(or2)  [list gates 1];
set COST_FUNC(or3)  [list gates 1];
set COST_FUNC(or4)  [list gates 1];
set COST_FUNC(or5)  [list gates 1];
set COST_FUNC(nor2) [list gates 1];
set COST_FUNC(nor3) [list gates 1];
set COST_FUNC(nor4) [list gates 1];
set COST_FUNC(nor5) [list gates 1];
set COST_FUNC(xor2)  [list gates 1];
set COST_FUNC(xor3) [list gates 1];
set COST_FUNC(xor4)  [list gates 1];
set COST_FUNC(xor5) [list gates 1]; 
set COST_FUNC(xnor2)  [list gates 1];
set COST_FUNC(xnor3)  [list gates 1];
set COST_FUNC(xnor4)  [list gates 1];
set COST_FUNC(xnor5)  [list gates 1];
set COST_FUNC(and2)  [list gates 1];
set COST_FUNC(and3)  [list gates 1];
set COST_FUNC(and4)  [list gates 1];
set COST_FUNC(and5)  [list gates 1];
set COST_FUNC(and2b1)  [list gates 1];

set COST_FUNC(xorcy)   [list muxes 1]; set COST_FUNC(muxcy) [list muxes 1]; 
set COST_FUNC(muxcy_l) [list muxes 1]; set COST_FUNC(muxf7) [list muxes 1]; 
set COST_FUNC(muxf8)   [list muxes 1]; 

set COST_FUNC(vcc)        [list pwr  1]; set COST_FUNC(gnd)       [list pwr  1];

set COST_FUNC(ramb36_exp) [list mems 1]; 
set COST_FUNC(ramb36sdp)  [list mems 1]; 
set COST_FUNC(ramb36)  [list mems 1]; 

set COST_FUNC(dsp48e)     [list dsps 1];

set COST_FUNC(bufg)     [list clocks 1]; 
set COST_FUNC(bufgctrl)     [list clocks 1];

set COST_FUNC(oserdes)    [list iosys 1]; 
set COST_FUNC(oddr)       [list iosys 1]; 
set COST_FUNC(idelayctrl) [list iosys 1]; 
set COST_FUNC(bufr)       [list iosys 1]; 
set COST_FUNC(buft)       [list iosys 1]; 
set COST_FUNC(ibuf)       [list iosys 1]; 
set COST_FUNC(obuf)       [list iosys 1]; 
set COST_FUNC(iserdes) [list iosys 1];
set COST_FUNC(iodelay) [list iosys 1];
set COST_FUNC(buf)     [list iosys 1];
set COST_FUNC(bufio)   [list iosys 1];
set COST_FUNC(ibufds)  [list iosys 1];
set COST_FUNC(obufds)  [list iosys 1];

set COST_FUNC(pll_adv)    [list sys 1]; set COST_FUNC(startup_virtex5)  [list sys 1];
set COST_FUNC(sysmon)     [list sys 1]; 

    
  foreach idx [array names COST_FUNC] {
     
      #reset pattr to zero
      $db_name eval " SELECT * FROM $table_name WHERE module='DUMMY_TEMPLATE_' AND lib='DUMMY_TEMPLATE_';" pattr {  }
   
    
      set pname [ lindex $COST_FUNC($idx) 0 ]
      
      set pname_val [ lindex $COST_FUNC($idx) 1 ]
      
      set pattr($pname) $pname_val
      
      #puts " $idx $pname = $pattr($pname)"

      set sqlCmd "INSERT INTO $table_name  VALUES('$idx','xcve',$pattr(flops),$pattr(latches),$pattr(luts),$pattr(muxes),$pattr(gates),$pattr(clocks),$pattr(ramluts),$pattr(mems),$pattr(iosys),$pattr(sys),$pattr(dsps),$pattr(pwr),$pattr(gnd))"

      $db_name eval $sqlCmd
      #puts $sqlCmd
    
  }
  set nrows   [ $db_name eval " SELECT COUNT(*) FROM $table_name ; " ]
  puts "$table_name  : NROWS $nrows "
} 



#tmp_print_ports "dut"

## 
# source ../../../../../../znet_gen.tcl



# puts [ time { count_lines d }  ]
#array set x {}
#unset x ;array set x {}
#parray x 
#get_prop_row_2  dddd   'hello' 'helsslo'  x
# parray x


### ../tools/zTopBuild/global_ztb_my_tb.edf.gz 
## delete_all_tables 

## .mode csv 
##-- use '.separator SOME_STRING' for something other than a comma.
##.headers on 
##.out file.dmp 
##select * from ;

#.header on
#.mode csv
## -- use '.separator SOME_STRING' for something other than a comma.
#.separator ","
#.out file1.csv
# SELECT * FROM d WHERE lib='xcve';


# edif2db $db_name /tmp/ggg.db

proc aa { db_name module_prop_table top_name } { 

    puts "$db_name  $module_prop_table $top_name"

    set mid [ zn_SearchModule [zn_GetNetlist] $top_name ]
    
    append unkown_xilinx_primitive "$module_prop_table" "_unkown_xilinx_primitive"  

    $db_name eval " CREATE TABLE $unkown_xilinx_primitive ( module text , ref_module text )"

    append_to_unkown_xilinx_primitive $db_name $module_prop_table  $mid $mid
    
} 

proc edif2db  {   db_name db_path table_name} { 
    
    load /remote/vgscratch02/oraikhm/test/sqlite-autoconf-3100000/libtclsqlite3.so
    package require sqlite3
    
    sqlite3 $db_name $db_path

    $db_name eval { BEGIN TRANSACTION }

    puts [  time { create_util_con_tables $db_name  $table_name }  ] 

    aa  $db_name  $table_name [ zm_GetName [ zn_GetTop [zn_GetNetlist] ]  ]

    $db_name eval { END TRANSACTION }

    $db_name close
}

#   read_edif $edif_path 
#    merge 
# source ../../../../../../znet_gen.tcl


# 
# read_edif  zTopBuild_equi.edf.gz
# merge 
