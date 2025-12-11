library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_textio.all;
use ieee.numeric_std.all;
use std.textio.all; -- Para ler o arquivo de texto

entity Instruction_Memory is
    port (
        -- Endereço de 32 bits vindo do Program Counter (PC)
        Address     : in  std_logic_vector(31 downto 0);
        
        -- Instrução de 32 bits saindo para o 'datapath'
        Instruction : out std_logic_vector(31 downto 0)
    );
end entity Instruction_Memory;

architecture Behavioral of Instruction_Memory is

    -- Define o tamanho da nossa memória (2^8 = 256 palavras de 32 bits)
    constant MEM_DEPTH : integer := 256;
    type mem_type is array (0 to MEM_DEPTH - 1) of std_logic_vector(31 downto 0);

    -- Função pura para ler o arquivo de memória (apenas VHDL-1993)
    -- Ela lê o "program.mem" e inicializa a ROM
    pure function init_rom(filename : string) return mem_type is
        file mem_file     : text open read_mode is filename;
        variable file_line  : line;
        variable rom_data   : mem_type;
        variable hval       : std_logic_vector(31 downto 0);
    begin
        for i in 0 to MEM_DEPTH - 1 loop
            if not endfile(mem_file) then
                readline(mem_file, file_line);
                -- hread lê um valor hexadecimal da linha
                hread(file_line, hval);
                rom_data(i) := hval;
            else
                -- Preenche o resto da memória com NOP (Instrução '0')
                rom_data(i) := x"00000000";
            end if;
        end loop;
        file_close(mem_file);
        return rom_data;
    end function;

    -- Cria o sinal da ROM e o inicializa chamando a função
    signal ROM : mem_type := init_rom("./program.mem");
    
    -- Sinal interno para o endereço (índice da array)
    signal s_rom_addr : integer range 0 to MEM_DEPTH - 1;

begin

    -- Mapeamento do Endereço:
    -- O PC (Address) conta em bytes (0, 4, 8...).
    -- Nossa ROM (array) conta em palavras (0, 1, 2...).
    --
    -- Pegamos os bits [9:2] do endereço do PC para usá-los como
    -- o índice da nossa array. Isso nos dá uma ROM de 2^8 = 256 palavras
    -- e ignora os 2 bits menos significativos (que são sempre '00').
    s_rom_addr <= to_integer(unsigned(Address(9 downto 2)));

    -- Processo de Leitura (Combinacional):
    -- A instrução na saída é atualizada imediatamente
    -- quando o endereço de entrada muda.
    Instruction <= ROM(s_rom_addr);

end architecture Behavioral;