library ieee;
use ieee.std_logic_1164.all;

entity deco_hexa is
    port(
        D : in std_logic_vector (3 downto 0);
        S : out std_logic_vector (6 downto 0) --Sg a Sa
    );
end deco_hexa;

architecture arch of deco_hexa is
begin
    with D select S <=
    "0111111" when "0000",--0
    "0000110" when "0001",--1
    "1011011" when "0010",--2
    "1001111" when "0011",--3
    "1100110" when "0100",--4
    "1101101" when "0101",--5
    "1111101" when "0110",--6
    "0000111" when "0111",--7
    "1111111" when "1000",--8
    "1100111" when "1001",--9
    "1110111" when "1010",--A
    "1111100" when "1011",--b
    "0111001" when "1100",--C
    "1011110" when "1101",--d
    "1111001" when "1110",--E
    "1110001" when "1111",--F
    "0000000" when others; --todos apagados por defecto

end arch;