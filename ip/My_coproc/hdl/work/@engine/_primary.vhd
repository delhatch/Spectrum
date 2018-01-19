library verilog;
use verilog.vl_types.all;
entity Engine is
    port(
        eRegRe          : in     vl_logic_vector(31 downto 0);
        eRegIm          : in     vl_logic_vector(31 downto 0);
        eMaxItr         : in     vl_logic_vector(15 downto 0);
        GO              : in     vl_logic;
        eRST_N          : in     vl_logic;
        Engine_CLK      : in     vl_logic;
        ItrCounter      : out    vl_logic_vector(15 downto 0);
        eDONE           : out    vl_logic
    );
end Engine;
