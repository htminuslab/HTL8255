-------------------------------------------------------------------------------
--  HTL8255 - PPI core                                                       --
--                                                                           --
--  https://github.com/htminuslab                                            --
--                                                                           --
-------------------------------------------------------------------------------
-- Project       : HTL8255                                                   --
-- Purpose       : PortA Interrupt Control FSM                               --
-- Library       : I8088                                                     --
--                                                                           --
-- Version       : 1.0  20/01/2002   Created HT-LAB                          --
--               : 1.1  21/11/2023   cleaned and uploaded to github          --
-------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY intra_fsm IS
   PORT( 
      acka         : IN     std_logic;
      changemode   : IN     std_logic;
      clk          : IN     std_logic;
      control_word : IN     std_logic_vector (6 DOWNTO 0);
      ibfa         : IN     std_logic;
      intea1       : IN     std_logic;
      intea2       : IN     std_logic;
      obfa         : IN     std_logic;
      rdfea_s      : IN     std_logic;
      reset        : IN     std_logic;
      stba         : IN     std_logic;
      wrfea_s      : IN     std_logic;
      intra        : OUT    std_logic
   );

END intra_fsm ;
 
ARCHITECTURE fsm OF intra_fsm IS

   TYPE STATE_TYPE IS (
      sreset,
      sm1rd,
      sm1w,
      sm11w,
      sm12w,
      sm11r,
      sm12r,
      sm0,
      sm2,
      sm21,
      sm22
   );
 
   -- Declare current and next state signals
   SIGNAL current_state : STATE_TYPE;
   SIGNAL next_state : STATE_TYPE;

   -- Declare any pre-registered internal signals
   SIGNAL intra_cld : std_logic ;

BEGIN

   -----------------------------------------------------------------
   clocked_proc : PROCESS ( 
      clk,
      reset
   )
   -----------------------------------------------------------------
   BEGIN
      IF (reset = '1') THEN
         current_state <= sreset;
         -- Default Reset Values
         intra_cld <= '0';
      ELSIF (clk'EVENT AND clk = '1') THEN
         IF (changemode = '1') THEN
            current_state <= sreset;
            -- Default Reset Values
            intra_cld <= '0';
         ELSE
            current_state <= next_state;
            -- Default Assignment To Internals
            intra_cld <= '0';

            -- Combined Actions
            CASE current_state IS
               WHEN sm12w => 
                  intra_cld<='1';
               WHEN sm12r => 
                  intra_cld<='1';
               WHEN sm22 => 
                  intra_cld<='1';
               WHEN OTHERS =>
                  NULL;
            END CASE;
         END IF;
      END IF;
   END PROCESS clocked_proc;
 
   -----------------------------------------------------------------
   nextstate_proc : PROCESS ( 
      acka,
      control_word,
      current_state,
      ibfa,
      intea1,
      intea2,
      obfa,
      rdfea_s,
      stba,
      wrfea_s
   )
   -----------------------------------------------------------------
   BEGIN

      -- Combined Actions
      CASE current_state IS
         WHEN sreset => 
            IF (control_word(6 downto 4)="010") THEN 
               next_state <= sm1w;
            ELSIF (control_word(6 downto 4)="011") THEN 
               next_state <= sm1rd;
            ELSIF (control_word(6 downto 5)="00") THEN 
               next_state <= sm0;
            ELSIF (control_word(6)='1') THEN 
               next_state <= sm2;
            ELSE
               next_state <= sreset;
            END IF;
         WHEN sm1rd => 
            IF (stba='0') THEN 
               next_state <= sm11r;
            ELSE
               next_state <= sm1rd;
            END IF;
         WHEN sm1w => 
            IF (acka='0') THEN 
               next_state <= sm11w;
            ELSE
               next_state <= sm1w;
            END IF;
         WHEN sm11w => 
            IF (obfa='1' AND intea1='1' 
                AND acka='1') THEN 
               next_state <= sm12w;
            ELSE
               next_state <= sm11w;
            END IF;
         WHEN sm12w => 
            IF (wrfea_s='1') THEN 
               next_state <= sm1w;
            ELSE
               next_state <= sm12w;
            END IF;
         WHEN sm11r => 
            IF (stba='1' AND ibfa='1' 
                AND intea2='1') THEN 
               next_state <= sm12r;
            ELSE
               next_state <= sm11r;
            END IF;
         WHEN sm12r => 
            IF (rdfea_s='1') THEN 
               next_state <= sm1rd;
            ELSE
               next_state <= sm12r;
            END IF;
         WHEN sm0 => 
            next_state <= sm0;
         WHEN sm2 => 
            IF (acka='0' OR 
                stba='0') THEN 
               next_state <= sm21;
            ELSE
               next_state <= sm2;
            END IF;
         WHEN sm21 => 
            IF ((obfa='1' AND acka='1' AND intea1='1') OR
                (stba='1' AND ibfa='1' AND intea2='1')) THEN 
               next_state <= sm22;
            ELSE
               next_state <= sm21;
            END IF;
         WHEN sm22 => 
            IF (wrfea_s='1' OR rdfea_s='1') THEN 
               next_state <= sm2;
            ELSE
               next_state <= sm22;
            END IF;
         WHEN OTHERS =>
            next_state <= sreset;
      END CASE;
   END PROCESS nextstate_proc;
 
   -- Concurrent Statements
   -- Clocked output assignments
   intra <= intra_cld;
END fsm;
