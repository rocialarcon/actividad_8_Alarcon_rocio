library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all;

entity ram_512x8 is
    generic (
        constant init_file : string := ""
    );
    port (
        clk     : in  std_logic;
        we      : in  std_logic;
        addr    : in  std_logic_vector(8 downto 0);
        din     : in  std_logic_vector(7 downto 0);
        dout    : out std_logic_vector(7 downto 0)
    );
end entity ram_512x8;

architecture behavioral of ram_512x8 is
    type ram_type is array (511 downto 0) of std_logic_vector(7 downto 0);

    impure function init_ram return ram_type is
        file ram_file : text;
        variable ram_data : ram_type := (others => (others => '0'));
        variable line_content : line;
        variable addr_index : integer := 0;
        variable valid : boolean;
        variable status : file_open_status;
    begin
        file_open(status, ram_file, init_file, read_mode);
        if status = open_ok then
            while not endfile(ram_file) loop
                readline(ram_file, line_content);
                hread(line_content, ram_data(addr_index), valid);
                if valid then
                    addr_index := addr_index + 1;
                end if;
            end loop;
        end if;
        return ram_data;
    end function init_ram;

    signal ram : ram_type := init_ram;
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if we = '1' then
                ram(to_integer(unsigned(addr))) <= din;
            end if;
            dout <= ram(to_integer(unsigned(addr)));
        end if;
    end process;
end architecture behavioral;