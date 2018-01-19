add wave \
{sim:/Engine/Engine_CLK } 
add wave \
{sim:/Engine/eRegRe } 
add wave \
{sim:/Engine/eRegIm } 
add wave \
{sim:/Engine/eMaxItr } 
add wave \
{sim:/Engine/GO } 
add wave \
{sim:/Engine/eRST_N } 
add wave \
{sim:/Engine/eDONE } 
add wave \
{sim:/Engine/ItrCounter } \
{sim:/Engine/NewIm } \
{sim:/Engine/NewRe } \
{sim:/Engine/OldIm } \
{sim:/Engine/OldRe } \
{sim:/Engine/state } 
force -freeze sim:/Engine/Engine_CLK 1 0, 0 {50 ps} -r 100
force -freeze sim:/Engine/eRST_N 0 0
force -freeze sim:/Engine/GO 0 0
force -freeze sim:/Engine/eMaxItr 16'h00ff 0
force -freeze sim:/Engine/eRegRe 32'h00f00000 0
force -freeze sim:/Engine/eRegIm 32'h00040000 0
run 110 ps
force -freeze sim:/Engine/eRST_N 1 0
run 200
force -freeze sim:/Engine/GO 1 0


