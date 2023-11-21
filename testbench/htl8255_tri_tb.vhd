-------------------------------------------------------------------------------
--  HTL8255 - PPI core                                                       --
--                                                                           --
--  https://github.com/htminuslab                                            --
--                                                                           --
-------------------------------------------------------------------------------
--  Project       : HTL8255                                                  --
--  Purpose       : TestBench                                                --
--  Library       : I8088                                                    --
--                                                                           --
--  Version       : 1.0  20/01/2002   Created HT-LAB                         --
--                : 1.1  21/11/2023   cleaned and uploaded to github         --
-- ----------------------------------------------------------------------------

ENTITY HTL8255_TriState_tb IS
END HTL8255_TriState_tb ;

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

LIBRARY std;
USE std.TEXTIO.all;

USE work.utils.all;


ARCHITECTURE struct OF HTL8255_TriState_tb IS

   -- Internal signal declarations
   SIGNAL abus  : std_logic_vector(1 DOWNTO 0);
   SIGNAL clk   : std_logic;
   SIGNAL csn   : std_logic;
   SIGNAL dbus  : std_logic_vector(7 DOWNTO 0);
   SIGNAL pa    : std_logic_vector(7 DOWNTO 0);
   SIGNAL pb    : std_logic_vector(7 DOWNTO 0);
   SIGNAL pc    : std_logic_vector(7 DOWNTO 0);
   SIGNAL rdn   : std_logic;
   SIGNAL reset : std_logic;
   SIGNAL wrn   : std_logic;


   -- Component Declarations
   COMPONENT HTL8255_TriState
   PORT (
      abus  : IN     std_logic_vector (1 DOWNTO 0);
      clk   : IN     std_logic ;
      csn   : IN     std_logic ;
      rdn   : IN     std_logic ;
      reset : IN     std_logic ;
      wrn   : IN     std_logic ;
      dbus  : INOUT  std_logic_vector (7 DOWNTO 0);
      pa    : INOUT  std_logic_vector (7 DOWNTO 0);
      pb    : INOUT  std_logic_vector (7 DOWNTO 0);
      pc    : INOUT  std_logic_vector (7 DOWNTO 0)
   );
   END COMPONENT;
   COMPONENT htl8255_tristate_tester
   PORT (
      abus  : OUT    std_logic_vector (1 DOWNTO 0);
      clk   : OUT    std_logic ;
      csn   : OUT    std_logic ;
      rdn   : OUT    std_logic ;
      reset : OUT    std_logic ;
      wrn   : OUT    std_logic ;
      dbus  : INOUT  std_logic_vector (7 DOWNTO 0);
      pa    : INOUT  std_logic_vector (7 DOWNTO 0);
      pb    : INOUT  std_logic_vector (7 DOWNTO 0);
      pc    : INOUT  std_logic_vector (7 DOWNTO 0)
   );
   END COMPONENT;


BEGIN

   -- Instance port mappings.
   U_0 : HTL8255_TriState
      PORT MAP (
         abus  => abus,
         clk   => clk,
         csn   => csn,
         rdn   => rdn,
         reset => reset,
         wrn   => wrn,
         dbus  => dbus,
         pa    => pa,
         pb    => pb,
         pc    => pc
      );
   U_1 : htl8255_tristate_tester
      PORT MAP (
         abus  => abus,
         clk   => clk,
         csn   => csn,
         rdn   => rdn,
         reset => reset,
         wrn   => wrn,
         dbus  => dbus,
         pa    => pa,
         pb    => pb,
         pc    => pc
      );

END struct;
