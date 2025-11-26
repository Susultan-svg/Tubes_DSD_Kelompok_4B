library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_elevator_fsm_scan is
end entity;

architecture sim of tb_elevator_fsm_scan is

    -- sinyal ke/dari DUT
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

    constant CLK_PERIOD : time := 10 ns;

begin

    ----------------------------------------------------------------
    -- Instansiasi DUT
    ----------------------------------------------------------------
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

    ----------------------------------------------------------------
    -- Clock 100 MHz (periode 10 ns)
    ----------------------------------------------------------------
    clk_process : process
    begin
        clk <= '0';
        wait for CLK_PERIOD / 2;
        clk <= '1';
        wait for CLK_PERIOD / 2;
    end process;

    ----------------------------------------------------------------
    -- Stimulus
    ----------------------------------------------------------------
    stim_proc : process
    begin
        ----------------------------------------------------------------
        -- Inisialisasi awal
        ----------------------------------------------------------------
        rst        <= '1';
        req_L1     <= '0';
        req_L2     <= '0';
        req_L3     <= '0';
        door_btn   <= '0';
        TIMER_DONE <= '0';

        -- elevator mulai di lantai 1
        S_F1 <= '1';
        S_F2 <= '0';
        S_F3 <= '0';

        wait for 5*CLK_PERIOD;
        rst <= '0';
        wait for 5*CLK_PERIOD;

        ----------------------------------------------------------------
        -- Skenario 1:
        -- Elevator idle di lantai 1, ada request lantai 1 (req_here=1).
        -- Harus langsung masuk SERVIS (pintu buka), lalu timer habis.
        ----------------------------------------------------------------
        -- Tekan request lantai 1
        req_L1 <= '1';
        wait for CLK_PERIOD;
        req_L1 <= '0';

        -- tunggu beberapa saat di SERVIS (pintu buka)
        wait for 20*CLK_PERIOD;

        -- Timer pintu habis
        TIMER_DONE <= '1';
        wait for 3*CLK_PERIOD;
        TIMER_DONE <= '0';

        -- beri waktu FSM untuk kembali ke IDLE
        wait for 20*CLK_PERIOD;

        ----------------------------------------------------------------
        -- Skenario 2:
        -- Elevator di lantai 1, user request lantai 3.
        -- Elevator harus naik, lewat lantai 2, lalu sampai lantai 3
        -- dan masuk SERVIS.
        ----------------------------------------------------------------
        -- pastikan sensor posisi kembali di lantai 1
        S_F1 <= '1';
        S_F2 <= '0';
        S_F3 <= '0';
        wait for 10*CLK_PERIOD;

        -- Tekan request lantai 3
        req_L3 <= '1';
        wait for CLK_PERIOD;
        req_L3 <= '0';

        -- Beri waktu FSM keluar dari IDLE dan mulai "naik"
        wait for 40*CLK_PERIOD;

        -- Simulasikan lift sudah sampai lantai 2
        S_F1 <= '0';
        S_F2 <= '1';
        S_F3 <= '0';
        wait for 40*CLK_PERIOD;

        -- Simulasikan lift lanjut sampai lantai 3
        S_F2 <= '0';
        S_F3 <= '1';
        wait for 20*CLK_PERIOD;
        -- Pada saat ini, karena r3=1 dan S_F3=1, req_here=1
        -- → FSM seharusnya masuk SERVIS (pintu buka)

        ----------------------------------------------------------------
        -- Skenario 3:
        -- Di lantai 3, pintu terbuka (SERVIS).
        -- TIMER_DONE naik, tapi door_btn=1 → pintu di-hold.
        -- Setelah door_btn dilepas, baru FSM boleh keluar dari SERVIS.
        ----------------------------------------------------------------
        -- Hold door (misalnya penumpang tekan tombol door hold)
        door_btn <= '1';
        wait for 30*CLK_PERIOD;

        -- Meskipun TIMER_DONE = '1', FSM tetap SERVIS karena door_btn=1
        TIMER_DONE <= '1';
        wait for 20*CLK_PERIOD;

        -- Lepas tombol hold
        door_btn <= '0';
        -- Sekarang TIMER_DONE masih '1', jadi FSM boleh pindah ke DECIDE
        wait for 5*CLK_PERIOD;
        TIMER_DONE <= '0';

        -- Tunggu lagi sedikit
        wait for 50*CLK_PERIOD;

        ----------------------------------------------------------------
        -- Akhiri simulasi
        ----------------------------------------------------------------
        wait; 


    end process;

end architecture sim;
