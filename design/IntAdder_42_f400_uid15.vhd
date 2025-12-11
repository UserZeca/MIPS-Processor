library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity IntAdder_42_f400_uid15 is
    port ( X : in  std_logic_vector(41 downto 0);
           Y : in  std_logic_vector(41 downto 0);
           Cin : in  std_logic;
           R : out  std_logic_vector(41 downto 0)   );
end entity;

architecture arch of IntAdder_42_f400_uid15 is
begin
    --Classical
     R <= X + Y + Cin;
end architecture;