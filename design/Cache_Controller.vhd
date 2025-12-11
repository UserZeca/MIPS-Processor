library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Cache_Controller is
    port (
        Clk : in std_logic;
        Rst : in std_logic;
        
        -- Interface com a CPU (Processador)
        CPU_Address   : in  std_logic_vector(31 downto 0);
        CPU_WriteData : in  std_logic_vector(31 downto 0);
        CPU_MemWrite  : in  std_logic;
        CPU_MemRead   : in  std_logic;
        CPU_ReadData  : out std_logic_vector(31 downto 0);
        CPU_Stall     : out std_logic; 
        
        -- Interface com a Memória Principal (RAM)
        RAM_ReadData  : in  std_logic_vector(31 downto 0); 
        RAM_Address   : out std_logic_vector(31 downto 0);
        RAM_WriteData : out std_logic_vector(31 downto 0);
        RAM_MemWrite  : out std_logic;
        RAM_MemRead   : out std_logic
    );
end entity Cache_Controller;

architecture Behavioral of Cache_Controller is

    -- Definição da Estrutura da Cache (64 Linhas)
    type Cache_Data_Array is array (0 to 63) of std_logic_vector(31 downto 0);
    type Cache_Tag_Array  is array (0 to 63) of std_logic_vector(23 downto 0);
    type Cache_Valid_Array is array (0 to 63) of std_logic;

    -- Sinais Internos
    signal cache_data  : Cache_Data_Array := (others => (others => '0'));
    signal cache_tag   : Cache_Tag_Array  := (others => (others => '0'));
    signal cache_valid : Cache_Valid_Array := (others => '0');

    -- Decodificação do Endereço
    signal s_Tag    : std_logic_vector(23 downto 0);
    signal s_Index  : integer range 0 to 63;
    
    -- Sinais de Controle
    signal s_Hit    : std_logic;
    signal s_Miss   : std_logic;

begin

    -- 1. Decodificação do Endereço (Split)
    s_Tag   <= CPU_Address(31 downto 8);
    s_Index <= to_integer(unsigned(CPU_Address(7 downto 2)));

    -- 2. Verificação de HIT ou MISS
    s_Hit <= '1' when (cache_valid(s_Index) = '1' and cache_tag(s_Index) = s_Tag) else '0';
    s_Miss <= not s_Hit;

    -- 3. Leitura de Dados (Mux de Saída)
    -- CORREÇÃO AQUI: Removido o "when others;" que causava erro
    CPU_ReadData <= cache_data(s_Index) when (s_Hit = '1' and CPU_MemRead = '1') else
                    RAM_ReadData;       

    -- 4. Interface com a RAM (Pass-through)
    RAM_Address   <= CPU_Address;
    RAM_WriteData <= CPU_WriteData;
    
    -- Controle da RAM:
    RAM_MemWrite  <= CPU_MemWrite;
    
    -- Lemos da RAM apenas se houver um MISS de leitura.
    RAM_MemRead   <= CPU_MemRead and s_Miss;
    
    -- Stall (Simplificado)
    CPU_Stall <= '0'; 

    -- 5. Lógica Sequencial (Atualização da Cache)
    process(Clk, Rst)
    begin
        if Rst = '1' then
            cache_valid <= (others => '0'); -- Invalida toda a cache
        elsif rising_edge(Clk) then
            
            -- CASO 1: Escrita (Write-Through)
            if CPU_MemWrite = '1' then
                cache_valid(s_Index) <= '1';
                cache_tag(s_Index)   <= s_Tag;
                cache_data(s_Index)  <= CPU_WriteData;
            end if;

            -- CASO 2: Leitura com Miss (Refill)
            if CPU_MemRead = '1' and s_Miss = '1' then
                cache_valid(s_Index) <= '1';
                cache_tag(s_Index)   <= s_Tag;
                cache_data(s_Index)  <= RAM_ReadData;
            end if;
            
        end if;
    end process;

end architecture Behavioral;