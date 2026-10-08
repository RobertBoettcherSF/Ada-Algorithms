pragma Ada_2022;
--  Own tests for Bucket_Sort (see tests/SOURCES.txt).
--  Sort must order the array and keep its values (own properties).
with Ada.Environment_Variables;
with Ada.Text_IO; use Ada.Text_IO;
with Bucket_Sort; use Bucket_Sort;

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
   function Same_Multiset (A, B : Element_Array) return Boolean is
      Used : array (B'Range) of Boolean := [others => False];
      Found : Boolean;
   begin
      if A'Length /= B'Length then return False; end if;
      for X of A loop
         Found := False;
         for J in B'Range loop
            if not Used (J) and then B (J) = X then Used (J) := True; Found := True; exit; end if;
         end loop;
         if not Found then return False; end if;
      end loop;
      return True;
   end Same_Multiset;
begin
   for Run in 1 .. 4000 loop
      declare
         First : constant Natural := Next (0, 5);
         A : Element_Array (First .. First + Next (0, 40) - 1);
         Hi : constant Integer := (case Run mod 3 is when 0 => 3, when 1 => 1000, when others => 1_000_000_000);
         B : Element_Array (A'Range);
         Ok : Boolean := True;
      begin
         for X of A loop X := Next (-Hi, Hi); end loop;
         B := A;
         Sort (B);
         for I in B'First + 1 .. B'Last loop Ok := Ok and then B (I - 1) <= B (I); end loop;
         Report (Ok and then Same_Multiset (A, B), "run" & Integer'Image (Run) & " length" & Integer'Image (A'Length));
      end;
   end loop;
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;
