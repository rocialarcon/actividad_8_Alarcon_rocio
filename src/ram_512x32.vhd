library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all;

entity ram_512x32 is
    generic (
        constant init_file : string := ""
    );
    port (
        clk     : in  std_logic;
        --Puerto A lectura
        addr_r : in std_logic_vector(8 downto 0);
        dout_r : out std_logic_vector(31 downto 0);
        --puerto b escritura
        we_w      : in  std_logic;
        addr_w    : in  std_logic_vector(8 downto 0);
        din_w     : in  std_logic_vector(31 downto 0);
        mask_w    : in std_logic_vector(3 downto 0)
    );
end entity ram_512x32;
architecture arch of ram_512x32 is
    type ram_type is array (511 downto 0) of std_logic_vector(31 downto 0);
    impure function init_ram return ram_type is
        file ram_file : text;
        variable ram_data : ram_type := (others => (others => '0'));
        variable line_content : line ;
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
                    end if ;
                end loop;   
            end if ;
        return ram_data;
        end function init_ram;
    signal ram : ram_type := init_ram;
    begin
    dout_r <= ram(to_integer(unsigned(addr_r)));
    --escritura con mascara
    process(clk)
        variable current_word : std_logic_vector(31 downto 0);
        begin
            if rising_edge(clk) then
                if we_w = '1' then
                    current_word := ram(to_integer(unsigned(addr_w)));
                    if mask_w(0) = '1' then
                        current_word(7 downto 0) := din_w(7 downto 0);
                    end if ;
                    if mask_w(1) = '1' then
                        current_word(15 downto 8) := din_w(15 downto 8);
                    end if ;
                    if mask_w(2) = '1' then
                        current_word(23 downto 16) := din_w(23 downto 16);
                    end if ;
                    if mask_w(3) ='1' then
                        current_word(31 downto 24) := din_w(31 downto 24);
                    end if ;
                    ram(to_integer(unsigned(addr_w))) <= current_word;
                end if ;
            end if ;
        end process;
end architecture arch;