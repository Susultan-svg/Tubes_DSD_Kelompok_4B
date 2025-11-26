--------------------------------------------------------------------
-- TUGAS BESAR KELOMPOK 4B
-- Smart Elevator Control System Using FSM (SCAN Algorithm)
----- Anggota -----
-- Sayed Sultan Maghrifatullah (002)
-- Nasywa Putri Irfianti (020)
-- Muhammad Yusril Syah (026)
-- Trialy Yudis Puta (042)
-- Abraham Ketaren (052)
--------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity elevator_fsm_scan is
    port (
        clk    : in  std_logic;
        rst    : in  std_logic;

        -- Tombol request per lantai (gabungan dalam + luar)
        req_L1 : in  std_logic;
        req_L2 : in  std_logic;
        req_L3 : in  std_logic;

        -- Tombol pintu (hold door saat di SERVIS)
        door_btn   : in  std_logic;

        -- Sensor posisi lantai
        S_F1   : in  std_logic;
        S_F2   : in  std_logic;
        S_F3   : in  std_logic;

        -- Timer pintu terbuka selesai
        TIMER_DONE : in  std_logic;

        -- Tombol emergency (optional, belum dipakai)
        -- EMG_STOP   : in  std_logic;

        -- Output Moore: MP = (M,P)
        -- MP(1) = Motor (1: bergerak, 0: diam)
        -- MP(0) = Pintu (1: terbuka, 0: tertutup)
        MP      : out std_logic_vector(1 downto 0)

        -- (Optional) untuk debug: state saat ini
        -- state_debug : out std_logic_vector(2 downto 0)
    );
end entity;


architecture rtl of elevator_fsm_scan is

    ----------------------------------------------------------------
    -- Tipe dan sinyal internal
    ----------------------------------------------------------------
    type state_type is (IDLE, DECIDE, NAIK_SATU, TURUN_SATU, SERVIS);
    signal state_reg, state_next : state_type;

    type dir_type is (DIR_UP, DIR_DOWN);
    signal dir_reg, dir_next : dir_type;      -- "terakhir naik / turun"

    -- Latch request per lantai (SCAN butuh request disimpan)
    signal r1, r2, r3 : std_logic;

    -- Posisi lantai
    signal at_f1, at_f2, at_f3 : std_logic;

    -- Informasi request relatif terhadap posisi sekarang
    signal req_here  : std_logic;
    signal above_req : std_logic;
    signal below_req : std_logic;
    signal any_req   : std_logic;

