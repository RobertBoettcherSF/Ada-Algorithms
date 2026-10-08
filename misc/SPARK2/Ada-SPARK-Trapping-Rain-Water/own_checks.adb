--  Own tests for Trapping_Rain_Water (see tests/SOURCES.txt).
--  Trapped must equal the own per-column water reference.
pragma Ada_2022;
with Ada.Environment_Variables;
with Ada.Text_IO;
with Trapping_Rain_Water; use Trapping_Rain_Water;

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

   D : Heights;
   function Ref (N : Natural) return Natural is
      W : Natural := 0;
      L, R : Natural;
   begin
      for I in 1 .. N loop
         L := 0; R := 0;
         for J in 1 .. I loop L := Natural'Max (L, D (J)); end loop;
         for J in I .. N loop R := Natural'Max (R, D (J)); end loop;
         W := W + Natural'Min (L, R) - D (I);
      end loop;
      return W;
   end Ref;
begin
   for Iter in 1 .. 6_000 loop
      declare
         N : constant Natural := Next (0, 32);
         Hi : constant Natural := (case Iter mod 3 is when 0 => 3, when 1 => 20, when others => 1_000);
      begin
         D := [others => Next (0, 1_000)];
         for I in 1 .. N loop
            D (I) := Next (0, Hi);
         end loop;
         Report (Trapped (D, N) = Ref (N), "random" & Iter'Image);
      end;
   end loop;
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (own per-column water reference)");
end Own_Checks;
