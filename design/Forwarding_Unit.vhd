library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Forwarding_Unit is
    port (
        -- Endereços do estágio EX (Quem precisa do dado?)
        Rs_EX : in std_logic_vector(4 downto 0);
        Rt_EX : in std_logic_vector(4 downto 0);
        
        -- Endereços e Controles dos estágios posteriores (Quem tem o dado?)
        Rd_MEM       : in std_logic_vector(4 downto 0);
        RegWrite_MEM : in std_logic;
        
        Rd_WB        : in std_logic_vector(4 downto 0);
        RegWrite_WB  : in std_logic;
        
        -- Seletores para os MUXes de Forwarding
        -- 00: Original (ID/EX)
        -- 10: Adiantamento do MEM (EX/MEM)
        -- 01: Adiantamento do WB (MEM/WB)
        ForwardA : out std_logic_vector(1 downto 0);
        ForwardB : out std_logic_vector(1 downto 0)
    );
end entity Forwarding_Unit;

architecture Behavioral of Forwarding_Unit is
begin
    process(Rs_EX, Rt_EX, Rd_MEM, RegWrite_MEM, Rd_WB, RegWrite_WB)
    begin
        -- Inicializa com '00' (Sem Forwarding)
        ForwardA <= "00";
        ForwardB <= "00";

        -- ==============================================================
        -- Lógica para ForwardA (Entrada A da ALU - baseada em Rs)
        -- ==============================================================
        
        -- Hazard EX (Prioridade Alta): O dado está no estágio MEM vizinho
        if (RegWrite_MEM = '1' and Rd_MEM /= "00000" and Rd_MEM = Rs_EX) then
            ForwardA <= "10";
            
        -- Hazard MEM (Prioridade Baixa): O dado está no estágio WB
        -- Só fazemos isso se NÃO houver um hazard EX (o dado mais recente ganha)
        elsif (RegWrite_WB = '1' and Rd_WB /= "00000" and Rd_WB = Rs_EX) then
            ForwardA <= "01";
        end if;

        -- ==============================================================
        -- Lógica para ForwardB (Entrada B da ALU - baseada em Rt)
        -- ==============================================================
        
        if (RegWrite_MEM = '1' and Rd_MEM /= "00000" and Rd_MEM = Rt_EX) then
            ForwardB <= "10";
            
        elsif (RegWrite_WB = '1' and Rd_WB /= "00000" and Rd_WB = Rt_EX) then
            ForwardB <= "01";
        end if;
        
    end process;
end architecture Behavioral;