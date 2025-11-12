library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all;

entity registro_32x32 is
    generic (
        constant init_file : string := ""
    );
    port (
        clk    : in  std_logic;
        addr_1 : in std_logic_vector(4 downto 0);
        dout_1 : out std_logic_vector(31 downto 0);
        addr_2 : in std_logic_vector(4 downto 0);
        dout_2 : out std_logic_vector(31 downto 0);

        we_w   : in  std_logic;
        addr_w : in  std_logic_vector(4 downto 0);
        din_w  : in  std_logic_vector(31 downto 0)
    );
end entity registro_32x32;
architecture arch of registro_32x32 is
    type reg_type is array (31 downto 0) of std_logic_vector(31 downto 0);
    impure function init_reg return reg_type is 
    file reg_file : text;
    variable reg_data : reg_type := (others => (others => '0'));
    variable line_content : line;
    variable addr_index : integer := 0;
    variable valid : boolean;
    variable status : file_open_status;
    begin
        file_open(status, reg_file, init_file, read_mode);
        if status = open_ok then
            while not endfile(reg_file) loop
                readline(reg_file, line_content);
                hread(line_content, reg_data(addr_index), valid);
                if valid then
                    addr_index := addr_index + 1;
                end if ;
            end loop ;
        end if ;
        return reg_data;
    end function init_reg;
    
    signal reg : reg_type := init_reg;

    begin
        dout_1 <= reg(to_integer(unsigned(addr_1)));
        dout_2 <= reg(to_integer(unsigned(addr_2)));

        process(clk)
        begin
            if rising_edge(clk) then
                if we_w = '1' and to_integer(unsigned(addr_w)) /= 0 then
                    reg(to_integer(unsigned(addr_w))) <= din_w;
                end if ;
                if to_integer(unsigned(addr_w)) = 0 then
                    reg(0) <= (others => '0');
                end if ;
            end if ;
        end process;
end arch;
