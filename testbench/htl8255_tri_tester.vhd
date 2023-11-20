-------------------------------------------------------------------------------
--  HTL8255 - PPI core                                                       --
--                                                                           --
--  https://github.com/htminuslab                                            --
--                                                                           --
-------------------------------------------------------------------------------
-- Project       : HTL8255                                                   --
-- Purpose       : TestBench Tester file                                     --
-- Library       : I8088                                                     --
--                                                                           --
-- Version       : 1.0  20/01/2002   Created HT-LAB                          --
--               : 1.2  30/11/2023   cleaned and uploaded to github          --
-------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

LIBRARY std;
USE std.TEXTIO.all;

USE work.utils.all;

ENTITY htl8255_tristate_tester IS
   PORT( 
      abus  : OUT    std_logic_vector (1 DOWNTO 0);
      clk   : OUT    std_logic;
      csn   : OUT    std_logic;
      rdn   : OUT    std_logic;
      reset : OUT    std_logic;
      wrn   : OUT    std_logic;
      dbus  : INOUT  std_logic_vector (7 DOWNTO 0);
      pa    : INOUT  std_logic_vector (7 DOWNTO 0);
      pb    : INOUT  std_logic_vector (7 DOWNTO 0);
      pc    : INOUT  std_logic_vector (7 DOWNTO 0)
   );
END htl8255_tristate_tester ;

ARCHITECTURE behaviour OF htl8255_tristate_tester IS
    
signal clk_s  : std_logic:='0';
signal data_s : std_logic_vector(7 downto 0);
signal abus_s : std_logic_vector(1 downto 0);


