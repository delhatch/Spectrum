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


