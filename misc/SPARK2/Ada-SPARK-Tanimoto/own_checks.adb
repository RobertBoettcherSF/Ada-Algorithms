pragma Ada_2022;
--  Own tests for Tanimoto (see tests/SOURCES.txt).
--  Similarity: floor (100 * A.B / (|A|^2 + |B|^2 - A.B)); 100 when both are zero; exhaustive.
with Ada.Text_IO; use Ada.Text_IO;
with Tanimoto; use Tanimoto;

procedure Own_Checks is
   Failures : Natural := 0;
   Checked : Natural := 0;
   procedure Report (Ok : Boolean; Label : String) is
   begin
      Checked := Checked + 1;
      if not Ok then
         Failures := Failures + 1;
         if Failures <= 10 then Put_Line ("  FAIL own check: " & Label); end if;
      end if;
   end Report;
   A, V : Vector;
begin
   for CA in 0 .. 4**3 - 1 loop
      for CB in 0 .. 4**3 - 1 loop
         declare
            Dot, NA, NB : Natural := 0;
         begin
            for I in Index loop
               A (I) := (CA / 4**(I - 1)) mod 4; V (I) := (CB / 4**(I - 1)) mod 4;
               Dot := Dot + A (I) * V (I); NA := NA + A (I)**2; NB := NB + V (I)**2;
            end loop;
            Report (Similarity (A, V) = (if NA + NB = 0 then 100 else (100 * Dot) / (NA + NB - Dot))
                    and then Similarity (A, V) = Similarity (V, A)
                    and then Similarity (A, V) in 0 .. 100
                    and then (CA /= CB or else Similarity (A, V) = 100),
                    "A" & Integer'Image (CA) & " B" & Integer'Image (CB));
         end;
      end loop;
   end loop;
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;
