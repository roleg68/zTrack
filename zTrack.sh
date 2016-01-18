set edifs_list = "./zcui.work_moyo/backend_default/tools/zDB/zTopBuild_equi.edf.gz" 


#set edifs_list = "./zcui.work_moyo/backend_default/U0/M0/F00.Original/fpga.edf.gz"


set dbpath = /tmp/ggg.db

set table = phase_1

foreach edif( ${edifs_list}  ) 


echo "Read netlist"

#set edif = zTopBuild_equi.edf.gz

rm -fr  $dbpath 


cat << EOF | zNetgen

read_edif  $edif
merge 
source $HOME/znet_gen.tcl
edif2db db1 $dbpath ${table}
EOF


echo "dump tables"

#SELECT name FROM sqlite_master WHERE type='table' ORDER BY name;
cat << EOF | sqlite3 $dbpath 
.header on
.mode csv
.separator ","
.out modules_con.csv
SELECT * FROM ${table}_con ;
.out util_xilinx_prim.csv
SELECT module FROM ${table}_util where ((lib='xcve') and (flops==0) and (latches=0) and (luts=0) and (muxes=0) and (gates=0) and (clocks=0) and  (ramluts=0) and (mems=0) and (iosys=0) and (sys=0) and (dsps=0) and (pwr=0) and (gnd=0) );
.out unkown_xilinx_primitive_table.csv
SELECT DISTINCT module FROM ${table}_unkown_xilinx_primitive;
.exit
EOF

end

#
#SELECT name FROM sqlite_master WHERE type='table' ORDER BY name;


