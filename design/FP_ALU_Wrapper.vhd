library ieee;
use ieee.std_logic_1164.all;

entity FP_ALU_Wrapper is
    port (
        -- Entradas padrão IEEE 754 (32 bits)
        X_in    : in  std_logic_vector(31 downto 0);
        Y_in    : in  std_logic_vector(31 downto 0);
        
        -- Seletor de Operação ('0' = ADD, '1' = MULT)
        Op_sel  : in  std_logic; 
        
        -- Saída padrão IEEE 754 (32 bits)
        R_out   : out std_logic_vector(31 downto 0)
    );
end entity FP_ALU_Wrapper;

architecture Structural of FP_ALU_Wrapper is

    -- 1. Declaração dos componentes que vamos instanciar
    
    -- Componente Somador (Wrapper de 32 bits)
    component FPAdd_32bit_Wrapper
        port (
            X_in  : in  std_logic_vector(31 downto 0);
            Y_in  : in  std_logic_vector(31 downto 0);
            R_out : out std_logic_vector(31 downto 0)
        );
    end component;

    -- Componente Multiplicador (Wrapper de 32 bits)
    component FPMult_32bit_Wrapper
        port (
            X_in  : in  std_logic_vector(31 downto 0);
            Y_in  : in  std_logic_vector(31 downto 0);
            R_out : out std_logic_vector(31 downto 0)
        );
    end component;

    -- 2. Sinais internos para armazenar os resultados de CADA operação
    signal s_R_add    : std_logic_vector(31 downto 0);
    signal s_R_mult   : std_logic_vector(31 downto 0);

begin

    -- 3. Instanciar AMBOS os componentes
    -- O somador sempre estará calculando...
    u_FPAdd: FPAdd_32bit_Wrapper
        port map (
            X_in  => X_in,
            Y_in  => Y_in,
            R_out => s_R_add
        );

    -- ...e o multiplicador também sempre estará calculando.
    u_FPMult: FPMult_32bit_Wrapper
        port map (
            X_in  => X_in,
            Y_in  => Y_in,
            R_out => s_R_mult
        );

    -- 4. O Multiplexador (MUX)
    --    Aqui é onde a mágica acontece.
    --    Nós selecionamos qual resultado vai para a saída final (R_out)
    --    com base no seletor 'Op_sel'.
    with Op_sel select
        R_out <= s_R_add  when '0',  -- Se Op_sel = '0', use o resultado da SOMA
                 s_R_mult when '1',  -- Se Op_sel = '1', use o resultado da MULTIPLICAÇÃO
                 (others => 'X') when others; -- Default para valores indefinidos

end architecture Structural;