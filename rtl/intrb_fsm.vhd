-------------------------------------------------------------------------------
--  HTL8255 - PPI core                                                       --
--                                                                           --
--  https://github.com/htminuslab                                            --
--                                                                           --
-------------------------------------------------------------------------------
-- Project       : HTL8255                                                   --
-- Purpose       : PortB Interrupt Control FSM                               --
-- Library       : I8088                                                     --
--                                                                           --
-- Version       : 1.0  20/01/2002   Created HT-LAB                          --
--               : 1.1  21/11/2023   cleaned and uploaded to github          --
-------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY intrb_fsm IS
   PORT( 
      ackb         : IN     std_logic;
      changemode   : IN     std_logic;
      clk          : IN     std_logic;
      control_word : IN     std_logic_vector (6 DOWNTO 0);
      ibfb         : IN     std_logic;
      inteb        : IN     std_logic;
      obfb         : IN     std_logic;
      rdfeb_s      : IN     std_logic;
      reset        : IN     std_logic;
      stbb         : IN     std_logic;
      wrfeb_s      : IN     std_logic;
      intrb        : OUT    std_logic
   );
END intrb_fsm ;
 
ARCHITECTURE fsm OF intrb_fsm IS

   TYPE STATE_TYPE IS (
      sm0,
      sreset,
      sm1w,
      sm12w,
      sm11w,
      sm1rd,
      sm12r,
      sm11r
   );
 
   -- Declare current and next state signals
   SIGNAL current_state : STATE_TYPE;
   SIGNAL next_state : STATE_TYPE;

   -- Declare any pre-registered internal signals
   SIGNAL intrb_cld : std_logic ;

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
         intrb_cld <= '0';
      ELSIF (clk'EVENT AND clk = '1') THEN
         IF (changemode = '1') THEN
            current_state <= sreset;
            -- Default Reset Values
            intrb_cld <= '0';
         ELSE
            current_state <= next_state;
            -- Default Assignment To Internals
            intrb_cld <= '0';

            -- Combined Actions
            CASE current_state IS
               WHEN sm12w => 
                  intrb_cld<='1';
               WHEN sm12r => 
                  intrb_cld<='1';
               WHEN OTHERS =>
                  NULL;
            END CASE;
         END IF;
      END IF;
   END PROCESS clocked_proc;
 
   -----------------------------------------------------------------
   nextstate_proc : PROCESS ( 
      ackb,
      control_word,
      current_state,
      ibfb,
      inteb,
      obfb,
      rdfeb_s,
      stbb,
      wrfeb_s
   )
   -----------------------------------------------------------------
   BEGIN

      -- Combined Actions
      CASE current_state IS
         WHEN sm0 => 
            next_state <= sm0;
         WHEN sreset => 
            IF (control_word(2 downto 1)="11") THEN 
               next_state <= sm1rd;
            ELSIF (control_word(2 downto 1)="10") THEN 
               next_state <= sm1w;
            ELSIF (control_word(2)='0') THEN 
               next_state <= sm0;
            ELSE
               next_state <= sreset;
            END IF;
         WHEN sm1w => 
            IF (ackb='0') THEN 
               next_state <= sm11w;
            ELSE
               next_state <= sm1w;
            END IF;
         WHEN sm12w => 
            IF (wrfeb_s='1') THEN 
               next_state <= sm1w;
            ELSE
               next_state <= sm12w;
            END IF;
         WHEN sm11w => 
            IF (obfb='1' AND inteb='1' 
                AND ackb='1') THEN 
               next_state <= sm12w;
            ELSE
               next_state <= sm11w;
            END IF;
         WHEN sm1rd => 
            IF (stbb='0') THEN 
               next_state <= sm11r;
            ELSE
               next_state <= sm1rd;
            END IF;
         WHEN sm12r => 
            IF (rdfeb_s='1') THEN 
               next_state <= sm1rd;
            ELSE
               next_state <= sm12r;
            END IF;
         WHEN sm11r => 
            IF (stbb='1' AND ibfb='1' 
                AND inteb='1') THEN 
               next_state <= sm12r;
            ELSE
               next_state <= sm11r;
            END IF;
         WHEN OTHERS =>
            next_state <= sreset;
      END CASE;
   END PROCESS nextstate_proc;
 
   -- Concurrent Statements
   -- Clocked output assignments
   intrb <= intrb_cld;
END fsm;