BEGIN
    
    clk_s <= not clk_s after 40 ns;     
    clk <= clk_s;

    process
        variable L   : line;

        --------------------------------------------------------------------
        -- Simple 8088 Write Port procedure
        -- write byte to I/Oport
        --------------------------------------------------------------------
        procedure outport(                             
            signal addr_p : in std_logic_vector(1 downto 0);-- Port Address
            signal dbus_p : in std_logic_vector(7 downto 0)) is 
            begin 
                wait until rising_edge(clk_s);
                abus <= addr_p;
                csn  <= '0';
                wait for 5 ns;
                wait until rising_edge(clk_s);
                wait for 3 ns;
                wrn  <= '0';
                wait for 2 ns;
                dbus <= dbus_p;
                wait until rising_edge(clk_s);
                wait until rising_edge(clk_s);
                wait for 2 ns;
                abus  <= (others => '1');
                wrn  <= '1';
                csn  <= '1';
                dbus <= (others=>'Z');
                wait for 1 ns;
        end outport;

        --------------------------------------------------------------------
        -- Simple 8088 Read Port procedure
        -- Read byte from I/Oport
        --------------------------------------------------------------------
        procedure inport(                              
            signal addr_p : in std_logic_vector(1 downto 0);-- Port Address
            signal dbus_p : out std_logic_vector(7 downto 0)) is 
            begin 
                wait until rising_edge(clk_s);
                abus <= addr_p;
                csn  <= '0';
                wait for 5 ns;
                wait until rising_edge(clk_s);
                wait for 3 ns;
                rdn  <= '0';
                wait for 2 ns;
                wait until rising_edge(clk_s);              
                wait until rising_edge(clk_s);
                dbus_p<= dbus;
                wait for 2 ns;
                abus <= (others => '1');
                rdn  <= '1';
                csn  <= '1';
                wait for 1 ns;
        end inport;

        --------------------------------------------------------------------
        -- Display 82C55 Control Word Values        
        --------------------------------------------------------------------
        procedure disp_control is                       
            begin 
                
                abus_s <= "11";                         -- Read Control Word 
                inport(abus_s,data_s);
                assert data_s(7)='1' report "failure: Control word bit 7 not set" severity error;

                write(L,string'("GroupA: "));
                case data_s(6 downto 5) is
                    when "00"   => write(L,string'("Mode0  "));
                    when "01"   => write(L,string'("Mode1  ")); 
                    when others => write(L,string'("Mode2  "));
                end case;

                if data_s(4)='1' then
                    write(L,string'("PortA=Input  "));
                else
                    write(L,string'("PortA=Output "));
                end if;

                if data_s(3)='1' then
                    write(L,string'("PortC(7:4)=Input   GroupB: "));
                else
                    write(L,string'("PortC(7:4)=Output  GroupB: "));
                end if;

                if data_s(2)='1' then
                    write(L,string'("Mode1 "));
                else
                    write(L,string'("Mode0 "));
                end if;

                if data_s(1)='1' then
                    write(L,string'("PortB=Input  "));
                else
                    write(L,string'("PortB=Output "));
                end if;

                if data_s(0)='1' then
                    write(L,string'("PortC(3:0)=Input"));
                else
                    write(L,string'("PortC(3:0)=Output"));
                end if;


                writeline(output,L);
                wait for 0 ns;
        end disp_control;

        --------------------------------------------------------------------
        -- Write to 82C55 control I/O port        
        --------------------------------------------------------------------
        procedure write_control(                           
            signal dbus_p : in std_logic_vector(7 downto 0)) is 
            begin 
                abus_s <= "11";                         -- Write to Control Word 
                outport(abus_s,dbus_p);             
                disp_control;
        end write_control;

        --------------------------------------------------------------------
        -- Display 82C55 PortC status        
        --------------------------------------------------------------------
        procedure disp_status is                        
            begin 
                
                abus_s <= "10";                         -- Read PortC 
                inport(abus_s,data_s);

                write(L,string'("PortC="));
                write(L,std_to_string(data_s(7 downto 4)));
                write(L,string'("-"));
                write(L,std_to_string(data_s(3 downto 0)));

                writeline(output,L);
                wait for 0 ns;
        end disp_status;


        begin

            dbus     <= (others => 'Z');
            pa       <= (others => 'H');
            pb       <= (others => 'H');
            pc       <= (others => 'H');
            abus     <= (others => '1');
            data_s   <= (others => 'H');
            rdn      <= '1';
            wrn      <= '1';
            csn      <= '1';
            reset    <= '1';

            wait for 100 ns;
            reset    <= '0';
            wait for 100 ns;

            ---------------------------------------------------------------------------
            -- Mode0 Output
            ---------------------------------------------------------------------------
            write(L,string'("------- Test Mode 0 PortA/B/C Output --------"));   
            writeline(output,L);

            data_s <= "10000000";           -- All Output
            write_control(data_s);
            wait for 200 ns;


            abus_s <= "00";                 -- Write to PortA 
            data_s <= "10101010";           -- AA
            outport(abus_s,data_s);
            wait for 200 ns;
            assert pa=X"AA" report "failure: PortA not 0xAA" severity error;

            abus_s <= "01";                 -- Write to PortB 
            data_s <= "01010101";           -- 55
            outport(abus_s,data_s);
            wait for 200 ns;
            assert pa=X"AA" report "failure: PortA changed" severity error;         
            assert pb=X"55" report "failure: PortB not 0x55" severity error;

            abus_s <= "10";                 -- Write to PortC 
            data_s <= "11000011";           -- C3
            outport(abus_s,data_s);
            wait for 200 ns;
            assert pa=X"AA" report "failure: PortA changed" severity error;         
            assert pb=X"55" report "failure: PortB changed" severity error;
            assert pc=X"C3" report "failure: PortC not 0xC3" severity error;


            abus_s <= "00";                 -- Write to PortA 
            data_s <= "00111100";           -- 3C
            outport(abus_s,data_s);
            wait for 200 ns;
            assert pa=X"3C" report "failure: PortA not 0x3C" severity error;            
            assert pb=X"55" report "failure: PortB changed" severity error;
            assert pc=X"C3" report "failure: PortC changed" severity error;


            ---------------------------------------------------------------------------
            -- Mode0 Input, unlatched!
            ---------------------------------------------------------------------------         
            write(L,string'("------- Test Mode 0 PortA/B/C Input --------"));   
            writeline(output,L);

            data_s <= "10011011";           -- All Input
            write_control(data_s);
            wait for 200 ns;
            
            pa       <= X"55";
            pb       <= X"AA";
            pc       <= X"3C";

            abus_s <= "00";                 -- Read Port A 
            inport(abus_s,data_s);              
            assert data_s=X"55" report "failure: PortA not 0x55 during read" severity error;            
            
            wait for 200 ns;

            abus_s <= "01";                 -- Read Port B 
            inport(abus_s,data_s);              
            assert data_s=X"AA" report "failure: PortB not 0xAA during read" severity error;            

            wait for 200 ns;

            abus_s <= "10";                 -- Read Port C 
            inport(abus_s,data_s);              
            assert data_s=X"3C" report "failure: PortC not 0x3C during read" severity error;            

            wait for 200 ns;

            pa       <= (others => 'H');
            pb       <= (others => 'H');
            pc       <= (others => 'H');


            ---------------------------------------------------------------------------
            -- Mode0 Set/Reset PortC
            ---------------------------------------------------------------------------         
            write(L,string'("------- Test Mode0 toggle portC bit --------"));   
            writeline(output,L);

            data_s <= "10000000";           -- All Output again
            write_control(data_s);
            wait for 200 ns;

            abus_s <= "10";                 -- Write to PortC 
            data_s <= "11000011";           -- C3
            outport(abus_s,data_s);
            assert pc=X"C3" report "failure: PortC not 0xC3, Set Bit function" severity error;

            wait for 200 ns;

            abus_s <= "11";                 -- Set PC(3)
            data_s <= "00000111";           -- C3->CB
            outport(abus_s,data_s);
            assert pc=X"CB" report "failure: PortC not 0xCB, Set Bit function" severity error;

            wait for 200 ns;

            abus_s <= "11";                 -- Set PC(3)
            data_s <= "00000101";           -- CB->CF
            outport(abus_s,data_s);
            assert pc=X"CF" report "failure: PortC not 0xCF, Set Bit function" severity error;

            wait for 200 ns;

            abus_s <= "11";                 -- Set PC(3)
            data_s <= "00001100";           -- CF->8F
            outport(abus_s,data_s);
            assert pc=X"8F" report "failure: PortC not 0x8F, Set Bit function" severity error;

            wait for 200 ns;

            abus_s <= "11";                 -- Set PC(3)
            data_s <= "00001110";           -- 8F->0F
            outport(abus_s,data_s);
            assert pc=X"0F" report "failure: PortC not 0x0F, Set Bit function" severity error;

            wait for 200 ns;
            ---------------------------------------------------------------------------
            -- Mode0 Mixed PortC I/O test   
            -- Use some of the 16 configuration as specified in the datasheets
            ---------------------------------------------------------------------------         

            write(L,string'("------- Test Mode0 split PortC I/O  --------"));   
            writeline(output,L);

            pa <= (others => 'H');
            pb <= (others => 'H');
            pc <= (others => 'H');

            ---------------------------------------------------------------------------
            data_s <= "10000001";           -- Configuration 1, PA/PB out, PCH Out, PCL in              
            write_control(data_s);
            wait for 100 ns;                    

            PC(3 downto 0) <= X"9";

            abus_s <= "00";                 -- Write to PortA  
            data_s <= X"44";                
            outport(abus_s,data_s);
            abus_s <= "01";                 -- Write to PortB  
            data_s <= X"55";                
            outport(abus_s,data_s);
            abus_s <= "10";                 -- Write to PortC, upper only  
            data_s <= X"66";                
            outport(abus_s,data_s);

            abus_s <= "10";                 -- Read PortC  
            inport(abus_s,data_s);

            assert pa=X"44"     report "failure: PortA not 0x44" severity error;  
            assert pb=X"55"     report "failure: PortB not 0x55" severity error;
            assert data_s(3 downto 0)=X"9" report "failure: PortC(3:0) not 0x9" severity error;
            assert pc(7 downto 4)=X"6" report "failure: PortC(7:4) not 0x6" severity error;
            
            pa <= (others => 'H');
            pb <= (others => 'H');
            pc <= (others => 'H');

            ---------------------------------------------------------------------------
            write(L,string'("------- Test Mode1 Port A/B Input, PCH in, PCL out --------"));   
            writeline(output,L);

            data_s <= "10001010";           -- Configuration 6, PA out PB in, PCH in, PCL out               
            write_control(data_s);
            wait for 100 ns;                    

            PC(7 downto 4) <= X"3";
            PB <= X"22";

            abus_s <= "00";                 -- Write to PortA  
            data_s <= X"11";                
            outport(abus_s,data_s);
            abus_s <= "10";                 -- Write to PortC, lower only  
            data_s <= X"77";                
            outport(abus_s,data_s);

            assert pa=X"11"     report "failure: PortA not 0x11" severity error;

            abus_s <= "01";                 -- Read PortB  
            inport(abus_s,data_s);
            assert data_s=X"22" report "failure: PortB not 0x22" severity error;

            abus_s <= "10";                 -- Read PortC  
            inport(abus_s,data_s);
            assert data_s(7 downto 4)=X"3" report "failure: PortC(7:4) not 0x3" severity error;
            assert pc(3 downto 0)=X"7" report "failure: PortC(3:0) not 0x7" severity error;
            
            pa <= (others => 'H');
            pb <= (others => 'H');
            pc <= (others => 'H');

            ---------------------------------------------------------------------------
            -- Mode1 Strobed Output
            ---------------------------------------------------------------------------         

            write(L,string'("------- Test Mode1 Port A/B Strobed Output --------"));   
            writeline(output,L);

            pc(6)<='1';                     -- ACKA is high
            pc(2)<='1';                     -- ACKB is high

            data_s <= "10100100";           -- mode1 porta and b
            write_control(data_s);
            wait for 200 ns;

            abus_s <= "00";                 -- Write to PortA 
            data_s <= "00101000";           -- 28
            outport(abus_s,data_s);
            wait until rising_edge(clk_s);
            wait until rising_edge(clk_s);
            assert pc(7)='0' report "failure: OBFA not asserted" severity error;
            
            pc(6)<='0';                     -- Create ACKA pulse
            wait for 100 ns;
            pc(6)<='1';
            assert pc(7)='1' report "failure: OBFA not negated" severity error;

            abus_s <= "01";                 -- Write to PortB 
            data_s <= "00101001";           -- 29
            outport(abus_s,data_s);
            wait until rising_edge(clk_s);
            wait until rising_edge(clk_s);
            assert pc(1)='0' report "failure: OBFB not asserted" severity error;

            wait for 400 ns;
            pc(2)<='0';                     -- Create ACKB pulse
            wait for 100 ns;
            pc(2)<='1';
            assert pc(1)='1' report "failure: OBFB not negated" severity error;


            ---------------------------------------------------------------------------
            -- Mode1 PortA Strobed Output   + Interrupts enabled
            ---------------------------------------------------------------------------         

            write(L,string'("------- Test Mode1 PortA Strobed Output + Interrupts --------"));   
            writeline(output,L);

            pc(6)<='1';                     -- ACKA is high

            data_s <= "10100000";           -- mode1 porta mode0 for portB
            write_control(data_s);

            abus_s <= "11";
            data_s <= "00001101";           -- Set INTEA1 (pc6), 0D
            outport(abus_s,data_s);

            abus_s <= "00";                 -- Write to PortA (part of ISR) 
            data_s <= "00101010";           -- 2B
            outport(abus_s,data_s);

            wait until rising_edge(clk_s);
            wait until rising_edge(clk_s);
            assert pc(7)='0' report "failure: OBFA not asserted" severity error;
            
            wait for 1 us;

            pc(6)<='0';                     -- Create ACKA pulse
            wait for 100 ns;
            pc(6)<='1';
            assert pc(7)='1' report "failure: OBFA not negated" severity error;
            wait until rising_edge(clk_s);
            wait until rising_edge(clk_s);
            wait until rising_edge(clk_s);
            assert pc(3)='1' report "failure: INTRA not asserted" severity error;


            abus_s <= "00";                 -- Write second byte to PortA (part of ISR) 
            data_s <= "00101100";           -- 2C
            outport(abus_s,data_s);

            wait for 400 ns;
            pc(6)<='0';                     -- Create ACKA pulse
            wait for 100 ns;
            pc(6)<='1';
            assert pc(7)='1' report "failure: OBFA not negated" severity error;
            wait until rising_edge(clk_s);
            wait until rising_edge(clk_s);
            wait until rising_edge(clk_s);
            assert pc(3)='1' report "failure: INTRA not asserted" severity error;

            abus_s <= "11";                 -- Disable Interrupt 
            data_s <= "00001100";           -- Clear INTEA1 (pc6), 0C
            outport(abus_s,data_s);

            ---------------------------------------------------------------------------
            -- Mode1 PortB Strobed Output   + Interrupts enabled
            ---------------------------------------------------------------------------         

            write(L,string'("------- Test Mode1 PortB Strobed Output + Interrupts --------"));   
            writeline(output,L);

            data_s <= "10011100";           -- mode1 portb and Mode0 porta Input, PC-Upper input
            write_control(data_s);

            pc(2)<='1';                     -- ACKB is high

            abus_s <= "11";                 -- Enable Interrupts PortB, Set INTEB (pc2)
            data_s <= "00000101";           -- 05
            outport(abus_s,data_s);

            abus_s <= "01";                 -- Write to PortB (part of ISR) 
            data_s <= "00001101";           -- 0D
            outport(abus_s,data_s);
            wait until rising_edge(clk_s);
            wait until rising_edge(clk_s);
            assert pc(1)='0' report "failure: OBFB not asserted" severity error;

            pc(2)<='0';                     -- Create ACKB pulse
            wait for 100 ns;
            pc(2)<='1';
            assert pc(1)='1' report "failure: OBFB not negated" severity error;

            wait until rising_edge(clk_s);
            wait until rising_edge(clk_s);
            wait until rising_edge(clk_s);
            assert pc(0)='1' report "failure: INTRB not asserted" severity error;

            abus_s <= "01";                 -- Write to PortB (part of ISR) 
            data_s <= "00101110";           -- 2E
            outport(abus_s,data_s);

            wait for 400 ns;

            pc(2)<='0';                     -- Create ACKB pulse
            wait for 100 ns;
            pc(2)<='1';

            assert pc(1)='1' report "failure: OBFA not negated" severity error;
            wait until rising_edge(clk_s);
            wait until rising_edge(clk_s);
            wait until rising_edge(clk_s);
            assert pc(0)='1' report "failure: INTRB not asserted" severity error;

            abus_s <= "11";                 -- Disable Interrupts PortB, Clear INTEB (pc2)
            data_s <= "00000100";           -- 04
            outport(abus_s,data_s);


            ---------------------------------------------------------------------------
            -- Mode1 Strobed Input  
            ---------------------------------------------------------------------------         

            write(L,string'("------- Test Mode1 PortA Strobed Input --------"));   
            writeline(output,L);

            pc(4)<='1';                     -- STBA is high
            pa <= (others => 'H');
            pc <= (others => 'H');

            data_s <= "10110010";           -- Mode1 Porta Input, mode0 for portB input
            write_control(data_s);

            wait for 400 ns;

            pa <= X"6B";
            pc(4)<='0';                     -- Assert STBA, strobe in 6B 
            wait for 100 ns;
            pc(4)<='1';
            wait for 5 ns;
            pa <= (others => '1');

            abus_s <= "00";                 -- Read PortA (part of ISR) 
            inport(abus_s,data_s);
            assert dbus=X"6B" report "failure: Value read from PortA is not 0x6B" severity error;
            

            write(L,string'("------- Test Mode1 PortB Strobed Input --------"));   
            writeline(output,L);

            pc(2)<='1';                     -- STBB is high
            pb <= (others => 'H');
            pc <= (others => 'H');

            data_s <= "10010110";           -- Mode1 PortB Input, mode0 for portA input
            write_control(data_s);

            wait for 400 ns;

            pb <= X"7C";
            pc(2)<='0';                     -- Assert STBB, strobe in 7C 
            wait for 100 ns;
            pc(2)<='1';
            wait for 5 ns;
            pb <= (others => 'H');

            abus_s <= "01";                 -- Read PortB (part of ISR) 
            inport(abus_s,data_s);
            assert dbus=X"7C" report "failure: Value read from PortB is not 0x7C" severity error;


            ---------------------------------------------------------------------------
            -- Mode1 Strobed Input + Interrupts 
            ---------------------------------------------------------------------------         

            write(L,string'("------- Test Mode1 PortA Strobed Input + Interrupts --------"));   
            writeline(output,L);

            pc(4)<='1';                     -- STBA is high
            pa <= (others => 'H');
            pc <= (others => 'H');

            data_s <= "10110010";           -- Mode1 Porta Input, mode0 for portB input
            write_control(data_s);

            abus_s <= "11";                 -- Enable Interrupts PortA, Set INTEB (pc4)
            data_s <= "00001001";           -- 09
            outport(abus_s,data_s);


            wait for 400 ns;

            pa <= X"8D";
            pc(4)<='0';                     -- Assert STBA, strobe in 8D 
            wait for 100 ns;
            pc(4)<='1';
            wait for 5 ns;
            pa <= (others => '1');

            wait for 199 ns;

            -- Check that the interrupt line is high before reading the port.
            assert pc(3)='1' report "failure: INTRA not asserted" severity error;
            abus_s <= "00";                 -- Read PortA (part of ISR) 
            inport(abus_s,data_s);
            assert dbus=X"8D" report "failure: Value read from PortA is not 0x8D" severity error;
            

            write(L,string'("------- Test Mode1 PortB Strobed Input --------"));   
            writeline(output,L);

            pc(2)<='1';                     -- STBB is high
            pb <= (others => 'H');
            pc <= (others => 'H');

            data_s <= "10010110";           -- Mode1 PortB Input, mode0 for portA input
            write_control(data_s);

            abus_s <= "11";                 -- Enable Interrupts PortB, Set INTEB (pc2)
            data_s <= "00000101";           -- 05
            outport(abus_s,data_s);

            wait for 400 ns;

            pb <= X"9E";
            pc(2)<='0';                     -- Assert STBB, strobe in 7C 
            wait for 100 ns;
            pc(2)<='1';
            wait for 5 ns;
            pb <= (others => 'H');

            wait for 200 ns;

            -- Check that the interrupt line is high before reading the port.
            assert pc(0)='1' report "failure: INTRB not asserted" severity error;
            abus_s <= "01";                 -- Read PortB (part of ISR) 
            inport(abus_s,data_s);
            assert dbus=X"9E" report "failure: Value read from PortB is not 0x9E" severity error;

            ---------------------------------------------------------------------------
            -- Mode1/Mode0 Mixed I/O test   
            -- PortA Mode1-Output, PortB Mode0-Output PortC-Output
            --
            -- Through a “Write Port C” command, only the Port C pins
            -- programmed as outputs in a Mode 0 group can be written.
            -- No other pins can be affected by a “Write Port C” command,
            -- nor can the interrupt enable flags be accessed. To write to
            -- any Port C output programmed as an output in Mode 1
            -- group or to change an interrupt enable flag, the 'Set/Reset
            -- Port C Bit' command must used.                       
            ---------------------------------------------------------------------------         

            write(L,string'("------- Test PortA Mode1, PortB Mode0 PortC Output  --------"));   
            writeline(output,L);

            pa <= (others => 'H');
            pb <= (others => 'H');
            pc <= (others => 'H');

            data_s <= "10100000";           -- PortA Mode1 Output, PortB=Mode0 Output, PortC Output             
            write_control(data_s);

            abus_s <= "10";                 -- Write to PortC, *** should not affect PortA ***  
            data_s <= X"00";                
            outport(abus_s,data_s);
            assert pc(7)='1' report "failure: OBFA affected by PortC 0x00 write" severity error;
            assert pc(3)='0' report "failure: INTRA affected by PortC 0x00 write" severity error;
            assert pc(5 downto 4)="00" report "failure: PC(5:4) not 00 after PortC 0x00 write" severity error;
            assert pc(2 downto 0)="000" report "failure: PC(2:0) not 000 after PortC 0x00 write" severity error;
            
            data_s <= X"FF";                -- Write to PortC, *** should not affect PortA ***
            outport(abus_s,data_s);
            assert pc(7)='1' report "failure: OBFA affected by PortC 0xFF write" severity error;
            assert pc(3)='0' report "failure: INTRA affected by PortC 0x00 write" severity error;
            assert pc(5 downto 4)="11" report "failure: PC(5:4) not 11 after PortC 0xFF write" severity error;


            abus_s <= "00";                 -- Write to PortA, assert OBFA, INTRA should still be low  
            data_s <= X"19";                
            outport(abus_s,data_s);
            abus_s <= "01";                 -- Write to PortB, should not affect PortC or PortA  
            data_s <= X"2A";                
            outport(abus_s,data_s);

            assert pc(5 downto 4)="11" report "failure: PC(5:4) not 11 after PortC 0xFF write" severity error;
            assert pc(2 downto 0)="111" report "failure: PC(2:0) not 111 after PortC 0xFF write" severity error;
            assert pb=X"2A" report "failure: PB not 2A after PortB 0x2A write" severity error;


            abus_s <= "10";                 -- Write to PortC, *** should not affect PortA ***  
            data_s <= X"00";                
            outport(abus_s,data_s);
            assert pc(7)='0' report "failure: OBFA affected by PortC 0x00 write" severity error;
            assert pc(3)='0' report "failure: INTRA affected by PortC 0x00 write" severity error;
            assert pc(5 downto 4)="00" report "failure: PC(5:4) not 00 after PortC 0x00 write" severity error;
            assert pc(2 downto 0)="000" report "failure: PC(2:0) not 000 after PortC 0x00 write" severity error;
            
            data_s <= X"FF";                -- Write to PortC, *** should not affect PortA ***
            outport(abus_s,data_s);
            assert pc(7)='0' report "failure: OBFA affected by PortC 0xFF write" severity error;
            assert pc(3)='0' report "failure: INTRA affected by PortC 0x00 write" severity error;
            assert pc(5 downto 4)="11" report "failure: PC(5:4) not 11 after PortC 0xFF write" severity error;
            assert pc(2 downto 0)="111" report "failure: PC(2:0) not 111 after PortC 0xFF write" severity error;
            assert pb=X"2A" report "failure: PB not 2A after PortB 0x2A write" severity error;


            ---------------------------------------------------------------------------
            -- Mode1/Mode0 Mixed I/O test   
            -- PortA Mode1-Output, PortB Mode1-Output PortC Output
            ---------------------------------------------------------------------------

            write(L,string'("------- Test PortA/B Mode1, PortC Output  --------"));   
            writeline(output,L);

            pa <= (others => 'H');
            pb <= (others => 'H');
            pc <= (others => 'H');

            ---------------------------------------------------------------------------
            data_s <= "10100100";           -- PortA/B Mode1 Output,  PortC Output              
            write_control(data_s);


            abus_s <= "10";                 -- Write 00 to PortC, *** should not affect PortA/B ***  
            data_s <= X"00";                
            outport(abus_s,data_s);
            assert pc(7)='1' report "failure: OBFA affected by PortC 0x00 write" severity error;
            assert pc(1)='1' report "failure: OBFB affected by PortC 0x00 write" severity error;
            assert pc(3)='0' report "failure: INTRA affected by PortC 0x00 write" severity error;
            assert pc(0)='0' report "failure: INTRB affected by PortC 0x00 write" severity error;
            assert pc(5 downto 4)="00" report "failure: PC(5:4) not 00 after PortC 0x00 write" severity error;
            
            abus_s <= "10";                 -- Write FF to PortC, *** should not affect PortA/B ***
            data_s <= X"FF";                
            outport(abus_s,data_s);
            assert pc(7)='1' report "failure: OBFA affected by PortC 0xFF write" severity error;
            assert pc(1)='1' report "failure: OBFB affected by PortC 0xFF write" severity error;
            assert pc(3)='0' report "failure: INTRA affected by PortC 0xFF write" severity error;
            assert pc(0)='0' report "failure: INTRB affected by PortC 0xFF write" severity error;
            assert pc(5 downto 4)="11" report "failure: PC(5:4) not 11 after PortC 0xFF write" severity error;

            -- Next write to PortB which should only set the OBFB flag
            abus_s <= "01";                 -- Write to PortB, should not affect PortC or PortA  
            data_s <= X"3B";                
            outport(abus_s,data_s);

            abus_s <= "10";                 -- Write 00 to PortC, *** should not affect PortA/B ***  
            data_s <= X"00";                
            outport(abus_s,data_s);
            assert pc(7)='1' report "failure: OBFA affected by PortC 0x00 write" severity error;
            assert pc(1)='0' report "failure: OBFB affected by PortC 0x00 write" severity error;
            assert pc(3)='0' report "failure: INTRA affected by PortC 0x00 write" severity error;
            assert pc(0)='0' report "failure: INTRB affected by PortC 0x00 write" severity error;
            assert pc(5 downto 4)="00" report "failure: PC(5:4) not 00 after PortC 0x00 write" severity error;
            
            abus_s <= "10";                 -- Write FF to PortC, *** should not affect PortA/B ***
            data_s <= X"FF";                
            outport(abus_s,data_s);
            assert pc(7)='1' report "failure: OBFA affected by PortC 0xFF write" severity error;
            assert pc(1)='0' report "failure: OBFB affected by PortC 0xFF write" severity error;
            assert pc(3)='0' report "failure: INTRA affected by PortC 0xFF write" severity error;
            assert pc(0)='0' report "failure: INTRB affected by PortC 0xFF write" severity error;
            assert pc(5 downto 4)="11" report "failure: PC(5:4) not 11 after PortC 0xFF write" severity error;


            -- Next write to PortA which should only set the OBFA flag
            abus_s <= "00";                 -- Write to PortA, assert OBFA, INTRA should still be low  
            data_s <= X"4C";                
            outport(abus_s,data_s);

            abus_s <= "10";                 -- Write 00 to PortC, *** should not affect PortA/B ***  
            data_s <= X"00";                
            outport(abus_s,data_s);
            assert pc(7)='0' report "failure: OBFA affected by PortC 0x00 write" severity error;
            assert pc(1)='0' report "failure: OBFB affected by PortC 0x00 write" severity error;
            assert pc(3)='0' report "failure: INTRA affected by PortC 0x00 write" severity error;
            assert pc(0)='0' report "failure: INTRB affected by PortC 0x00 write" severity error;
            assert pc(5 downto 4)="00" report "failure: PC(5:4) not 00 after PortC 0x00 write" severity error;
            
            abus_s <= "10";                 -- Write FF to PortC, *** should not affect PortA/B ***
            data_s <= X"FF";                
            outport(abus_s,data_s);
            assert pc(7)='0' report "failure: OBFA affected by PortC 0xFF write" severity error;
            assert pc(1)='0' report "failure: OBFB affected by PortC 0xFF write" severity error;
            assert pc(3)='0' report "failure: INTRA affected by PortC 0xFF write" severity error;
            assert pc(0)='0' report "failure: INTRB affected by PortC 0xFF write" severity error;
            assert pc(5 downto 4)="11" report "failure: PC(5:4) not 11 after PortC 0xFF write" severity error;


            ---------------------------------------------------------------------------
            -- Mode1/Mode0 Mixed I/O test   
            -- PortA/B Mode1-Input, PortC-output
            ---------------------------------------------------------------------------         

            write(L,string'("------- Test PortA/B Mode1 Input, PortC Output  --------"));   
            writeline(output,L);

            pa <= (others => 'H');
            pb <= (others => 'H');
            pc <= (others => 'H');

            data_s <= "10110110";           -- PortA/B Mode1 Output, PortC Output               
            write_control(data_s);

            abus_s <= "10";                 -- Write 00 to PortC, *** should not affect PortA/B ***  
            data_s <= X"00";                
            outport(abus_s,data_s);
            assert pc(5)='0' report "failure: IBFA affected by PortC 0x00 write" severity error;
            assert pc(1)='0' report "failure: IBFB affected by PortC 0x00 write" severity error;
            assert pc(3)='0' report "failure: INTRA affected by PortC 0x00 write" severity error;
            assert pc(0)='0' report "failure: INTRB affected by PortC 0x00 write" severity error;
            assert pc(7 downto 6)="00" report "failure: PC(7:6) not 00 after PortC 0x00 write" severity error;
            
            abus_s <= "10";                 -- Write FF to PortC, *** should not affect PortA/B ***
            data_s <= X"FF";                
            outport(abus_s,data_s);
            assert pc(5)='0' report "failure: IBFA affected by PortC 0xFF write" severity error;
            assert pc(1)='0' report "failure: IBFB affected by PortC 0xFF write" severity error;
            assert pc(3)='0' report "failure: INTRA affected by PortC 0xFF write" severity error;
            assert pc(0)='0' report "failure: INTRB affected by PortC 0xFF write" severity error;
            assert pc(7 downto 6)="11" report "failure: PC(7:6) not 11 after PortC 0xFF write" severity error;

            -- Next strobe in byte on PortA which should only set the IBFA flag
            pc(4) <= '0';
            wait for 100 ns;
            pc(4) <= '1';

            abus_s <= "10";                 -- Write 00 to PortC, *** should not affect PortA/B ***  
            data_s <= X"00";                
            outport(abus_s,data_s);
            assert pc(5)='1' report "failure: IBFA affected by PortC 0x00 write" severity error;
            assert pc(1)='0' report "failure: IBFB affected by PortC 0x00 write" severity error;
            assert pc(3)='0' report "failure: INTRA affected by PortC 0x00 write" severity error;
            assert pc(0)='0' report "failure: INTRB affected by PortC 0x00 write" severity error;
            assert pc(7 downto 6)="00" report "failure: PC(7:6) not 00 after PortC 0x00 write" severity error;
            
            abus_s <= "10";                 -- Write FF to PortC, *** should not affect PortA/B ***
            data_s <= X"FF";                
            outport(abus_s,data_s);
            assert pc(5)='1' report "failure: IBFA affected by PortC 0xFF write" severity error;
            assert pc(1)='0' report "failure: IBFB affected by PortC 0xFF write" severity error;
            assert pc(3)='0' report "failure: INTRA affected by PortC 0xFF write" severity error;
            assert pc(0)='0' report "failure: INTRB affected by PortC 0xFF write" severity error;
            assert pc(7 downto 6)="11" report "failure: PC(7:6) not 11 after PortC 0xFF write" severity error;


            -- Next strobe in byte on PortB which should only set the IBFB flag
            pc(2) <= '0';
            wait for 100 ns;
            pc(2) <= '1';

            abus_s <= "10";                 -- Write 00 to PortC, *** should not affect PortA/B ***  
            data_s <= X"00";                
            outport(abus_s,data_s);
            assert pc(5)='1' report "failure: IBFA affected by PortC 0x00 write" severity error;
            assert pc(1)='1' report "failure: IBFB affected by PortC 0x00 write" severity error;
            assert pc(3)='0' report "failure: INTRA affected by PortC 0x00 write" severity error;
            assert pc(0)='0' report "failure: INTRB affected by PortC 0x00 write" severity error;
            assert pc(7 downto 6)="00" report "failure: PC(7:6) not 00 after PortC 0x00 write" severity error;
            
            abus_s <= "10";                 -- Write FF to PortC, *** should not affect PortA/B ***
            data_s <= X"FF";                
            outport(abus_s,data_s);
            assert pc(5)='1' report "failure: IBFA affected by PortC 0xFF write" severity error;
            assert pc(1)='1' report "failure: IBFB affected by PortC 0xFF write" severity error;
            assert pc(3)='0' report "failure: INTRA affected by PortC 0xFF write" severity error;
            assert pc(0)='0' report "failure: INTRB affected by PortC 0xFF write" severity error;
            assert pc(7 downto 6)="11" report "failure: PC(7:6) not 11 after PortC 0xFF write" severity error;


            ---------------------------------------------------------------------------
            -- Mode2 Bidirectional I/O on porta 
            ---------------------------------------------------------------------------         

            write(L,string'("------- Test Mode2 PortA Bidirectional I/O --------"));   
            writeline(output,L);

            pa <= (others => 'Z');
            pc <= (others => 'H');

            data_s <= "11000010";           -- Mode2 Porta Input, mode0 for portB input
            write_control(data_s);

            pc(6)<='1';                     -- ACKA is high
            pc(4)<='1';                     -- STBA is high

            abus_s <= "11";                 -- Enable Both Interrupts PortA, PC4/PC6
            data_s <= "00001001";           -- 09
            outport(abus_s,data_s);
            data_s <= "00001101";           -- 0D
            outport(abus_s,data_s);

            wait for 200 ns;                    

            abus_s <= "00";                 -- Write to PortA  
            data_s <= X"A7";                
            outport(abus_s,data_s);

            wait for 400 ns;

            pc(6)<='0';                     -- Pulse ACKA, acknowledge byte received 
            wait for 100 ns;                -- Interrupt will be asserted
            pc(6)<='1';                     -- do a read to determine were the int came from
            wait for 5 ns;
            
            wait until rising_edge(clk_s);
            wait until rising_edge(clk_s);
            wait until rising_edge(clk_s);
            assert pc(3)='1' report "failure: INTRA not asserted" severity error;
            assert pc(7)='1' report "failure: OBFA not negated" severity error;

            --disp_status;

            wait for 400 ns;                -- Next Peripheral writes a byte 

            pa <= X"B8";
            pc(4)<='0';                     -- Assert STBA, strobe in B8 
            wait for 100 ns;
            pc(4)<='1';
            wait for 5 ns;
            pa <= (others => 'Z');
            
            assert pc(5)='1' report "failure: IBFA not asserted" severity error;
            assert pc(3)='1' report "failure: INTRA not asserted" severity error;
            assert pc(7)='1' report "failure: OBFA not negated" severity error;

            --disp_status;

            wait for 400 ns;

            abus_s <= "00";                 -- Read PortA 
            inport(abus_s,data_s);
            assert dbus=X"B8" report "failure: Value read from PortA is not 0xB8" severity error;
            
            -- 2 Bytes come in without the CPU reading the first one

            pa <= X"10";
            pc(4)<='0';                     -- Assert STBA, strobe in 10 
            wait for 100 ns;
            pc(4)<='1';
            wait for 5 ns;
            pa <= (others => 'Z');
            wait for 20 ns;
            pa <= X"01";
            pc(4)<='0';                     -- Assert STBA, strobe in 01, 10 is lost 
            wait for 100 ns;
            pc(4)<='1';
            wait for 5 ns;
            pa <= (others => 'Z');
            
            abus_s <= "00";                 -- Read PortA 
            inport(abus_s,data_s);
            assert dbus=X"01" report "failure: Value read from PortA is not 0x01" severity error;


            ---------------------------------------------------------------------------
            -- Mode2/Mode0 Input test   
            -- See Figure16 Datasheets
            ---------------------------------------------------------------------------         

            write(L,string'("------- Test PortA Mode2, PortB Mode0 Input, PortC Output --------"));   
            writeline(output,L);

            pa <= (others => 'Z');
            pc <= (others => 'H');
            pb<=X"80";                      -- Read from PortB later
            pc(4)<='1'; -- stba
            pc(6)<='1'; -- acka

            data_s <= "11000010";           -- PortA Mode1, PortB Mode0 Input, PortC Output             
            write_control(data_s);

            abus_s <= "10";                 -- Write 00 to PortC, *** should not affect PortA ***  
            data_s <= X"00";                
            outport(abus_s,data_s);
            assert pc(7)='1' report "failure: OBFA affected by PortC 0x00 write" severity error;
            assert pc(5)='0' report "failure: IBFA affected by PortC 0x00 write" severity error;
            assert pc(3)='0' report "failure: INTRA affected by PortC 0x00 write" severity error;
            assert pc(2 downto 0)="000" report "failure: PC(2:0) not 000 after PortC 0x00 write" severity error;
        
            abus_s <= "10";                 -- Write FF to PortC, *** should not affect PortA ***  
            data_s <= X"FF";                
            outport(abus_s,data_s);
            assert pc(7)='1' report "failure: OBFA affected by PortC 0xFF write" severity error;
            assert pc(5)='0' report "failure: IBFA affected by PortC 0xFF write" severity error;
            assert pc(3)='0' report "failure: INTRA affected by PortC 0xFF write" severity error;
            assert pc(2 downto 0)="111" report "failure: PC(2:0) not 111 after PortC 0xFF write" severity error;
        
            -- Next write to PortA which should only set the OBFA flag
            abus_s <= "00";                 -- Write to PortA, assert OBFA, INTRA should still be low  
            data_s <= X"4C";                
            outport(abus_s,data_s);
            abus_s <= "01";                 -- Read from PortB
            inport(abus_s,data_s);

            abus_s <= "10";                 -- Write 00 to PortC, *** should not affect PortA ***  
            data_s <= X"00";                
            outport(abus_s,data_s);
            assert pc(7)='0' report "failure: OBFA affected by PortC 0x00 write" severity error;
            assert pc(5)='0' report "failure: IBFA affected by PortC 0x00 write" severity error;
            assert pc(3)='0' report "failure: INTRA affected by PortC 0x00 write" severity error;
            assert pc(2 downto 0)="000" report "failure: PC(2:0) not 000 after PortC 0x00 write" severity error;
        
            abus_s <= "10";                 -- Write FF to PortC, *** should not affect PortA ***  
            data_s <= X"FF";                
            outport(abus_s,data_s);
            assert pc(7)='0' report "failure: OBFA affected by PortC 0xFF write" severity error;
            assert pc(5)='0' report "failure: IBFA affected by PortC 0xFF write" severity error;
            assert pc(3)='0' report "failure: INTRA affected by PortC 0xFF write" severity error;
            assert pc(2 downto 0)="111" report "failure: PC(2:0) not 111 after PortC 0xFF write" severity error;

            -- Next Receive a byte which should only affect IBFA
            pa <= X"42";
            pc(4) <= '0';
            wait for 100 ns;
            pc(4) <= '1';
            pa <= (others => 'Z');

            abus_s <= "10";                 -- Write 00 to PortC, *** should not affect PortA ***  
            data_s <= X"00";                
            outport(abus_s,data_s);
            assert pc(7)='0' report "failure: OBFA affected by PortC 0x00 write" severity error;
            assert pc(5)='1' report "failure: IBFA affected by PortC 0x00 write" severity error;
            assert pc(3)='0' report "failure: INTRA affected by PortC 0x00 write" severity error;
            assert pc(2 downto 0)="000" report "failure: PC(2:0) not 000 after PortC 0x00 write" severity error;
        
            abus_s <= "10";                 -- Write FF to PortC, *** should not affect PortA ***  
            data_s <= X"FF";                
            outport(abus_s,data_s);
            assert pc(7)='0' report "failure: OBFA affected by PortC 0xFF write" severity error;
            assert pc(5)='1' report "failure: IBFA affected by PortC 0xFF write" severity error;
            assert pc(3)='0' report "failure: INTRA affected by PortC 0xFF write" severity error;
            assert pc(2 downto 0)="111" report "failure: PC(2:0) not 111 after PortC 0xFF write" severity error;

            
            ---------------------------------------------------------------------------
            -- Mode2/Mode1 Output test  
            -- See Figure16 Datasheets
            ---------------------------------------------------------------------------         

            write(L,string'("------- Test PortA Mode2, PortB Mode1 Output, PortC Output --------"));   
            writeline(output,L);

            pa <= (others => 'Z');
            pb <= (others => 'H');
            pc <= (others => 'H');
            
            pc(4)<='1'; -- stba
            pc(6)<='1'; -- acka

            data_s <= "11000100";           -- PortA Mode2, PortB Mode1 Output, PortC Output                
            write_control(data_s);


            abus_s <= "10";                 -- Write 00 to PortC, *** should not affect PortA ***  
            data_s <= X"00";                
            outport(abus_s,data_s);
            assert pc(7)='1' report "failure: OBFA affected by PortC 0x00 write" severity error;
            assert pc(1)='1' report "failure: OBFB affected by PortC 0x00 write" severity error;
            assert pc(5)='0' report "failure: IBFA affected by PortC 0x00 write" severity error;
            assert pc(3)='0' report "failure: INTRA affected by PortC 0x00 write" severity error;
            assert pc(0)='0' report "failure: INTRB affected by PortC 0x00 write" severity error;
        
            abus_s <= "10";                 -- Write FF to PortC, *** should not affect PortA ***  
            data_s <= X"FF";                
            outport(abus_s,data_s);
            assert pc(7)='1' report "failure: OBFA affected by PortC 0xFF write" severity error;
            assert pc(1)='1' report "failure: OBFB affected by PortC 0xFF write" severity error;
            assert pc(5)='0' report "failure: IBFA affected by PortC 0xFF write" severity error;
            assert pc(3)='0' report "failure: INTRA affected by PortC 0xFF write" severity error;
            assert pc(0)='0' report "failure: INTRB affected by PortC 0xFF write" severity error;
        
            -- Next write to PortA and B which should only set the OBFA and OBFB flag
            abus_s <= "00";                 -- Write to PortA, assert OBFA, INTRA should still be low  
            data_s <= X"4C";                
            outport(abus_s,data_s);
            abus_s <= "01";                 -- Write to PortB, assert OBFB, INTRA should still be low  
            data_s <= X"5D";                
            outport(abus_s,data_s);

            abus_s <= "10";                 -- Write 00 to PortC, *** should not affect PortA ***  
            data_s <= X"00";                
            outport(abus_s,data_s);
            assert pc(7)='0' report "failure: OBFA affected by PortC 0x00 write" severity error;
            assert pc(1)='0' report "failure: OBFB affected by PortC 0x00 write" severity error;
            assert pc(5)='0' report "failure: IBFA affected by PortC 0x00 write" severity error;
            assert pc(3)='0' report "failure: INTRA affected by PortC 0x00 write" severity error;
            assert pc(0)='0' report "failure: INTRB affected by PortC 0x00 write" severity error;
        
            abus_s <= "10";                 -- Write FF to PortC, *** should not affect PortA ***  
            data_s <= X"FF";                
            outport(abus_s,data_s);
            assert pc(7)='0' report "failure: OBFA affected by PortC 0xFF write" severity error;
            assert pc(1)='0' report "failure: OBFB affected by PortC 0xFF write" severity error;
            assert pc(5)='0' report "failure: IBFA affected by PortC 0xFF write" severity error;
            assert pc(3)='0' report "failure: INTRA affected by PortC 0xFF write" severity error;
            assert pc(0)='0' report "failure: INTRB affected by PortC 0xFF write" severity error;

            -- Next Receive a byte which should only affect IBFA
            pa <= X"42";
            pc(4) <= '0';
            wait for 100 ns;
            pc(4) <= '1';
            pa <= (others => 'Z');

            abus_s <= "10";                 -- Write 00 to PortC, *** should not affect PortA ***  
            data_s <= X"00";                
            outport(abus_s,data_s);
            assert pc(7)='0' report "failure: OBFA affected by PortC 0x00 write" severity error;
            assert pc(1)='0' report "failure: OBFB affected by PortC 0x00 write" severity error;
            assert pc(5)='1' report "failure: IBFA affected by PortC 0x00 write" severity error;
            assert pc(3)='0' report "failure: INTRA affected by PortC 0x00 write" severity error;
            assert pc(0)='0' report "failure: INTRB affected by PortC 0x00 write" severity error;
        
            abus_s <= "10";                 -- Write FF to PortC, *** should not affect PortA ***  
            data_s <= X"FF";                
            outport(abus_s,data_s);
            assert pc(7)='0' report "failure: OBFA affected by PortC 0xFF write" severity error;
            assert pc(1)='0' report "failure: OBFB affected by PortC 0xFF write" severity error;
            assert pc(5)='1' report "failure: IBFA affected by PortC 0xFF write" severity error;
            assert pc(3)='0' report "failure: INTRA affected by PortC 0xFF write" severity error;
            assert pc(0)='0' report "failure: INTRB affected by PortC 0xFF write" severity error;
            
            ---------------------------------------------------------------------------
            -- Mode2/Mode1 Input test   
            -- See Figure16 Datasheets
            ---------------------------------------------------------------------------         

            write(L,string'("------- Test PortA Mode2, PortB Mode1 Input, PortC Output --------"));   
            writeline(output,L);

            pa <= (others => 'Z');
            pb <= (others => 'H');
            pc <= (others => 'H');
            
            pc(4)<='1'; -- stba
            pc(6)<='1'; -- acka
            pc(2)<='1'; -- stbb

            data_s <= "11000110";           -- PortA Mode2, PortB Mode1 Input, PortC Output             
            write_control(data_s);


            abus_s <= "10";                 -- Write 00 to PortC, *** should not affect PortA ***  
            data_s <= X"00";                
            outport(abus_s,data_s);
            assert pc(7)='1' report "failure: OBFA affected by PortC 0x00 write" severity error;
            assert pc(5)='0' report "failure: IBFA affected by PortC 0x00 write" severity error;
            assert pc(1)='0' report "failure: IBFB affected by PortC 0x00 write" severity error;
            assert pc(3)='0' report "failure: INTRA affected by PortC 0x00 write" severity error;
            assert pc(0)='0' report "failure: INTRB affected by PortC 0x00 write" severity error;
        
            abus_s <= "10";                 -- Write FF to PortC, *** should not affect PortA ***  
            data_s <= X"FF";                
            outport(abus_s,data_s);
            assert pc(7)='1' report "failure: OBFA affected by PortC 0xFF write" severity error;
            assert pc(5)='0' report "failure: IBFA affected by PortC 0xFF write" severity error;
            assert pc(1)='0' report "failure: IBFB affected by PortC 0xFF write" severity error;
            assert pc(3)='0' report "failure: INTRA affected by PortC 0xFF write" severity error;
            assert pc(0)='0' report "failure: INTRB affected by PortC 0xFF write" severity error;
        
            -- Next write to PortA and stobe in a byte on port B only OBFA and IBFB flag should be set
            abus_s <= "00";                 -- Write to PortA, assert OBFA, INTRA should still be low  
            data_s <= X"4C";                
            outport(abus_s,data_s);
            pc(2) <= '0';                   -- Strobe in byte on PortB
            wait for 100 ns;
            pc(2) <= '1';

            abus_s <= "10";                 -- Write 00 to PortC, *** should not affect PortA ***  
            data_s <= X"00";                
            outport(abus_s,data_s);
            assert pc(7)='0' report "failure: OBFA affected by PortC 0x00 write" severity error;
            assert pc(5)='0' report "failure: IBFA affected by PortC 0x00 write" severity error;
            assert pc(1)='1' report "failure: IBFB affected by PortC 0x00 write" severity error;
            assert pc(3)='0' report "failure: INTRA affected by PortC 0x00 write" severity error;
            assert pc(0)='0' report "failure: INTRB affected by PortC 0x00 write" severity error;
        
            abus_s <= "10";                 -- Write FF to PortC, *** should not affect PortA ***  
            data_s <= X"FF";                
            outport(abus_s,data_s);
            assert pc(7)='0' report "failure: OBFA affected by PortC 0xFF write" severity error;
            assert pc(5)='0' report "failure: IBFA affected by PortC 0xFF write" severity error;
            assert pc(1)='1' report "failure: IBFB affected by PortC 0xFF write" severity error;
            assert pc(3)='0' report "failure: INTRA affected by PortC 0xFF write" severity error;
            assert pc(0)='0' report "failure: INTRB affected by PortC 0xFF write" severity error;

            -- Next Receive a byte which should only affect IBFA
            pa <= X"42";
            pc(4) <= '0';
            wait for 100 ns;
            pc(4) <= '1';
            pa <= (others => 'Z');

            abus_s <= "10";                 -- Write 00 to PortC, *** should not affect PortA ***  
            data_s <= X"00";                
            outport(abus_s,data_s);
            assert pc(7)='0' report "failure: OBFA affected by PortC 0x00 write" severity error;
            assert pc(5)='1' report "failure: IBFA affected by PortC 0x00 write" severity error;
            assert pc(1)='1' report "failure: IBFB affected by PortC 0x00 write" severity error;
            assert pc(3)='0' report "failure: INTRA affected by PortC 0x00 write" severity error;
            assert pc(0)='0' report "failure: INTRB affected by PortC 0x00 write" severity error;
        
            abus_s <= "10";                 -- Write FF to PortC, *** should not affect PortA ***  
            data_s <= X"FF";                
            outport(abus_s,data_s);
            assert pc(7)='0' report "failure: OBFA affected by PortC 0xFF write" severity error;
            assert pc(5)='1' report "failure: IBFA affected by PortC 0xFF write" severity error;
            assert pc(1)='1' report "failure: IBFB affected by PortC 0xFF write" severity error;
            assert pc(3)='0' report "failure: INTRA affected by PortC 0xFF write" severity error;
            assert pc(0)='0' report "failure: INTRB affected by PortC 0xFF write" severity error;


            ---------------------------------------------------------------------------
            -- Mode2/Mode1 Input test Interrupt enabled 
            -- See Figure16 Datasheets
            ---------------------------------------------------------------------------         

            write(L,string'("------- Test PortA Mode2, PortB Mode1 Input, PortC Output INTA --------"));   
            writeline(output,L);

            pa <= (others => 'Z');
            pb <= (others => 'H');
            pc <= (others => 'H');
            
            pc(4)<='1'; -- stba
            pc(6)<='1'; -- acka
            pc(2)<='1'; -- stbb

            data_s <= "11000110";           -- PortA Mode2, PortB Mode1 Input, PortC Output             
            write_control(data_s);

            abus_s <= "11";
            data_s <= "00000101";           -- Enable INTEB, PC2
            outport(abus_s,data_s);
            data_s <= "00001101";           -- Enable INTEA1 PC6
            outport(abus_s,data_s);
            data_s <= "00001001";           -- Enable INTEA2 PC4
            outport(abus_s,data_s);


            abus_s <= "10";                 -- Write 00 to PortC, *** should not affect PortA ***  
            data_s <= X"00";                
            outport(abus_s,data_s);
            assert pc(7)='1' report "failure: OBFA affected by PortC 0x00 write" severity error;
            assert pc(5)='0' report "failure: IBFA affected by PortC 0x00 write" severity error;
            assert pc(1)='0' report "failure: IBFB affected by PortC 0x00 write" severity error;
            assert pc(3)='0' report "failure: INTRA affected by PortC 0x00 write" severity error;
            assert pc(0)='0' report "failure: INTRB affected by PortC 0x00 write" severity error;
        
            abus_s <= "10";                 -- Write FF to PortC, *** should not affect PortA ***  
            data_s <= X"FF";                
            outport(abus_s,data_s);
            assert pc(7)='1' report "failure: OBFA affected by PortC 0xFF write" severity error;
            assert pc(5)='0' report "failure: IBFA affected by PortC 0xFF write" severity error;
            assert pc(1)='0' report "failure: IBFB affected by PortC 0xFF write" severity error;
            assert pc(3)='0' report "failure: INTRA affected by PortC 0xFF write" severity error;
            assert pc(0)='0' report "failure: INTRB affected by PortC 0xFF write" severity error;
        
            -- Next write to PortA and strobe in a byte on port B, OBFA/IBFB INTRA/INTRB should be set
            abus_s <= "00";                 -- Write to PortA, assert OBFA, INTRA should be low until ack  
            data_s <= X"4C";                
            outport(abus_s,data_s);
            pc(2) <= '0';                   -- Strobe in byte on PortB, INTRB set
            wait for 100 ns;
            pc(2) <= '1';

            abus_s <= "10";                 -- Write 00 to PortC, *** should not affect PortA ***  
            data_s <= X"00";                
            outport(abus_s,data_s);
            assert pc(7)='0' report "failure: OBFA affected by PortC 0x00 write" severity error;
            assert pc(5)='0' report "failure: IBFA affected by PortC 0x00 write" severity error;
            assert pc(1)='1' report "failure: IBFB affected by PortC 0x00 write" severity error;
            assert pc(3)='0' report "failure: INTRA affected by PortC 0x00 write" severity error;
            assert pc(0)='1' report "failure: INTRB affected by PortC 0x00 write" severity error;
        
            abus_s <= "10";                 -- Write FF to PortC, *** should not affect PortA ***  
            data_s <= X"FF";                
            outport(abus_s,data_s);
            assert pc(7)='0' report "failure: OBFA affected by PortC 0xFF write" severity error;
            assert pc(5)='0' report "failure: IBFA affected by PortC 0xFF write" severity error;
            assert pc(1)='1' report "failure: IBFB affected by PortC 0xFF write" severity error;
            assert pc(3)='0' report "failure: INTRA affected by PortC 0xFF write" severity error;
            assert pc(0)='1' report "failure: INTRB affected by PortC 0xFF write" severity error;


            pc(6) <= '0';                   -- Strobe ACKA, this should assert INTRA and clear OBFA
            wait for 100 ns;
            pc(6) <= '1';

            abus_s <= "10";                 -- Write 00 to PortC, *** should not affect PortA ***  
            data_s <= X"00";                
            outport(abus_s,data_s);
            assert pc(7)='1' report "failure: OBFA affected by PortC 0x00 write" severity error;
            assert pc(5)='0' report "failure: IBFA affected by PortC 0x00 write" severity error;
            assert pc(1)='1' report "failure: IBFB affected by PortC 0x00 write" severity error;
            assert pc(3)='1' report "failure: INTRA affected by PortC 0x00 write" severity error;
            assert pc(0)='1' report "failure: INTRB affected by PortC 0x00 write" severity error;
        
            abus_s <= "10";                 -- Write FF to PortC, *** should not affect PortA ***  
            data_s <= X"FF";                
            outport(abus_s,data_s);
            assert pc(7)='1' report "failure: OBFA affected by PortC 0xFF write" severity error;
            assert pc(5)='0' report "failure: IBFA affected by PortC 0xFF write" severity error;
            assert pc(1)='1' report "failure: IBFB affected by PortC 0xFF write" severity error;
            assert pc(3)='1' report "failure: INTRA affected by PortC 0xFF write" severity error;
            assert pc(0)='1' report "failure: INTRB affected by PortC 0xFF write" severity error;


            -- Next Receive a byte which should only affect IBFA
            pa <= X"53";
            pc(4) <= '0';
            wait for 100 ns;
            pc(4) <= '1';
            pa <= (others => 'Z');  
            -- Read PortB which should clear INTRB
            abus_s <= "01";                   
            inport(abus_s,data_s);
            -- Strobe ACKA to clear OBFA
            pc(6) <= '0';
            wait for 100 ns;
            pc(6) <= '1';


            abus_s <= "10";                 -- Write 00 to PortC, *** should not affect PortA ***  
            data_s <= X"00";                
            outport(abus_s,data_s);
            assert pc(7)='1' report "failure: OBFA affected by PortC 0x00 write" severity error;
            assert pc(5)='1' report "failure: IBFA affected by PortC 0x00 write" severity error;
            assert pc(1)='0' report "failure: IBFB affected by PortC 0x00 write" severity error;
            assert pc(3)='1' report "failure: INTRA affected by PortC 0x00 write" severity error;
            assert pc(0)='0' report "failure: INTRB affected by PortC 0x00 write" severity error;
        
            abus_s <= "10";                 -- Write FF to PortC, *** should not affect PortA ***  
            data_s <= X"FF";                
            outport(abus_s,data_s);
            assert pc(7)='1' report "failure: OBFA affected by PortC 0xFF write" severity error;
            assert pc(5)='1' report "failure: IBFA affected by PortC 0xFF write" severity error;
            assert pc(1)='0' report "failure: IBFB affected by PortC 0xFF write" severity error;
            assert pc(3)='1' report "failure: INTRA affected by PortC 0xFF write" severity error;
            assert pc(0)='0' report "failure: INTRB affected by PortC 0xFF write" severity error;
 
            ---------------------------------------------------------------------------
            -- Read PortC Status Mode1 Input    
            ---------------------------------------------------------------------------         
 
            write(L,string'("------- Test PortC Status Read Mode 0--------"));   
            writeline(output,L);
 
            pa <= (others => 'H');
            pb <= (others => 'H');
            pc <= (others => 'H');
            
            data_s <= "10011011";               -- PortA/B/C Input              
            write_control(data_s);
 
            abus_s <= "10";                     -- Read PortC 
            inport(abus_s,data_s);
 
            pc <= X"55";
            abus_s <= "10";                     -- Read PortC, Mode0 
            inport(abus_s,data_s);
            assert data_s=X"55" report "failure: PortC Read not 0x55" severity error;
            pc <= X"AA";
            abus_s <= "10";                     -- Read PortC, Mode0 
            inport(abus_s,data_s);
            assert data_s=X"AA" report "failure: PortC Read not 0xAA" severity error;
            
 
            write(L,string'("------- Test PortC Status Read, PortA/B=Mode1 Input, PortC input --------"));   
            writeline(output,L);
            
            pc <= (others => 'H');
            
            data_s <= "10111111";                               
            write_control(data_s);
 
            --------------------------------------------
            -- Input Mode1
            -- D7  D6  D5   D4     D3    D2    D1   D0
            -- I/O I/O IBFA INTEA2 INTRA INTEB IBFB INTRB
            --------------------------------------------
            pc(7 downto 6) <= "00"; 
            pc(4) <='1';                        -- STBA
            pc(2) <='1';                        -- STBB
            
            abus_s <= "10";                     -- Read PortC, Mode0 
            inport(abus_s,data_s);
            assert data_s="00000000" report "failure: PortC Read not 0x00" severity error;
 
            pc(7 downto 6) <= "11";             -- Change I/O bits
 
            abus_s <= "10";                     -- Read PortC, Mode0 
            inport(abus_s,data_s);
            assert data_s="11000000" report "failure: PortC Read not 0xC0" severity error;
 
            pc(4) <= '0';                       -- Strobe STBA, this should set IBFA
            wait for 100 ns;
            pc(4) <= '1';
            abus_s <= "10";                      
            inport(abus_s,data_s);
            assert data_s="11100000" report "failure: PortC Read incorrect IBFA" severity error;
 
            pc(2) <= '0';                           -- Strobe STBB, this should set IBFB
            wait for 100 ns;
            pc(2) <= '1';
            abus_s <= "10";                      
            inport(abus_s,data_s);
            assert data_s="11100010" report "failure: PortC Read incorrect IBFB" severity error;
 
            abus_s <= "00";
            inport(abus_s,data_s);                  -- Read PortA this clears IBFA
            abus_s <= "10";                      
            inport(abus_s,data_s);
            assert data_s="11000010" report "failure: PortC Read incorrect IBFA clear" severity error;
 
            abus_s <= "01";
            inport(abus_s,data_s);                  -- Read PortB this clears IBFB
            abus_s <= "10";                      
            inport(abus_s,data_s);
            assert data_s="11000000" report "failure: PortC Read incorrect IBFB clear" severity error;
 
 
            abus_s <= "11";
            data_s <= "00001001";                   -- Enable INTEA2 PC4
            outport(abus_s,data_s);
            abus_s <= "10";                      
            inport(abus_s,data_s);
            assert data_s="11010000" report "failure: PortC Read Incorrect INTEA2" severity error;
 
            pc(4) <= '0';                           -- Strobe STBA, this should set IBFA and INTRA
            wait for 100 ns;
            pc(4) <= '1';
            abus_s <= "10";                     
            inport(abus_s,data_s);
            assert data_s="11111000" report "failure: PortC Read not 0xF8" severity error;
  
            abus_s <= "11";
            data_s <= "00000101";                   -- Enable INTEB, PC2
            outport(abus_s,data_s);
            abus_s <= "10";                      
            inport(abus_s,data_s);
            assert data_s="11111100" report "failure: PortC Read expected 0xFD" severity error;
            
            pc(2) <= '0';                           -- Strobe STBB, this should set IBFB and INTRB
            wait for 100 ns;
            pc(2) <= '1';
            inport(abus_s,data_s);
            assert data_s="11111111" report "failure: PortC Read not 0xFF" severity error;
 
            abus_s <= "01";                         -- Read PortB which should clear IBFB and INTRB                     
            inport(abus_s,data_s);
            abus_s <= "10";
            inport(abus_s,data_s);
            assert data_s="11111100" report "failure: PortC Read not 0xFC" severity error;
        
    
            ---------------------------------------------------------------------------
            -- Read PortC Status Mode1 output   
            ---------------------------------------------------------------------------         
    
            write(L,string'("------- Test PortC Status Read, PortA/B=Mode1 Output, PortC input --------"));   
            writeline(output,L);
            
            pa <= (others => 'Z');
            pb <= (others => 'Z');
            pc <= (others => 'H');
            
            data_s <= "10101101";                               
            write_control(data_s);

            --------------------------------------------
            -- Output Mode1
            -- D7   D6     D5  D4  D3    D2    D1   D0
            -- OBFA INTEA1 I/O I/O INTRA INTEB OBFB INTRB
            --------------------------------------------
            pc <= (others => 'Z');
            pc(5 downto 4) <= "00"; 
            pc(6) <='1';                        -- ACKA
            pc(2) <='1';                        -- ACKB
            
            abus_s <= "10";                     -- Read PortC, Mode0 
            inport(abus_s,data_s);
            assert data_s="10000010" report "failure: PortC Read not 0x82" severity error;

            pc(5 downto 4) <= "11";             -- Change I/O bits

            abus_s <= "10";                     -- Read PortC, Mode0 
            inport(abus_s,data_s);
            assert data_s="10110010" report "failure: PortC Read not 0xB2" severity error;

            abus_s <= "00";                         -- Write to PortA, this should clear OBFA 
            data_s <= X"62";                    
            outport(abus_s,data_s);
            abus_s <= "10";                      
            inport(abus_s,data_s);
            assert data_s="00110010" report "failure: PortC Read incorrect OBFA" severity error;

            abus_s <= "01";                         -- Write to PortB, this should clear OBFB 
            data_s <= X"73";                    
            outport(abus_s,data_s);
            abus_s <= "10";                      
            inport(abus_s,data_s);
            assert data_s="00110000" report "failure: PortC Read incorrect OBFB" severity error;


            pc(6) <= '0';                           -- Strobe ACKA, this should set OBFA again
            wait for 100 ns;
            pc(6) <= '1';
            abus_s <= "10";                      
            inport(abus_s,data_s);
            assert data_s="10110000" report "failure: PortC Read incorrect OBFA" severity error;

            pc(2) <= '0';                           -- Strobe ACKB, this should set OBFB again
            wait for 100 ns;
            pc(2) <= '1';
            abus_s <= "10";                      
            inport(abus_s,data_s);
            assert data_s="10110010" report "failure: PortC Read incorrect OBFB" severity error;

            pc(5 downto 4) <= "00";                 -- Change I/O bits

            -- Note ACKA has already been strobed, this means that if you enable INTEA1 then INTRA line will 
            -- be asserted. It is unclear from the datasheets if this is the correct behaviour. Alternatively
            -- the INTRA is asserted only when the ACKA pulse occurs when INTEA1 is asserted. This can easily 
            -- be added if required.
            
            abus_s <= "11";
            data_s <= "00001101";                   -- Enable INTEA1 PC6, this will enable INTRA!!!
            outport(abus_s,data_s);
            abus_s <= "10";                      
            inport(abus_s,data_s);
            assert data_s="11001010" report "failure: PortC Read Incorrect INTEA1" severity error;


            abus_s <= "00";                         -- Write to PortA, this should clear OBFA and INTRA 
            data_s <= X"51";                    
            outport(abus_s,data_s);
            abus_s <= "10";                      
            inport(abus_s,data_s);
            assert data_s="01000010" report "failure: PortC Read incorrect OBFA" severity error;

 
            abus_s <= "11";
            data_s <= "00000101";                   -- Enable INTEB PC2, this should assert INTRB!!!
            outport(abus_s,data_s);
            abus_s <= "10";                      
            inport(abus_s,data_s);
            assert data_s="01000111" report "failure: PortC Read expected 0x47" severity error;
                    
            
            ---------------------------------------------------------------------------
            -- Read PortC Status Mode2, GroupB Input Mode 0 
            ---------------------------------------------------------------------------         
    
            write(L,string'("------- Test PortC Status Read, PortA Mode2, PortB input Mode0 --------"));   
            writeline(output,L);
            
            pa <= (others => 'Z');
            pb <= (others => 'Z');
            pc <= (others => 'H');
            
            data_s <= "11001011";                               
            write_control(data_s);

            --------------------------------------------
            -- Output Mode1
            -- D7   D6    D5   D4    D3    D2 D1 D0
            -- OBFA INTE1 IBFA INTE2 INTRA X  X  X
            --------------------------------------------
            pc <= (others => 'Z');
            pc(6) <='1';                        -- ACKA
            pc(4) <='1';                        -- STBA
            pc(2 downto 0)<="000";              -- Mode0 on PortB
            
            abus_s <= "10";                     -- Read PortC, Mode0 
            inport(abus_s,data_s);
            assert data_s="10000000" report "failure: PortC Read not 0x80" severity error;

            pc(2 downto 0)<="101";              -- Mode0 on PortB
            abus_s <= "10";                     -- Read PortC, Mode0 
            inport(abus_s,data_s);
            assert data_s="10000101" report "failure: PortC Read not 0x85" severity error;

            pc(2 downto 0)<="010";              -- Mode0 on PortB
            abus_s <= "10";                     -- Read PortC, Mode0 
            inport(abus_s,data_s);
            assert data_s="10000010" report "failure: PortC Read not 0x82" severity error;


            -- Write to PortA, this should assert OBFA
            abus_s <= "00";                         -- Write to PortA, this should assert OBFA 
            data_s <= X"21";                    
            outport(abus_s,data_s);
            abus_s <= "10";                      
            inport(abus_s,data_s);
            assert data_s="00000010" report "failure: PortC Read incorrect OBFA" severity error;

            pc(6) <= '0';                           -- Strobe ACKA, this should set OBFA again
            wait for 100 ns;
            pc(6) <= '1';
            abus_s <= "10";                      
            inport(abus_s,data_s);
            assert data_s="10000010" report "failure: PortC Read incorrect OBFA" severity error;


            abus_s <= "11";
            data_s <= "00001101";                   -- Enable INTEA1 PC6, this will enable INTRA!!!
            outport(abus_s,data_s);
            abus_s <= "10";                      
            inport(abus_s,data_s);
            assert data_s="11001010" report "failure: PortC Read Incorrect INTEA1" severity error;


            abus_s <= "11";
            data_s <= "00001001";                   -- Enable INTEA2 PC4
            outport(abus_s,data_s);
            abus_s <= "10";                      
            inport(abus_s,data_s);
            assert data_s="11011010" report "failure: PortC Read Incorrect INTEA2" severity error;


            abus_s <= "00";                         -- Write to PortA, this should clear OBFA and INTRA 
            data_s <= X"51";                    
            outport(abus_s,data_s);
            abus_s <= "10";                      
            inport(abus_s,data_s);
            assert data_s="01010010" report "failure: PortC Read incorrect OBFA & INTRA" severity error;


            abus_s <= "11";
            data_s <= "00001000";                   -- Disable INTEA2 PC4
            outport(abus_s,data_s);
            abus_s <= "10";                      
            inport(abus_s,data_s);
            assert data_s="01000010" report "failure: PortC Read Incorrect Clear INTEA2" severity error;
            

            pa <= X"53";                            -- Receive a byte by strobing stba, IBFA should be asserted
            pc(4) <= '0';
            wait for 100 ns;
            pc(4) <= '1';
            pa <= (others => 'Z');  


            abus_s <= "10";                      
            inport(abus_s,data_s);
            assert data_s="01100010" report "failure: PortC Read incorrect IBFA" severity error;


            abus_s <= "11";
            data_s <= "00001001";                   -- Enable INTEA2 PC4
            outport(abus_s,data_s);
            abus_s <= "10";                      
            inport(abus_s,data_s);
            assert data_s="01111010" report "failure: PortC Read Incorrect INTRA" severity error;



            ---------------------------------------------------------------------------
            -- Read PortC Status Mode2, GroupB Input Mode 1 
            ---------------------------------------------------------------------------         
    
            write(L,string'("------- Test PortC Status Read, PortA Mode2, PortB input Mode1 --------"));   
            writeline(output,L);
            
            pa <= (others => 'Z');
            pb <= (others => 'Z');
            pc <= (others => 'H');
            
            data_s <= "11001111";                               
            write_control(data_s);

            --------------------------------------------
            -- Output Mode1
            -- D7   D6    D5   D4    D3    D2    D1    D0
            -- OBFA INTE1 IBFA INTE2 INTRA INTEB IBFB INTRB
            --------------------------------------------
            pc <= (others => 'Z');
            pc(6) <='1';                        -- ACKA
            pc(4) <='1';                        -- STBA
            pc(2) <='1';                        -- STBB, Mode1 on PortB
            
            abus_s <= "10";                     -- Read PortC, Mode0 
            inport(abus_s,data_s);
            assert data_s="10000000" report "failure: PortC Read not 0x80" severity error;


            pc(2) <= '0';                           -- Strobe STBB, this should assert IBFB
            wait for 100 ns;
            pc(2) <= '1';
            abus_s <= "10";                      
            inport(abus_s,data_s);
            assert data_s="10000010" report "failure: PortC Read incorrect IBFB" severity error;
 
 
            abus_s <= "01";
            inport(abus_s,data_s);                  -- Read PortB this clears IBFB
            abus_s <= "10";                      
            inport(abus_s,data_s);
            assert data_s="10000000" report "failure: PortC Read incorrect IBFB clear" severity error;
 
 
            abus_s <= "11";
            data_s <= "00000101";                   -- Enable INTEB, PC2
            outport(abus_s,data_s);
            abus_s <= "10";                      
            inport(abus_s,data_s);
            assert data_s="10000100" report "failure: PortC Read expected 0x84" severity error;
 
            
            pc(2) <= '0';                           -- Strobe STBB, this should set IBFB and INTRB
            wait for 100 ns;
            pc(2) <= '1';
            inport(abus_s,data_s);
            assert data_s="10000111" report "failure: PortC Read not 0x87" severity error;
 
            abus_s <= "01";                         -- Read PortB which should clear IBFB and INTRB                     
            inport(abus_s,data_s);
            abus_s <= "10";
            inport(abus_s,data_s);
            assert data_s="10000100" report "failure: PortC Read not 0x84" severity error;

            -- Write to PortA, this should assert OBFA
            abus_s <= "00";                         -- Write to PortA, this should assert OBFA 
            data_s <= X"21";                    
            outport(abus_s,data_s);
            abus_s <= "10";                      
            inport(abus_s,data_s);
            assert data_s="00000100" report "failure: PortC Read incorrect OBFA" severity error;

            pc(6) <= '0';                           -- Strobe ACKA, this should set OBFA again
            wait for 100 ns;
            pc(6) <= '1';
            abus_s <= "10";                      
            inport(abus_s,data_s);
            assert data_s="10000100" report "failure: PortC Read incorrect OBFA" severity error;

            abus_s <= "11";
            data_s <= "00001101";                   -- Enable INTE1, PC6
            outport(abus_s,data_s);
            abus_s <= "11";
            data_s <= "00001001";                   -- Enable INTE2, PC4
            outport(abus_s,data_s);

            abus_s <= "10";                      
            inport(abus_s,data_s);
            assert data_s="11011100" report "failure: PortC Read expected 0xDC" severity error;


            assert false report "************ End of Test ***************" severity failure;

            wait;
    end process; 

END ARCHITECTURE behaviour;
