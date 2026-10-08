--  Own tests for Beautiful_Arrangement (see tests/SOURCES.txt).
--  Is_Beautiful (A, N): A (1 .. N) is a permutation of 1 .. N with A (I) divisible by I or I divisible
--  by A (I) at every position (the standard statement).
with Ada.Environment_Variables;
with Ada.Text_IO; use Ada.Text_IO;
with Beautiful_Arrangement; use Beautiful_Arrangement;

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
   function Brute (A : Arrangement; N : Size) return Boolean is
      Seen : array (1 .. 8) of Boolean := [others => False];
   begin
      for I in 1 .. N loop
         if A (I) not in 1 .. N or else Seen (A (I)) then return False; end if;
         Seen (A (I)) := True;
         if A (I) mod I /= 0 and then I mod A (I) /= 0 then return False; end if;
      end loop;
      return True;
   end Brute;
   A : Arrangement;
begin
   --  every arrangement of values 0 .. 8 at positions 1 .. 4 for N = 1 .. 4 (9**4 each)
   for Code in 0 .. 9**4 - 1 loop
      A := [others => 0];
      for I in 1 .. 4 loop
         A (I) := (Code / 9**(I - 1)) mod 9;
      end loop;
      for N in 1 .. 4 loop
         Report (Is_Beautiful (A, N) = Brute (A, N), "small N" & Integer'Image (N));
      end loop;
   end loop;
   --  random arrangements and random permutations for N = 5 .. 8
   for Trial in 1 .. 50_000 loop
      declare
         N : constant Size := Next (5, 8);
      begin
         for I in Size loop
            A (I) := I;
         end loop;
         for I in reverse 2 .. N loop   --  Fisher-Yates over 1 .. N
            declare
               J : constant Size := Next (1, I);
               T : constant Value := A (I);
            begin
               A (I) := A (J); A (J) := T;
            end;
         end loop;
         if Trial mod 2 = 0 then
            A (Next (1, N)) := Next (0, 8);
         end if;
         Report (Is_Beautiful (A, N) = Brute (A, N), "random N" & Integer'Image (N));
      end;
   end loop;
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;
