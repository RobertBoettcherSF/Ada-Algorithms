--  Own tests for Arranging_Coins (see tests/SOURCES.txt).
--  Full_Rows (N) = the largest K with K (K + 1) / 2 <= N (complete staircase rows).
with Ada.Environment_Variables;
with Ada.Text_IO; use Ada.Text_IO;
with Arranging_Coins; use Arranging_Coins;

procedure Own_Checks is
   Failures : Natural := 0;
   Checked : Natural := 0;
   --  Random test inputs: fixed default seed, printed at start; AA_SEED=<n> overrides it.
   function AA_Seed (Default : Long_Long_Integer) return Long_Long_Integer is
      V : constant String := Ada.Environment_Variables.Value ("AA_SEED", "");
      S : Long_Long_Integer := Default;
   begin
      if V /= "" then
         S := Long_Long_Integer (1 + abs (Long_Long_Integer'Value (V)) mod 2_147_483_646);
      end if;
      Ada.Text_IO.Put_Line ("AA_SEED =" & Long_Long_Integer'Image (S) & (if V = "" then " (default)" else " (from AA_SEED)"));
      return S;
   end AA_Seed;
   Seed : Long_Long_Integer := AA_Seed (20261008);
   function Next (Lo, Hi : Integer) return Integer is
   begin
      Seed := (Seed * 16807) mod 2147483647;   --  Park-Miller minimal standard
      return Lo + Integer (Seed mod Long_Long_Integer (Hi - Lo + 1));
   end Next;
   procedure Report (Ok : Boolean; Label : String) is
   begin
      Checked := Checked + 1;
      if not Ok then
         Failures := Failures + 1;
         if Failures <= 10 then Put_Line ("  FAIL own check: " & Label); end if;
      end if;
   end Report;
   function Tri (K : Long_Long_Integer) return Long_Long_Integer is (K * (K + 1) / 2);
   procedure Check (N : Coins) is
      K : constant Long_Long_Integer := Long_Long_Integer (Full_Rows (N));
   begin
      Report (Tri (K) <= Long_Long_Integer (N) and then Long_Long_Integer (N) < Tri (K + 1),
              "coins" & Integer'Image (N));
   end Check;
begin
   for N in 0 .. 1_000_000 loop
      Check (N);
   end loop;
   for K in 1 .. 44_720 loop   --  every staircase boundary and its neighbours
      declare
         T : constant Long_Long_Integer := Tri (Long_Long_Integer (K));
      begin
         Check (Coins (T - 1)); Check (Coins (T));
         if T + 1 <= Long_Long_Integer (Coins'Last) then Check (Coins (T + 1)); end if;
      end;
   end loop;
   for Trial in 1 .. 100_000 loop
      Check (Next (0, Coins'Last));
   end loop;
   Check (Coins'Last);
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;
