-------------------------------------------------------------------------------
--  HTL8255 - PPI core                                                       --
--                                                                           --
--  https://github.com/htminuslab                                            --
--                                                                           --
-------------------------------------------------------------------------------
-- Project       : HTL8255                                                   --
-- Purpose       : Toplevel                                                  --
-- Library       : I8088                                                     --
--                                                                           --
-- Version       : 1.0  20/01/2002   Created HT-LAB                          --
--               : 1.0a 25/05/2009   Added pragma's around assertion         --
--               : 1.1  30/11/2023   cleaned and uploaded to github          --
-------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;

ENTITY HTL8255 IS
   PORT( 
      abus    : IN     std_logic_vector (1 DOWNTO 0);
      clk     : IN     std_logic;
      csn     : IN     std_logic;
      dbusin  : IN     std_logic_vector (7 DOWNTO 0);
      pa_in   : IN     std_logic_vector (7 DOWNTO 0);
      pb_in   : IN     std_logic_vector (7 DOWNTO 0);
      pc_in   : IN     std_logic_vector (7 DOWNTO 0);
      rdn     : IN     std_logic;
      reset   : IN     std_logic;
      wrn     : IN     std_logic;
      dbusout : OUT    std_logic_vector (7 DOWNTO 0);
      pa_out  : OUT    std_logic_vector (7 DOWNTO 0);
      pa_rd   : OUT    std_logic;
      pb_out  : OUT    std_logic_vector (7 DOWNTO 0);
      pb_rd   : OUT    std_logic;
      pc_out  : OUT    std_logic_vector (7 DOWNTO 0);
      pc_rd   : OUT    std_logic_vector (7 DOWNTO 0)
   );
END HTL8255 ;

ARCHITECTURE struct OF HTL8255 IS

    -- Architecture declarations

    -- Internal signal declarations
    signal acka         : std_logic;
    signal ackb         : std_logic;
    signal bitsel       : std_logic_vector(2 DOWNTO 0);
    signal bitval       : std_logic;
    signal changemode   : std_logic;
    signal control_word : std_logic_vector(6 DOWNTO 0);
    signal control_wr   : std_logic;
    signal dbuspa       : std_logic_vector(7 DOWNTO 0);
    signal dbuspb       : std_logic_vector(7 DOWNTO 0);
    signal dbuspc       : std_logic_vector(7 DOWNTO 0);
    signal ibfa         : std_logic;
    signal ibfb         : std_logic;
    signal intea1       : std_logic;
    signal intea2       : std_logic;
    signal inteb        : std_logic;
    signal intra        : std_logic;
    signal intrb        : std_logic;
    signal obfa         : std_logic;
    signal obfb         : std_logic;
    signal porta_wr     : std_logic;
    signal portb_wr     : std_logic;
    signal portc_wr     : std_logic;
    signal rdfe_s       : std_logic;
    signal rdfea_s      : std_logic;
    signal rdfeb_s      : std_logic;
    signal rdre_s       : std_logic;
    signal setres       : std_logic;
    signal stba         : std_logic;
    signal stbb         : std_logic;
    signal wrfe_s       : std_logic;
    signal wrfea_s      : std_logic;
    signal wrfeb_s      : std_logic;
    signal wrre_s       : std_logic;

    signal dind1_s      : std_logic;
    signal dind2_s      : std_logic;
    signal abus_s       : std_logic_vector(1 downto 0);
    signal pa_reg       : std_logic_vector(7 downto 0);
    signal pb_reg       : std_logic_vector(7 downto 0);
    signal pcl_reg      : std_logic_vector(3 downto 0);
    signal pch_reg      : std_logic_vector(3 downto 0);
    signal pa_in_latched: std_logic_vector(7 downto 0);
    signal pb_in_latched: std_logic_vector(7 downto 0);

    signal wrn_s        : std_logic;
    signal rdn_s        : std_logic;

    signal rdrea_s      : std_logic;
    signal wrrea_s      : std_logic;
    signal rdreb_s      : std_logic;
    signal wrreb_s      : std_logic;

   -- Component Declarations
   COMPONENT intra_fsm
   PORT (
      acka         : IN     std_logic ;
      changemode   : IN     std_logic ;
      clk          : IN     std_logic ;
      control_word : IN     std_logic_vector (6 DOWNTO 0);
      ibfa         : IN     std_logic ;
      intea1       : IN     std_logic ;
      intea2       : IN     std_logic ;
      obfa         : IN     std_logic ;
      rdfea_s      : IN     std_logic ;
      reset        : IN     std_logic ;
      stba         : IN     std_logic ;
      wrfea_s      : IN     std_logic ;
      intra        : OUT    std_logic 
   );
   END COMPONENT;
   COMPONENT intrb_fsm
   PORT (
      ackb         : IN     std_logic ;
      changemode   : IN     std_logic ;
      clk          : IN     std_logic ;
      control_word : IN     std_logic_vector (6 DOWNTO 0);
      ibfb         : IN     std_logic ;
      inteb        : IN     std_logic ;
      obfb         : IN     std_logic ;
      rdfeb_s      : IN     std_logic ;
      reset        : IN     std_logic ;
      stbb         : IN     std_logic ;
      wrfeb_s      : IN     std_logic ;
      intrb        : OUT    std_logic 
   );
   END COMPONENT;


