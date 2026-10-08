pragma Ada_2022;
--  Own tests for Partition_Around_Pivot (see tests/SOURCES.txt).
--  Partition: values <= Pivot first, then the larger ones, each group in input order (README: stable).
with Ada.Environment_Variables;
with Ada.Text_IO; use Ada.Text_IO;
with Partition_Around_Pivot; use Partition_Around_Pivot;

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
   A : Value_Array;
begin
   for Trial in 1 .. 50_000 loop
      for I in Index loop A (I) := Next (-10, 10); end loop;
      declare
         P : constant Value := Next (-10, 10);
         R : constant Value_Array := Partition (A, P);
         E : Value_Array;
         K : Natural := 0;
      begin
         for I in Index loop if A (I) <= P then K := K + 1; E (K) := A (I); end if; end loop;
         for I in Index loop if A (I) > P then K := K + 1; E (K) := A (I); end if; end loop;
         Report (R = E, "trial" & Integer'Image (Trial));
      end;
   end loop;
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;