begin

    ----------------------------------------------------------------
    -- Dekode posisi lantai dari sensor
    ----------------------------------------------------------------
    at_f1 <= S_F1;
    at_f2 <= S_F2;
    at_f3 <= S_F3;

    ----------------------------------------------------------------
    -- Latch request (set saat tombol ditekan, clear saat sudah servis)
    ----------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                r1 <= '0';
                r2 <= '0';
                r3 <= '0';
            else
                -- Set request jika ada tombol
                if req_L1 = '1' then r1 <= '1'; end if;
                if req_L2 = '1' then r2 <= '1'; end if;
                if req_L3 = '1' then r3 <= '1'; end if;

                -- Clear request saat pintu terbuka di lantai tersebut (SERVIS)
                if state_reg = SERVIS then
                    if at_f1 = '1' then r1 <= '0'; end if;
                    if at_f2 = '1' then r2 <= '0'; end if;
                    if at_f3 = '1' then r3 <= '0'; end if;
                end if;
            end if;
        end if;
    end process;

    ----------------------------------------------------------------
    -- Hitung informasi bantuan: req_here, above_req, below_req
    ----------------------------------------------------------------
    req_here <= (r1 and at_f1) or
    (r2 and at_f2) or
    (r3 and at_f3);

    above_req <= ((r2 or r3) and at_f1) or   -- di L1, ada req L2/L3
    ( r3        and at_f2);     -- di L2, ada req L3

    below_req <= ( r1        and at_f2) or   -- di L2, ada req L1
    ((r1 or r2) and at_f3);     -- di L3, ada req L1/L2

    any_req <= r1 or r2 or r3;

    ----------------------------------------------------------------
    -- Register state & arah terakhir
    ----------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                state_reg <= IDLE;
                dir_reg   <= DIR_UP;  -- default arah awal
            else
                state_reg <= state_next;
                dir_reg   <= dir_next;
            end if;
        end if;
    end process;

    ----------------------------------------------------------------
    -- Next-state logic + update arah terakhir (SCAN)
    ----------------------------------------------------------------
    process(state_reg, dir_reg,
        req_here, above_req, below_req, any_req,
        door_btn, TIMER_DONE)
    begin
        -- default
        state_next <= state_reg;
        dir_next   <= dir_reg;

        case state_reg is

            --------------------------------------------------------
            -- IDLE (00): motor diam, pintu tutup
            -- Penumpang tekan request:
            --  - jika di lantai yang sama (req_here=1) -> SERVIS
            --  - kalau beda lantai -> NAIK_SATU / TURUN_SATU
            --------------------------------------------------------
            when IDLE =>
                if req_here = '1' then
                    state_next <= SERVIS;   -- cabin dan request di lantai yang sama
                elsif any_req = '1' then
                    -- inisial arah berdasarkan posisi terhadap request
                    if above_req = '1' then
                        dir_next   <= DIR_UP;
                        state_next <= NAIK_SATU;
                    elsif below_req = '1' then
                        dir_next   <= DIR_DOWN;
                        state_next <= TURUN_SATU;
                    end if;
                else
                    state_next <= IDLE;
                end if;

            --------------------------------------------------------
            -- DECIDE (00): menentukan arah sesuai SCAN
            --------------------------------------------------------
            when DECIDE =>
                if any_req = '0' then
                    state_next <= IDLE;
                else
                    -- logika SCAN: lanjutkan arah yang sama bila masih ada req
                    if dir_reg = DIR_UP then
                        if above_req = '1' then
                            state_next <= NAIK_SATU;
                        elsif req_here = '1' then
                            state_next <= SERVIS;
                        elsif below_req = '1' then
                            dir_next   <= DIR_DOWN;
                            state_next <= TURUN_SATU;
                        else
                            state_next <= IDLE;
                        end if;
                    else  -- DIR_DOWN
                        if below_req = '1' then
                            state_next <= TURUN_SATU;
                        elsif req_here = '1' then
                            state_next <= SERVIS;
                        elsif above_req = '1' then
                            dir_next   <= DIR_UP;
                            state_next <= NAIK_SATU;
                        else
                            state_next <= IDLE;
                        end if;
                    end if;
                end if;

            --------------------------------------------------------
            -- NAIK_SATU (10): motor jalan naik satu lantai
            --------------------------------------------------------
            when NAIK_SATU =>
                dir_next <= DIR_UP;
                if req_here = '1' then
                    state_next <= SERVIS;
                elsif any_req = '0' then
                    state_next <= IDLE;
                else
                    state_next <= NAIK_SATU;
                end if;

            --------------------------------------------------------
            -- TURUN_SATU (10): motor jalan turun satu lantai
            --------------------------------------------------------
            when TURUN_SATU =>
                dir_next <= DIR_DOWN;
                if req_here = '1' then
                    state_next <= SERVIS;
                elsif any_req = '0' then
                    state_next <= IDLE;
                else
                    state_next <= TURUN_SATU;
                end if;

            --------------------------------------------------------
            -- SERVIS (01): motor diam, pintu terbuka
            -- door_btn = 1 -> HOLD (tetap SERVIS meskipun TIMER_DONE=1)
            -- TIMER_DONE = 1 & door_btn = 0 -> pintu boleh tutup -> DECIDE
            --------------------------------------------------------
            when SERVIS =>
                if door_btn = '1' then
                    -- hold door, abaikan TIMER_DONE
                    state_next <= SERVIS;
                elsif TIMER_DONE = '1' then
                    -- waktu habis & tidak di-hold -> lanjut putuskan arah
                    state_next <= DECIDE;
                else
                    state_next <= SERVIS;
                end if;

        end case;
    end process;

    ----------------------------------------------------------------
    -- Output Moore: MP = (M,P) sesuai state
    ----------------------------------------------------------------
    with state_reg select
    MP <= "00" when IDLE,        -- motor diam, pintu tutup
              "00" when DECIDE,      -- diam, tutup (lagi milih arah)
              "10" when NAIK_SATU,   -- motor jalan, pintu tutup
              "10" when TURUN_SATU,  -- motor jalan, pintu tutup
              "01" when SERVIS,      -- motor diam, pintu buka
              "00" when others;

    -- Optional debug (bisa diaktifkan kalau mau)
    -- with state_reg select
    --     state_debug <= "000" when IDLE,
    --                    "001" when DECIDE,
    --                    "010" when NAIK_SATU,
    --                    "011" when TURUN_SATU,
    --                    "100" when SERVIS,
    --                    "111" when others;

end architecture;
