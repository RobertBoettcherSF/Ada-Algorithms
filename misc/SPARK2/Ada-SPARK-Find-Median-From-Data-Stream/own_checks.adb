pragma Ada_2022;
--  Own tests for Find_Median_From_Data_Stream (see tests/SOURCES.txt).
--  Median of Input (1 .. Count): the middle value after sorting; for even Count the two
--  middle values averaged with Ada integer division (truncation toward zero, as the README states).
with Ada.Environment_Variables;
with Ada.Text_IO; use Ada.Text_IO;
with Find_Median_From_Data_Stream; use Find_Median_From_Data_Stream;

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
   function Ref (A : Input_Array; N : Count_Index) return Integer is
      W : Input_Array := A;
      Below : Natural;
   begin
      --  own order: place each value by counting smaller ones (stable on ties)
      for I in 1 .. N loop
         Below := 0;
         for J in 1 .. N loop
            if A (J) < A (I) or else (A (J) = A (I) and then J < I) then Below := Below + 1; end if;
         end loop;
         W (Below + 1) := A (I);
      end loop;
      if N mod 2 = 1 then return W ((N + 1) / 2); end if;
      return (W (N / 2) + W (N / 2 + 1)) / 2;
   end Ref;
begin
   for Run in 1 .. 20000 loop
      declare
         A : Input_Array;
         N : constant Count_Index := Next (1, 8);
         Hi : constant Natural := (if Run mod 2 = 0 then 3 else 100);
      begin
         for I in Index loop A (I) := Next (-Hi, Hi); end loop;
         Report (Median (A, N) = Ref (A, N), "run" & Integer'Image (Run));
      end;
   end loop;
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;