BEGIN
  
    -- Architecture concurrent statements
	--1.0a
	-- pragma synthesis_off
    assert not (rdn='0' and wrn='0') report "Failure RD and WR strobe both asserted at the same time"
                                    severity failure;	
	-- pragma synthesis_on

    wrn_s   <= '0' when (wrn='0' and csn='0') else '1';
    rdn_s   <= '0' when (rdn='0' and csn='0') else '1';

    porta_wr   <= '1' when (abus="00" and wrn_s='0') else '0';
    portb_wr   <= '1' when (abus="01" and wrn_s='0') else '0';
    portc_wr   <= '1' when (abus="10" and wrn_s='0') else '0';
    control_wr <= '1' when (abus="11" and wrn_s='0') else '0';

    -------------------------------------------------------------------------------
    -- Reset all registers when changing mode (d7=1)
    -------------------------------------------------------------------------------
    changemode <= '1' when (abus="11" and wrn_s='0' and dbusin(7)='1') else '0';

    process (clk,reset)                         
       begin
           if (reset='1') then                     
               dind1_s <= '1';  
               abus_s <= "00";
           elsif rising_edge(clk) then     
               dind1_s <= rdn_s;                        -- First delay
               abus_s  <= abus;
           end if;   
    end process;    

    rdre_s <= '1' when (rdn_s='1' and dind1_s='0') else '0';   -- Rising edge of rdn
    rdfe_s <= '1' when (rdn_s='0' and dind1_s='1') else '0';   -- Falling edge of rdn

    process (clk,reset)                         
       begin
           if (reset='1') then                     
               dind2_s <= '1';  
           elsif rising_edge(clk) then     
               dind2_s <= wrn_s;           -- First delay
           end if;   
    end process;    

    wrre_s <= '1' when (wrn_s='1' and dind2_s='0') else '0';   -- Rising edge of wrn
    wrfe_s <= '1' when (wrn_s='0' and dind2_s='1') else '0';   -- Falling edge of wrn


    rdrea_s <= '1' when rdre_s='1' and abus_s="00" else '0';   -- Pulse on PA read rising edge
    wrrea_s <= '1' when wrre_s='1' and abus_s="00" else '0';   -- Pulse on PA write rising edge
    rdfea_s <= '1' when rdfe_s='1' and abus_s="00" else '0';   -- Pulse on PA read falling edge
    wrfea_s <= '1' when wrfe_s='1' and abus_s="00" else '0';   -- Pulse on PA write falling edge

    rdreb_s <= '1' when rdre_s='1' and abus_s="01" else '0';   -- Pulse on PB read rising edge
    wrreb_s <= '1' when wrre_s='1' and abus_s="01" else '0';   -- Pulse on PB write rising edge
    rdfeb_s <= '1' when rdfe_s='1' and abus_s="01" else '0';   -- Pulse on PB read falling edge
    wrfeb_s <= '1' when wrfe_s='1' and abus_s="01" else '0';   -- Pulse on PB write falling edge

    -- control 2  
    process(reset,clk)
       begin
           if reset='1' then
               control_word<="0011011";                 -- All ports to input & mode0
           elsif rising_edge(clk) then
               if (control_wr='1' and dbusin(7)='1') then
                   control_word<=dbusin(6 downto 0);
               end if;
           end if;
    end process;                                                     

    -- Output databus to Processor
    process(abus, dbuspa, dbuspb, dbuspc,control_word)
       begin
           case abus is
               when "00"   => dbusout <= dbuspa;  
               when "01"   => dbusout <= dbuspb;
               when "10"   => dbusout <= dbuspc;
               when others => dbusout <= '1'&control_word;-- D7 always one when reading control word
           end case;
    end process;

    -- Control bits for Bit Set/Reset option on PortC
    setres <= '1' when (control_wr='1' and dbusin(7)='0') else '0';
    bitsel <= dbusin(3 downto 1);
    bitval <= dbusin(0);                                -- New bit value

    -------------------------------------------------------------------------------
    -- PortA Output Register
    -- Changing mode will reset the register
    -------------------------------------------------------------------------------
    process(clk,reset)
       begin
           if reset='1' then
               pa_reg<=(others=>'0');
           elsif rising_edge(clk) then
               if changemode='1' then
                   pa_reg<=(others=>'0');
               elsif porta_wr='1' and control_word(4)='0' then -- PortA write
                   pa_reg<= dbusin;
               end if;
           end if;
    end process;


    -------------------------------------------------------------------------------
    -- PortA Input Register used for Mode1 and Mode2 only
    -- Data is strobed in using the STBA signal. 
    -- Note input is registered and not latched as with the original 8255, this means
    -- that the clock period must be higher than the strobe period!
    -------------------------------------------------------------------------------
    process(clk,reset)
       begin
           if reset='1' then
               pa_in_latched<=(others=>'0');
           elsif rising_edge(clk) then
               if stba='0' then
                   pa_in_latched<= pa_in;
               end if;
           end if;
    end process;

    -------------------------------------------------------------------------------
    -- PortA Tri-State Output Register
    -- Note pa_rd=0 for output, 1 for input
    -- Output is controlled by ACKA when in mode2
    -------------------------------------------------------------------------------
    pa_rd <= control_word(4) when control_word(6)='0' else acka;     

    -------------------------------------------------------------------------------
    -- PortA out 
    -------------------------------------------------------------------------------
    pa_out <= pa_reg;
                   
    -------------------------------------------------------------------------------
    -- PortA to processor
    -- Mode0 non-latched, mode1/2 latched (Registered) 
    -------------------------------------------------------------------------------
    dbuspa <= pa_in when control_word(6 downto 5)="00" else pa_in_latched;

    -------------------------------------------------------------------------------
    -- Mode1/2 Input IBF flag
    -- A 'high' on the IBF output indicates that the data has been loaded into the 
    -- input latch; in essence, an acknowledgement. IBF is set by STB input being
    -- low and is reset by the rising edge of the RD input.
    -- Changing mode clears this bit
    -------------------------------------------------------------------------------
    process (clk, reset)        
       begin
           if reset='1' then
               ibfa <= '0';       
           elsif rising_edge(clk) then 
               if (rdrea_s='1' or changemode='1') then
                  ibfa <= '0';   
               else 
                  ibfa <= (not stba) or ibfa;
               end if;
           end if;    
    end process;


    -------------------------------------------------------------------------------
    -- Mode1/2 Output OBF flag
    -- The OBF output will go 'low' to indicate that the CPU has written data
    -- out to the specified port. The OBF F/F will be set by the rising edge of the 
    -- WR input and reset by ACK Input being low.
    -- Changing modes sets this bit
    -------------------------------------------------------------------------------
    process (clk, reset)        
       begin
           if reset='1' then
               obfa <= '1';       
           elsif rising_edge(clk) then  
               if (acka='0' or changemode='1') then
                   obfa <= '1';    
               elsif wrrea_s='1' then 
                   obfa <= '0';
               end if;
          end if;    
    end process;

    -- HDL Embedded Text Block 4 portc
    -- PortC 4  
    stba <= pc_in(4);
    stbb <= pc_in(2);
    acka <= pc_in(6);
    ackb <= pc_in(2);


    -------------------------------------------------------------------------------
    -- PortC Output Register
    -- Split into two 4 bits regs
    -- Bits can be set/reset by setting control_word(7)=0
    -- Changing mode clears the registers
    -------------------------------------------------------------------------------
    process(clk,reset)
       begin
           if reset='1' then
               pcl_reg<=(others=>'0');
               pch_reg<=(others=>'0');
           elsif rising_edge(clk) then
               if changemode='1' then
                   pcl_reg<=(others=>'0');
                   pch_reg<=(others=>'0');
               elsif setres='1' then                    -- setting/clearing individual bits
                   case bitsel is
                       when "000"  => pcl_reg  <= pcl_reg(3 downto 1) & bitval;
                       when "001"  => pcl_reg  <= pcl_reg(3 downto 2) & bitval & pcl_reg(0);   
                       when "010"  => pcl_reg  <= pcl_reg(3) & bitval & pcl_reg(1 downto 0);   
                       when "011"  => pcl_reg  <= bitval & pcl_reg(2 downto 0);    
                       when "100"  => pch_reg  <= pch_reg(3 downto 1) & bitval;
                       when "101"  => pch_reg  <= pch_reg(3 downto 2) & bitval & pch_reg(0);   
                       when "110"  => pch_reg  <= pch_reg(3) & bitval & pch_reg(1 downto 0);   
                       when others => pch_reg  <= bitval & pch_reg(2 downto 0);    
                   end case;
               elsif portc_wr='1' then                  -- Mode0 
                   if control_word(0)='0' then          -- PortC lower Output  
                       pcl_reg <= dbusin(3 downto 0);
                   end if;     
                   if control_word(3)='0' then          -- PortC upper Output
                       pch_reg <= dbusin(7 downto 4);
                   end if;     
               end if;
           end if;
    end process;

    -------------------------------------------------------------------------------
    -- Interrupt enable bits
    -- Bits can be set/reset by setting control_word(7)=0
    -- Changing mode clears the registers
    -------------------------------------------------------------------------------
    process(clk,reset)
       begin
           if reset='1' then
            inteb  <= '0';                              -- PC2
            intea1 <= '0';                              -- PC6
            intea2 <= '0';                              -- PC4
           elsif rising_edge(clk) then
               if changemode='1' then
                  inteb  <= '0';   
                  intea1 <= '0';  
                  intea2 <= '0';  
               elsif setres='1' then                    -- setting/clearing individual bits
                   case bitsel is
                       when "010"  => inteb  <= bitval;   
                       when "100"  => intea2 <= bitval;
                       when "110"  => intea1 <= bitval;   
                       when others => NULL;    
                   end case;
               end if;
           end if;
    end process;

    -------------------------------------------------------------------------------
    -- PortC Tri-State Output Mux
    -- Note pc_rd=0 for output, 1 for input
    -------------------------------------------------------------------------------
    process(control_word)
       begin
           -- PortA
           if control_word(6 downto 4)="011" then       -- Mode1 PA, strobed Input
               pc_rd(7 downto 3) <= control_word(3)&control_word(3)&"010";
           elsif control_word(6 downto 4)="010" then    -- Mode1 PA, strobed Output
               pc_rd(7 downto 3) <= "01"&control_word(3)&control_word(3)&"0";
           elsif control_word(6)='1' then               -- Mode2, Bidirectional
               pc_rd(7 downto 3) <= "01010";
           else                                         -- Mode0, Basic I/O
               pc_rd(7 downto 3) <= control_word(3)&control_word(3)&control_word(3)&control_word(3) &
                        control_word(0);
           end if;

           -- PortB
           if control_word(2 downto 1)="11" then        -- Mode1, PB strobed Input
               pc_rd(2 downto 0) <= "100";
           elsif control_word(2 downto 1)="10" then     -- Mode1, PB strobed Output
               pc_rd(2 downto 0) <= "100";
           else                                         -- Mode0, Basic I/O
               pc_rd(2 downto 0) <= control_word(0)&control_word(0)&control_word(0);
           end if;

    end process;


    -------------------------------------------------------------------------------
    -- PortC Output
    -- GroupA & GroupB
    -------------------------------------------------------------------------------
    process(pch_reg,pcl_reg,control_word,ibfa,ibfb,obfa,obfb,intra,intrb)
       begin
                                   
           if control_word(6 downto 4)="011" then       -- PA=Mode1-Input
               pc_out(7 downto 3) <= pch_reg(3 downto 2)& ibfa & '-' & intra; -- don't care is stba (input)
           
           elsif control_word(6 downto 4)="010" then    -- PA=Mode1-Output
               pc_out(7 downto 3) <= obfa & '-' & pch_reg(1 downto 0)& intra; -- don't care is acka (input)
           
           elsif control_word(6)='1' then               -- PA=Mode2
               pc_out(7 downto 3) <= obfa & '-' & ibfa & '-' & intra;      -- don't care is acka and stba
           
           else                                         -- Mode0
               pc_out(7 downto 3) <= pch_reg&pcl_reg(3);                       
           end if;

           if control_word(2 downto 1)="11" then        -- PB=Mode1-Input
               pc_out(2 downto 0) <= '-' & ibfb & intrb;

           elsif control_word(2 downto 1)="10" then     -- PB=Mode1-Output
               pc_out(2 downto 0) <= '-' & obfb & intrb;

           else                                         -- PA=Mode2 and Mode0 
               pc_out(2 downto 0) <= pcl_reg(2 downto 0);      
           end if;

    end process;


    -------------------------------------------------------------------------------
    -- PortC dbuspc mux
    -- GroupA & GroupB
    -- During a read of Port C, the state of all the Port C lines, except the ACK 
    -- and STB lines, will be placed on the data bus. In place of the ACK and STB 
    -- line states, INTE flag status will appear on the data bus in the PC2, PC4
    -- and PC6 bit positions
    -- INTEB  PC2 ACKB (Output Mode 1) or STBB (Input Mode 1)
    -- INTEA2 PC4 STBA (Input Mode 1 or Mode 2)
    -- INTEA1 PC6 ACKA (Output Mode 1 or Mode 2
    -------------------------------------------------------------------------------
    process(control_word,pc_in,intea1,intea2,inteb,intra,intrb)
       begin
                                   
           if control_word(6 downto 4)="011" then       -- PA=Mode1-Input
               dbuspc(7 downto 3) <= pc_in(7 downto 5)& intea2 & intra; -- intea2=stba
           elsif control_word(6 downto 4)="010" then    -- PA=Mode1-Output
               dbuspc(7 downto 3) <= pc_in(7) & intea1 & pc_in(5 downto 4) & intra;-- intea1=acka
           elsif control_word(6)='1' then               -- PA=Mode2
               dbuspc(7 downto 3) <= pc_in(7) & intea1 & pc_in(5) & intea2 & intra;   -- intea1=acka intea2=stba
           else                                         -- Mode0
               dbuspc(7 downto 3) <= pc_in(7 downto 3);                       
           end if;

           if control_word(2)='1' then                  -- PB=Mode1
               dbuspc(2 downto 0) <= inteb & pc_in(1) & intrb;             -- inteb=ackb
           else                                         -- PB=Mode0 
               dbuspc(2 downto 0) <= pc_in(2 downto 0);
           end if;

    end process;

    -------------------------------------------------------------------------------
    -- PortB Output Register
    -- Changing mode will reset the register
    -------------------------------------------------------------------------------
    process(clk,reset)
       begin
           if reset='1' then
               pb_reg<=(others=>'0');
           elsif rising_edge(clk) then
               if changemode='1' then
                   pb_reg<=(others=>'0');
               elsif portb_wr='1' and control_word(1)='0' then -- PortB write
                   pb_reg<= dbusin;
               end if;
           end if;
    end process;

    -------------------------------------------------------------------------------
    -- PortB Input Register used for Mode1 and Mode2 only
    -- Data is strobed in using the STBB signal. 
    -- Note input is registered and not latched as with the original 8255, this means
    -- that the clock period must be higher than the strobe period!
    -------------------------------------------------------------------------------
    process(clk,reset)
       begin
           if reset='1' then
               pb_in_latched<=(others=>'0');
           elsif rising_edge(clk) then
               if stbb='0' then
                   pb_in_latched<= pb_in;
               end if;
           end if;
    end process;

    -------------------------------------------------------------------------------
    -- PortB Tri-State Output Register
    -- Note pb_rd=0 for output, 1 for input
    -------------------------------------------------------------------------------
    pb_rd <= control_word(1);     

    -------------------------------------------------------------------------------
    -- PortB out 
    -------------------------------------------------------------------------------
    pb_out <= pb_reg;
                   
    -------------------------------------------------------------------------------
    -- PortB to processor 
    -- Mode0 non-latched, mode1/2 latched (Registered) 
    -------------------------------------------------------------------------------
    dbuspb <= pb_in when control_word(2)='0' else pb_in_latched;


    -------------------------------------------------------------------------------
    -- Mode1/2 Input IBF flag
    -- A 'high' on the IBF output indicates that the data has been loaded into the 
    -- input latch; in essence, an acknowledgement. IBF is set by STB input being
    -- low and is reset by the rising edge of the RD input.
    -- Changing mode clears this bit
    -------------------------------------------------------------------------------
    process (clk, reset)        
       begin
           if reset='1' then
               ibfb <= '0';       
           elsif rising_edge(clk) then 
               if (rdreb_s='1' or changemode='1') then
                   ibfb <= '0';   
               else 
                   ibfb <= (not stbb) or ibfb;
               end if;
           end if;    
    end process;

    -------------------------------------------------------------------------------
    -- Mode1/2 Output OBF flag
    -- The OBF output will go 'low' to indicate that the CPU has written data
    -- out to the specified port. The OBF F/F will be set by the rising edge of the 
    -- WR input and reset by ACK Input being low.
    -- Changing mode sets this bit
    -------------------------------------------------------------------------------
    process (clk, reset)        
       begin
           if reset='1' then
               obfb <= '1';       
           elsif rising_edge(clk) then
               if (ackb='0' or changemode='1') then
                   obfb <= '1'; 
               elsif wrreb_s='1' then 
                   obfb <= '0';
               end if;
          end if;    
    end process;


    -- Instance port mappings.
    U_0 : intra_fsm
    PORT MAP (
        acka         => acka,
        changemode   => changemode,
        clk          => clk,
        control_word => control_word,
        ibfa         => ibfa,
        intea1       => intea1,
        intea2       => intea2,
        obfa         => obfa,
        rdfea_s      => rdfea_s,
        reset        => reset,
        stba         => stba,
        wrfea_s      => wrfea_s,
        intra        => intra
    );
    U_1 : intrb_fsm
    PORT MAP (
        ackb         => ackb,
        changemode   => changemode,
        clk          => clk,
        control_word => control_word,
        ibfb         => ibfb,
        inteb        => inteb,
        obfb         => obfb,
        rdfeb_s      => rdfeb_s,
        reset        => reset,
        stbb         => stbb,
        wrfeb_s      => wrfeb_s,
        intrb        => intrb
    );

END struct;