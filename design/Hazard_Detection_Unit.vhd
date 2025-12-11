library ieee;
use ieee.std_logic_1164.all;

entity Hazard_Detection_Unit is
    port (
        -- Para detectar Load-Use
        ID_EX_MemRead : in std_logic;
        ID_EX_Rt      : in std_logic_vector(4 downto 0);
        IF_ID_Rs      : in std_logic_vector(4 downto 0);
        IF_ID_Rt      : in std_logic_vector(4 downto 0);
        
        -- Para detectar Branch Taken (Vem do estágio MEM)
        Branch_Taken  : in std_logic;
        
        -- Saídas de Controle
        -- '1' = Habilita escrita (Normal), '0' = Trava (Stall)
        PC_Write      : out std_logic;
        IF_ID_Write   : out std_logic;
        
        -- '1' = Zera o registrador (Flush/Bolha)
        IF_ID_Flush   : out std_logic;
        ID_EX_Flush   : out std_logic;
        EX_MEM_Flush  : out std_logic
    );
end entity Hazard_Detection_Unit;

architecture Behavioral of Hazard_Detection_Unit is
begin
    process(ID_EX_MemRead, ID_EX_Rt, IF_ID_Rs, IF_ID_Rt, Branch_Taken)
    begin
        -- Valores Padrão (Sem Hazard)
        PC_Write      <= '1'; -- PC anda normal
        IF_ID_Write   <= '1'; -- IF/ID atualiza normal
        
        IF_ID_Flush   <= '0';
        ID_EX_Flush   <= '0';
        EX_MEM_Flush  <= '0';

        -- ==========================================================
        -- 1. Detecção de BRANCH (Prioridade Máxima)
        -- ==========================================================
        if Branch_Taken = '1' then
            -- Se o branch foi tomado no estágio MEM, tudo o que veio
            -- depois dele (EX, ID, IF) é lixo e precisa ser jogado fora.
            IF_ID_Flush  <= '1';
            ID_EX_Flush  <= '1';
            EX_MEM_Flush <= '1'; -- Opcional, depende de onde o branch é resolvido
            
        -- ==========================================================
        -- 2. Detecção de LOAD-USE (Se não for Branch)
        -- ==========================================================
        elsif (ID_EX_MemRead = '1') then
            -- Se a instrução anterior é um Load...
            -- E o destino dela (Rt) é igual a algum operando da atual (Rs ou Rt)...
            if (ID_EX_Rt = IF_ID_Rs) or (ID_EX_Rt = IF_ID_Rt) then
                
                -- STALL: Travamos o PC e o IF/ID para eles repetirem a mesma instrução
                PC_Write    <= '0';
                IF_ID_Write <= '0';
                
                -- BUBBLE: Zeramos o ID/EX para que a instrução "Load" avance sozinha
                -- e abra espaço para o dado voltar da memória
                ID_EX_Flush <= '1';
                
            end if;
        end if;
        
    end process;
end architecture Behavioral;