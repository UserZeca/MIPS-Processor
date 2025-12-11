library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; -- Para fazer a soma (PC + 4)

entity Program_Counter is
    port (
        -- Entradas
        Clk         : in  std_logic; -- Clock global do processador
        Rst         : in  std_logic; -- Reset (para iniciar no endereço 0)
        
        -- Endereço de Desvio (vindo do datapath de branch/jump)
        Branch_Addr : in  std_logic_vector(31 downto 0);
        
        -- Sinal de Controle (da Unidade de Controle)
        -- '0' = Carregar PC + 4
        -- '1' = Carregar Branch_Addr
        PC_Sel      : in  std_logic; 
        
        -- Saída
        -- Endereço da instrução ATUAL (indo para a Memória de Instrução)
        PC_Out      : out std_logic_vector(31 downto 0)
    );
end entity Program_Counter;

architecture Behavioral of Program_Counter is

    -- Sinal interno que armazena o valor ATUAL do PC
    signal s_PC : std_logic_vector(31 downto 0) := (others => '0');
    
    -- Sinal interno que calcula o PRÓXIMO valor do PC
    signal s_PC_Next : std_logic_vector(31 downto 0);

begin

    -- === 1. Lógica Combinacional: Calcular o PRÓXIMO PC ===
    --    Calculamos o incremento padrão (PC + 4)
    with PC_Sel select
        s_PC_Next <= std_logic_vector(signed(s_PC) + 4) when '0', -- PC + 4
                     Branch_Addr                     when '1', -- Endereço de Desvio
                     (others => 'X')                 when others;

    -- === 2. Lógica Sequencial: Atualizar o PC ===
    --    Este é o registrador. Na borda de subida do clock,
    --    o PC atual (s_PC) recebe o valor do próximo PC (s_PC_Next).
    process(Clk)
    begin
        if rising_edge(Clk) then
            if Rst = '1' then
                -- Se o Reset estiver ativo, força o PC para o endereço 0
                s_PC <= x"00000000";
            else
                -- Em um ciclo normal, apenas carrega o próximo valor
                s_PC <= s_PC_Next;
            end if;
        end if;
    end process;

    -- === 3. Saída ===
    -- A saída (PC_Out) é o valor ATUAL armazenado no registrador
    PC_Out <= s_PC;

end architecture Behavioral;