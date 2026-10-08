pragma Ada_2022;
--  Own tests for Top_K_Frequent_Words (see tests/SOURCES.txt).
--  Kth_Frequency (W, N, K): the K-th largest of the 32 word counts over W (1 .. N) (unused ids count 0).
with Ada.Environment_Variables;
with Ada.Text_IO; use Ada.Text_IO;
with Top_K_Frequent_Words; use Top_K_Frequent_Words;

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
   W : Word_Array;
   Cnt : array (Word_Id) of Natural;
begin
   for Run in 1 .. 20_000 loop
      declare
         N : constant Positive := Next (1, 32);
         R : constant Positive := Next (1, 32);   --  id range, so repeats are common
         K : constant Positive := Next (1, N);
         V, Above, At_Least : Natural;
      begin
         Cnt := [others => 0];
         for I in W'Range loop
            W (I) := Next (1, R);
            if I <= N then Cnt (W (I)) := Cnt (W (I)) + 1; end if;
         end loop;
         V := Kth_Frequency (W, N, K);
         Above := 0; At_Least := 0;
         for C of Cnt loop
            if C > V then Above := Above + 1; end if;
            if C >= V then At_Least := At_Least + 1; end if;
         end loop;
         Report (Above < K and then K <= At_Least, "run" & Integer'Image (Run));
      end;
   end loop;
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;
