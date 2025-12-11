library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Data_Memory is
    port (
        -- O clock global do processador
        Clk         : in  std_logic;
        
        -- Sinais de Controle (da Unidade de Controle)
        MemWrite    : in  std_logic; -- '1' = Escrever, '0' = Não escrever
        MemRead     : in  std_logic; -- '1' = Ler (usado para habilitar a saída, opcional)
        
        -- Endereço (normalmente vindo da saída da ALU de inteiros)
        Address     : in  std_logic_vector(31 downto 0);
        
        -- Dados a serem escritos (vindos do Banco de Registradores)
        DataIn      : in  std_logic_vector(31 downto 0);
        
        -- Dados lidos (indo para o Banco de Registradores)
        DataOut     : out std_logic_vector(31 downto 0)
    );
end entity Data_Memory;

architecture Behavioral of Data_Memory is

    -- Define o tamanho da nossa memória (2^8 = 256 palavras de 32 bits)
    constant MEM_DEPTH : integer := 256;
    type mem_type is array (0 to MEM_DEPTH - 1) of std_logic_vector(31 downto 0);

    -- O sinal principal que armazena os dados da RAM
    -- Podemos inicializar com 'X' para ver se tentamos ler algo
    -- que nunca foi escrito.
    signal RAM : mem_type := (others => (others => 'X'));
    
    -- Sinal interno para o endereço (índice da array)
    signal s_ram_addr : integer range 0 to MEM_DEPTH - 1;

begin

    -- Mapeamento do Endereço (igual ao da Memória de Instrução)
    -- O endereço da ALU conta em bytes (0, 4, 8...).
    -- Nossa RAM (array) conta em palavras (0, 1, 2...).
    -- Ignoramos os 2 bits menos significativos.
    s_ram_addr <= to_integer(unsigned(Address(9 downto 2)));

    -- === Processo de Leitura (Combinacional/Assíncrono) ===
    -- A leitura acontece o tempo todo, independentemente do clock.
    -- O 'DataOut' sempre reflete o que está no endereço 's_ram_addr'.
    -- (O sinal MemRead é usado pela Unidade de Controle, não aqui)
    DataOut <= RAM(s_ram_addr) when MemRead = '1' else (others => 'Z');


    -- === Processo de Escrita (Síncrono) ===
    -- A escrita SÓ acontece na borda de subida do clock
    -- E APENAS SE o sinal 'MemWrite' estiver ativo.
    process(Clk)
    begin
        if rising_edge(Clk) then
            if (MemWrite = '1') then
                RAM(s_ram_addr) <= DataIn;
            end if;
        end if;
    end process;

end architecture Behavioral;