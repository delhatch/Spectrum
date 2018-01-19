# TCL File Generated by Component Editor 17.1
# Sat Nov 18 15:02:43 PST 2017
# DO NOT MODIFY


# 
# Coproc_Top "Coproc_Top" v1.0
#  2017.11.18.15:02:43
# 
# 

# 
# request TCL package from ACDS 16.1
# 
package require -exact qsys 16.1


# 
# module Coproc_Top
# 
set_module_property DESCRIPTION ""
set_module_property NAME Coproc_Top
set_module_property VERSION 1.0
set_module_property INTERNAL false
set_module_property OPAQUE_ADDRESS_MAP true
set_module_property AUTHOR ""
set_module_property DISPLAY_NAME Coproc_Top
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE true
set_module_property REPORT_TO_TALKBACK false
set_module_property ALLOW_GREYBOX_GENERATION false
set_module_property REPORT_HIERARCHY false


# 
# file sets
# 
add_fileset QUARTUS_SYNTH QUARTUS_SYNTH "" ""
set_fileset_property QUARTUS_SYNTH TOP_LEVEL Coproc_Top
set_fileset_property QUARTUS_SYNTH ENABLE_RELATIVE_INCLUDE_PATHS false
set_fileset_property QUARTUS_SYNTH ENABLE_FILE_OVERWRITE_MODE false
add_fileset_file Coproc_Top.v VERILOG PATH ip/My_coproc/hdl/Coproc_Top.v TOP_LEVEL_FILE


# 
# parameters
# 


# 
# display items
# 


# 
# connection point s1
# 
add_interface s1 avalon end
set_interface_property s1 addressUnits WORDS
set_interface_property s1 associatedClock clock
set_interface_property s1 associatedReset reset
set_interface_property s1 bitsPerSymbol 8
set_interface_property s1 burstOnBurstBoundariesOnly false
set_interface_property s1 burstcountUnits WORDS
set_interface_property s1 explicitAddressSpan 2048
set_interface_property s1 holdTime 0
set_interface_property s1 linewrapBursts false
set_interface_property s1 maximumPendingReadTransactions 0
set_interface_property s1 maximumPendingWriteTransactions 0
set_interface_property s1 readLatency 0
set_interface_property s1 readWaitTime 1
set_interface_property s1 setupTime 0
set_interface_property s1 timingUnits Cycles
set_interface_property s1 writeWaitTime 0
set_interface_property s1 ENABLED true
set_interface_property s1 EXPORT_OF ""
set_interface_property s1 PORT_NAME_MAP ""
set_interface_property s1 CMSIS_SVD_VARIABLES ""
set_interface_property s1 SVD_ADDRESS_GROUP ""

add_interface_port s1 avs_s1_readdata_oDATA readdata Output 32
add_interface_port s1 avs_s1_address_iADDR address Input 9
add_interface_port s1 avs_s1_read_iRD read Input 1
add_interface_port s1 avs_s1_chipselect_iCS chipselect Input 1
set_interface_assignment s1 embeddedsw.configuration.isFlash 0
set_interface_assignment s1 embeddedsw.configuration.isMemoryDevice 0
set_interface_assignment s1 embeddedsw.configuration.isNonVolatileStorage 0
set_interface_assignment s1 embeddedsw.configuration.isPrintableDevice 0


# 
# connection point reset
# 
add_interface reset reset end
set_interface_property reset associatedClock clock
set_interface_property reset synchronousEdges DEASSERT
set_interface_property reset ENABLED true
set_interface_property reset EXPORT_OF ""
set_interface_property reset PORT_NAME_MAP ""
set_interface_property reset CMSIS_SVD_VARIABLES ""
set_interface_property reset SVD_ADDRESS_GROUP ""

add_interface_port reset rsi_reset_n reset_n Input 1


# 
# connection point clock
# 
add_interface clock clock end
set_interface_property clock clockRate 0
set_interface_property clock ENABLED true
set_interface_property clock EXPORT_OF ""
set_interface_property clock PORT_NAME_MAP ""
set_interface_property clock CMSIS_SVD_VARIABLES ""
set_interface_property clock SVD_ADDRESS_GROUP ""

add_interface_port clock csi_clk clk Input 1


# 
# connection point export_s2
# 
add_interface export_s2 conduit end
set_interface_property export_s2 associatedClock ""
set_interface_property export_s2 associatedReset ""
set_interface_property export_s2 ENABLED true
set_interface_property export_s2 EXPORT_OF ""
set_interface_property export_s2 PORT_NAME_MAP ""
set_interface_property export_s2 CMSIS_SVD_VARIABLES ""
set_interface_property export_s2 SVD_ADDRESS_GROUP ""

add_interface_port export_s2 avs_s2_export_adcdata export_adcdata Input 1
add_interface_port export_s2 avs_s2_export_adclrc export_adclrc Input 1
add_interface_port export_s2 avs_s2_export_bclk export_bclk Input 1
add_interface_port export_s2 avs_s2_export_fft_clk export_fft_clk Input 1
add_interface_port export_s2 avs_s2_export_debug export_debug Output 10
