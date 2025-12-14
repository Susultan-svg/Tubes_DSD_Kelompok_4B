library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_elevator_fsm_scan is
end entity;

architecture sim of tb_elevator_fsm_scan is

  -- DUT ports
    signal clk        : std_logic := '0';
    signal rst        : std_logic := '0';

    signal req_L1     : std_logic := '0';
    signal req_L2     : std_logic := '0';
    signal req_L3     : std_logic := '0';

    signal door_btn   : std_logic := '0';

    signal S_F1       : std_logic := '0';
    signal S_F2       : std_logic := '0';
    signal S_F3       : std_logic := '0';

    signal TIMER_DONE : std_logic := '0';

    signal MP         : std_logic_vector(1 downto 0);

    constant CLK_PERIOD : time := 20 ns; -- 50 MHz (bebas, tidak kritis untuk FSM ini)

begin

  -- Instantiate DUT (pastikan entity kamu bernama elevator_fsm_scan di file Tubes.vhd)
    uut : entity work.elevator_fsm_scan
    port map (
        clk        => clk,
        rst        => rst,
        req_L1     => req_L1,
        req_L2     => req_L2,
        req_L3     => req_L3,
        door_btn   => door_btn,
        S_F1       => S_F1,
        S_F2       => S_F2,
        S_F3       => S_F3,
        TIMER_DONE => TIMER_DONE,
        MP         => MP
    );

  -- Clock generator
    clk <= not clk after CLK_PERIOD/2;

  -- Stimulus
    stim_proc : process
    begin
    ------------------------------------------------------------------
    -- Reset + posisi awal (Elevator di Lantai 1)
    ------------------------------------------------------------------
        rst <= '1';
        S_F1 <= '1'; S_F2 <= '0'; S_F3 <= '0';
        wait for 5*CLK_PERIOD;
        rst <= '0';
        wait for 5*CLK_PERIOD;

    ------------------------------------------------------------------
    -- Skenario 1: Request lantai 3 dari luar (req_L3 pulse)
    ------------------------------------------------------------------
        req_L3 <= '1';
        wait for 3*CLK_PERIOD;
        req_L3 <= '0';

    -- Elevator "bergerak": kita yang ubah sensor lantai
    -- (anggap butuh waktu sampai lantai 2)
        wait for 200*CLK_PERIOD;
        S_F1 <= '0'; S_F2 <= '1'; S_F3 <= '0';

    -- lanjut sampai lantai 3
        wait for 200*CLK_PERIOD;
        S_F1 <= '0'; S_F2 <= '0'; S_F3 <= '1';

    -- Di lantai 3, FSM harus masuk SERVIS (MP = "01")
    -- Tahan pintu sebentar pakai door_btn (hold)
        wait for 50*CLK_PERIOD;
        door_btn <= '1';
        wait for 50*CLK_PERIOD;
        door_btn <= '0';

    -- Timer selesai -> keluar dari SERVIS ke DECIDE
        TIMER_DONE <= '1';
        wait for 5*CLK_PERIOD;
        TIMER_DONE <= '0';

    ------------------------------------------------------------------
    -- Skenario 2 (opsional): setelah itu request lantai 1
    ------------------------------------------------------------------
        wait for 50*CLK_PERIOD;
        req_L1 <= '1';
        wait for 3*CLK_PERIOD;
        req_L1 <= '0';

    -- Turun ke lantai 2
        wait for 200*CLK_PERIOD;
        S_F1 <= '0'; S_F2 <= '1'; S_F3 <= '0';

    -- Turun ke lantai 1
        wait for 200*CLK_PERIOD;
        S_F1 <= '1'; S_F2 <= '0'; S_F3 <= '0';

    -- Timer selesai di SERVIS
        wait for 50*CLK_PERIOD;
        TIMER_DONE <= '1';
        wait for 5*CLK_PERIOD;
        TIMER_DONE <= '0';

    ------------------------------------------------------------------
    -- Selesai
    ------------------------------------------------------------------
        wait for 100*CLK_PERIOD;
        report "Simulation finished" severity note;
        wait;
    end process;

end architecture;
