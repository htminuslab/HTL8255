-------------------------------------------------------------------------------
--  HTL8255 - PPI core                                                       --
--                                                                           --
--  https://github.com/htminuslab                                            --
--                                                                           --
-------------------------------------------------------------------------------
-- Project       : HTL8255                                                   --
-- Purpose       : Toplevel including Tri-State Drivers                      --
-- Library       : I8088                                                     --
--                                                                           --
-- Version       : 1.0  20/01/2002   Created HT-LAB                          --
--               : 1.1  30/11/2023   cleaned and uploaded to github          --
-------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY HTL8255_TriState IS
   PORT( 
      abus  : IN     std_logic_vector (1 DOWNTO 0);
      clk   : IN     std_logic;
      csn   : IN     std_logic;
      rdn   : IN     std_logic;
      reset : IN     std_logic;
      wrn   : IN     std_logic;
      dbus  : INOUT  std_logic_vector (7 DOWNTO 0);
      pa    : INOUT  std_logic_vector (7 DOWNTO 0);
      pb    : INOUT  std_logic_vector (7 DOWNTO 0);
      pc    : INOUT  std_logic_vector (7 DOWNTO 0)
   );
END HTL8255_TriState ;

ARCHITECTURE struct OF HTL8255_TriState IS

   -- Architecture declarations

   -- Internal signal declarations
   SIGNAL dbusin  : std_logic_vector(7 DOWNTO 0);
   SIGNAL dbusout : std_logic_vector(7 DOWNTO 0);
   SIGNAL pa_in   : std_logic_vector(7 DOWNTO 0);
   SIGNAL pa_out  : std_logic_vector(7 DOWNTO 0);
   SIGNAL pa_rd   : std_logic;
   SIGNAL pb_in   : std_logic_vector(7 DOWNTO 0);
   SIGNAL pb_out  : std_logic_vector(7 DOWNTO 0);
   SIGNAL pb_rd   : std_logic;
   SIGNAL pc_in   : std_logic_vector(7 DOWNTO 0);
   SIGNAL pc_out  : std_logic_vector(7 DOWNTO 0);
   SIGNAL pc_rd   : std_logic_vector(7 DOWNTO 0);

   SIGNAL rdn_s   : std_logic;

   -- Component Declarations
   COMPONENT HTL8255
   PORT (
      abus    : IN     std_logic_vector (1 DOWNTO 0);
      clk     : IN     std_logic ;
      csn     : IN     std_logic ;
      dbusin  : IN     std_logic_vector (7 DOWNTO 0);
      pa_in   : IN     std_logic_vector (7 DOWNTO 0);
      pb_in   : IN     std_logic_vector (7 DOWNTO 0);
      pc_in   : IN     std_logic_vector (7 DOWNTO 0);
      rdn     : IN     std_logic ;
      reset   : IN     std_logic ;
      wrn     : IN     std_logic ;
      dbusout : OUT    std_logic_vector (7 DOWNTO 0);
      pa_out  : OUT    std_logic_vector (7 DOWNTO 0);
      pa_rd   : OUT    std_logic ;
      pb_out  : OUT    std_logic_vector (7 DOWNTO 0);
      pb_rd   : OUT    std_logic ;
      pc_out  : OUT    std_logic_vector (7 DOWNTO 0);
      pc_rd   : OUT    std_logic_vector (7 DOWNTO 0)
   );
   END COMPONENT;


BEGIN
   -- Architecture concurrent statements
   -- HDL Embedded Text Block 1 eb1
   -- eb1 1     
   process (pa_rd,pa_out)
       begin  
           case pa_rd is
               when '0'    => pa<= pa_out after 10 ns;     -- drive PortA
               when '1'    => pa<= (others => 'Z') after 10 ns;
               when others => pa<= (others => 'X') after 10 ns;         
           end case;    
   end process;   
   pa_in <= pa;                                            -- drive internal pa_in bus                                           

   -- HDL Embedded Text Block 2 eb2
   -- eb2 2                
   process (pb_rd,pb_out)
       begin  
           case pb_rd is
               when '0'    => pb<= pb_out after 10 ns;     -- drive PortB
               when '1'    => pb<= (others => 'Z') after 10 ns;
               when others => pb<= (others => 'X') after 10 ns;         
           end case;    
   end process;   
   pb_in <= pb;                                            -- drive internal pb_in bus                                   

   -- HDL Embedded Text Block 3 eb3
   -- eb3 3 
   pctri:for i in 0 to 7 generate
   
      process (pc_rd,pc_out)
          begin  
                 case pc_rd(i) is
                     when '0'    => pc(i)<= pc_out(i) after 10 ns; -- drive PortC
                     when '1'    => pc(i)<= 'Z' after 10 ns;
                     when others => pc(i)<= 'X' after 10 ns;         
                 end case;   
      end process;  
      end generate pctri; 
       
   pc_in <= pc;                                            -- drive internal pc_in bus                                             

   -- HDL Embedded Text Block 4 eb4
   -- eb1 1  
   rdn_s <= '0' when rdn='0' AND csn='0' else '1';   
   process (rdn_s,dbusout)
       begin  
           case rdn_s is
               when '0'    => dbus<= dbusout after 10 ns;  -- drive databus
               when others => dbus<= (others => 'Z') after 10 ns;         
           end case;    
   end process;   
   dbusin <= dbus;                                         -- drive internal databus                                           


   -- Instance port mappings.
   U_0 : HTL8255
      PORT MAP (
         abus    => abus,
         clk     => clk,
         csn     => csn,
         dbusin  => dbusin,
         pa_in   => pa_in,
         pb_in   => pb_in,
         pc_in   => pc_in,
         rdn     => rdn,
         reset   => reset,
         wrn     => wrn,
         dbusout => dbusout,
         pa_out  => pa_out,
         pa_rd   => pa_rd,
         pb_out  => pb_out,
         pb_rd   => pb_rd,
         pc_out  => pc_out,
         pc_rd   => pc_rd
      );

END struct;
