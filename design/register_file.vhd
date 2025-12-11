library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- 1. Entidade: As portas de entrada/saída
entity register_file is
  port (
    Clock     : in  std_logic;
    RegWrite  : in  std_logic;                      -- Sinal de controle: '1' para escrever
    ReadReg1  : in  std_logic_vector(4 downto 0);   -- Endereço do 1º registrador a ler (5 bits para 32 reg)
    ReadReg2  : in  std_logic_vector(4 downto 0);   -- Endereço do 2º registrador a ler
    WriteReg  : in  std_logic_vector(4 downto 0);   -- Endereço do registrador a escrever
    WriteData : in  std_logic_vector(31 downto 0);  -- Dado de 32 bits a ser escrito
    ReadData1 : out std_logic_vector(31 downto 0);  -- Saída do 1º registrador lido
    ReadData2 : out std_logic_vector(31 downto 0)   -- Saída do 2º registrador lido
  );
end entity register_file;

-- 2. Arquitetura: O funcionamento interno
architecture behavioral of register_file is

  -- Define um "tipo" de dado que é um array de 32 registradores,
  -- onde cada um é um vetor de 32 bits.
  type reg_array_t is array (0 to 31) of std_logic_vector(31 downto 0);
  
  -- Cria a memória interna (o "banco") usando esse tipo.
  -- Inicializa todos os registradores com zero.
  signal reg_bank : reg_array_t := (others => (others => '0'));

begin

  -- Lógica de Leitura 1 (Assíncrona)
  -- Converte o endereço de 5 bits para um inteiro
  ReadData1 <= reg_bank(to_integer(unsigned(ReadReg1)));

  -- Lógica de Leitura 2 (Assíncrona)
  ReadData2 <= reg_bank(to_integer(unsigned(ReadReg2)));

  -- Lógica de Escrita (Síncrona)
  write_process : process(Clock)
  begin
    -- Só faz algo na borda de subida do clock
    if rising_edge(Clock) then
      
      -- Verifica se o sinal RegWrite está ativo ('1')
      -- E se o endereço de escrita NÃO é o zero
      if (RegWrite = '1' and to_integer(unsigned(WriteReg)) /= 0) then
        
        -- Escreve o dado no registrador especificado
        reg_bank(to_integer(unsigned(WriteReg))) <= WriteData;
        
      end if;
    end if;
  end process write_process;

end architecture behavioral;
