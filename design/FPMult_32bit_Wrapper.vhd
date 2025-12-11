library ieee;
use ieee.std_logic_1164.all;

entity FPMult_32bit_Wrapper is
    port (
        -- Entradas padrão IEEE 754 (32 bits)
        X_in  : in  std_logic_vector(31 downto 0);
        Y_in  : in  std_logic_vector(31 downto 0);
        
        -- Saída padrão IEEE 754 (32 bits)
        R_out : out std_logic_vector(31 downto 0)
    );
end entity FPMult_32bit_Wrapper;

architecture Structural of FPMult_32bit_Wrapper is

    -- Sinais internos para conectar os blocos no formato FloPoCo (34 bits)
    signal s_X_internal : std_logic_vector(33 downto 0);
    signal s_Y_internal : std_logic_vector(33 downto 0);
    signal s_R_internal : std_logic_vector(33 downto 0);

    -- Declaração dos 3 componentes principais que vamos instanciar

    -- Componente 1: Conversor de Entrada
    component InputIEEE_8_23_to_8_23
       port ( X : in  std_logic_vector(31 downto 0);
              R : out  std_logic_vector(33 downto 0) );
    end component;

    -- Componente 2: Núcleo Multiplicador
    component FPMult_8_23_8_23_8_23_comb_uid2
       port ( X : in  std_logic_vector(33 downto 0);
              Y : in  std_logic_vector(33 downto 0);
              R : out  std_logic_vector(33 downto 0) );
    end component;

    -- Componente 3: Conversor de Saída
    component OutputIEEE_8_23_to_8_23
       port ( X : in  std_logic_vector(33 downto 0);
              R : out  std_logic_vector(31 downto 0) );
    end component;

begin

    -- 1. Converte a entrada X (32-bit IEEE) para o formato interno (34-bit)
    u_Input_X: InputIEEE_8_23_to_8_23
        port map (
            X => X_in,
            R => s_X_internal
        );

    -- 2. Converte a entrada Y (32-bit IEEE) para o formato interno (34-bit)
    u_Input_Y: InputIEEE_8_23_to_8_23
        port map (
            X => Y_in,
            R => s_Y_internal
        );

    -- 3. Executa a multiplicação usando o núcleo de 34-bit
    u_FPMult_Core: FPMult_8_23_8_23_8_23_comb_uid2
        port map (
            X => s_X_internal,
            Y => s_Y_internal,
            R => s_R_internal
        );

    -- 4. Converte o resultado interno (34-bit) de volta para IEEE (32-bit)
    u_Output_R: OutputIEEE_8_23_to_8_23
        port map (
            X => s_R_internal,
            R => R_out
        );

end architecture Structural;