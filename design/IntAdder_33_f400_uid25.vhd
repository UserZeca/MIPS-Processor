library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity IntAdder_33_f400_uid25 is
    port ( X : in  std_logic_vector(32 downto 0);
           Y : in  std_logic_vector(32 downto 0);
           Cin : in  std_logic;
           R : out  std_logic_vector(32 downto 0)   );
end entity;

architecture arch of IntAdder_33_f400_uid25 is
begin
    --Classical
     R <= X + Y + Cin;
end architecture;