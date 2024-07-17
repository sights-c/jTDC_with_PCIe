-------------------------------------------------------------------------
----                                                                 ----
---- Engineer: Ri-Guang Chen                                         ----
---- Company : Xi'an Institute of Optics and Precision Mechanics     ----
----                                                                 ----
---- Target Devices: Ailinx ax7203 Analog Front-End                  ----
---- Description   : Component for LVDS input adapter                ----
----                                                                 ----
-------------------------------------------------------------------------
----                                                                 ----
---- Copyright (C) 2024 Ri-Guang Chen                                ----
----                                                                 ----
---- This program is free software; you can redistribute it and/or   ----
---- modify it under the terms of the GNU General Public License as  ----
---- published by the Free Software Foundation; either version 3 of  ----
---- the License, or (at your option) any later version.             ----
----                                                                 ----
---- This program is distributed in the hope that it will be useful, ----
---- but WITHOUT ANY WARRANTY; without even the implied warranty of  ----
---- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the    ----
---- GNU General Public License for more details.                    ----
----                                                                 ----
---- You should have received a copy of the GNU General Public       ----
---- License along with this program; if not, see                    ----
---- <http://www.gnu.org/licenses>.                                  ----
----                                                                 ----
-------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library UNISIM;
use UNISIM.VComponents.all;


entity afe_lvds_in is
    Port ( data : out   STD_LOGIC_VECTOR (31 downto 0) := (others => '0');
           afe_in  : inout STD_LOGIC_VECTOR (63 downto 0));
end afe_lvds_in;

architecture Behavioral of afe_lvds_in is

   signal afe_buffer : std_logic_vector (63 downto 0);
	
begin

	buffers: for i in 0 to 31 generate
        IBUFDS_inst : IBUFDS
        generic map (
           DIFF_TERM    => FALSE,       -- Differential Termination 
           IBUF_LOW_PWR => TRUE,        -- Low power (TRUE) vs. performance (FALSE) setting for referenced I/O standards
           IOSTANDARD   => "LVDS_25")   -- LVDS can only be input with external termination when VCCO being 3.3V
        port map (
           O    => afe_buffer(i),   -- Buffer output
           I    => afe_in(2*i),     -- Diff_p buffer input (connect directly to top-level port)
           IB   => afe_in(2*i+1)    -- Diff_n buffer input (connect directly to top-level port)
        );
    end generate buffers;

	data (16)	<= not afe_buffer (1);
	data (0)	<= not afe_buffer (0);
	data (17)	<= not afe_buffer (3);
	data (1)	<= not afe_buffer (2);
	data (18)	<= not afe_buffer (5);
	data (2)	<= not afe_buffer (4);
	data (19)	<= not afe_buffer (7);
	data (3)	<= not afe_buffer (6);
	data (20)	<= not afe_buffer (9);
	data (4)	<= not afe_buffer (8);
	data (21)	<= not afe_buffer (11);
	data (5)	<= not afe_buffer (10);
	data (22)	<= not afe_buffer (13);
	data (6)	<= not afe_buffer (12);
	data (23)	<= not afe_buffer (15);
	data (7)	<= not afe_buffer (14);

	data (24)	<= not afe_buffer (17);
	data (8)	<= not afe_buffer (16);
	data (25)	<= not afe_buffer (19);
	data (9)	<= not afe_buffer (18);
	data (26)	<= not afe_buffer (21);
	data (10)	<= not afe_buffer (20);
	data (27)	<= not afe_buffer (23);
	data (11)	<= not afe_buffer (22);
	data (28)	<= not afe_buffer (25);
	data (12)	<= not afe_buffer (24);
	data (29)	<= not afe_buffer (27);
	data (13)	<= not afe_buffer (26);
	data (30)	<= not afe_buffer (29);
	data (14)	<= not afe_buffer (28);
	data (31)	<= not afe_buffer (31);
	data (15)	<= not afe_buffer (30);

end Behavioral;
