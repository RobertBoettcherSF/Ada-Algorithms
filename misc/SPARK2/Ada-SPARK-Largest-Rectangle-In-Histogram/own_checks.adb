--  Own tests for Largest_Rectangle_In_Histogram (see tests/SOURCES.txt).
--  Max_Area must equal the own all-intervals reference.
pragma Ada_2022;
with Ada.Environment_Variables;
with Ada.Text_IO;
with Largest_Rectangle_In_Histogram; use Largest_Rectangle_In_Histogram;

procedure Own_Checks is
   Failures : Natural := 0;
   Cases    : Natural := 0;

   --  Park-Miller "minimal standard" generator (x := 16807 x mod (2**31 - 1)).
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
   Seed : Long_Long_Integer := AA_Seed (20_261_008);
   function Next (Lo, Hi : Integer) return Integer is
   begin
      Seed := (Seed * 16_807) mod 2_147_483_647;
      return Integer (Long_Long_Integer (Lo)
                      + Seed mod (Long_Long_Integer (Hi) - Long_Long_Integer (Lo) + 1));
   end Next;

   procedure Report (Ok : Boolean; Label : String) is
   begin
      Cases := Cases + 1;
      if not Ok then
         Failures := Failures + 1;
         if Failures <= 5 then
            Ada.Text_IO.Put_Line ("  FAIL own check: " & Label);
         end if;
      end if;
   end Report;

   H : Heights;
   function Ref (N : Natural) return Natural is
      Best : Natural := 0;
      Lo : Natural;
   begin
      for I in 1 .. N loop
         Lo := Natural'Last;
         for J in I .. N loop
            Lo := Natural'Min (Lo, H (J));
            Best := Natural'Max (Best, Lo * (J - I + 1));
         end loop;
      end loop;
      return Best;
   end Ref;
begin
   for Iter in 1 .. 6_000 loop
      declare
         N : constant Natural := Next (0, 32);
         Hi : constant Natural := (if Iter mod 2 = 0 then 4 else 32);
      begin
         H := [others => Next (0, 32)];
         for I in 1 .. N loop
            H (I) := Next (0, Hi);
         end loop;
         Report (Max_Area (H, N) = Ref (N), "random" & Iter'Image);
      end;
   end loop;
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (own all-intervals reference)");
end Own_Checks;
