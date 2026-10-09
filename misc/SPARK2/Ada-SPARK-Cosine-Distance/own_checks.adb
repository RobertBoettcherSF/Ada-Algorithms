pragma Ada_2022;
--  Own checks (V&V sweep, agent A3). Every pair of vectors over the
--  component range (4 ** 3 = 64 vectors, 4,096 pairs). Independent
--  definition of the result D for non-zero vectors: with c = cos^2 =
--  Dot^2 / (|A|^2 |B|^2), D = 1000 - floor (1000 c), checked through the
--  defining inequalities of floor in exact integers:
--    (1000 - D) * NA * NB <= 1000 * Dot^2 < (1001 - D) * NA * NB.
--  Also: 0 <= D <= 1000, symmetry, D = 0 for parallel vectors (B = k A),
--  D = 1000 exactly for orthogonal vectors, and 0 when a vector is zero.
with Ada.Text_IO;
with Cosine_Distance; use Cosine_Distance;

procedure Own_Checks is
   Failures : Natural := 0;
   Checked  : Natural := 0;

   procedure Report (Ok : Boolean; Label : String) is
   begin
      Checked := Checked + 1;
      if not Ok then
         Failures := Failures + 1;
         if Failures <= 10 then
            Ada.Text_IO.Put_Line ("  FAIL own check: " & Label);
         end if;
      end if;
   end Report;

   function Img (V : Vector) return String is
     (V (1)'Image & V (2)'Image & V (3)'Image);

   function Vec (Code : Natural) return Vector is
     [Code mod 4, Code / 4 mod 4, Code / 16 mod 4];

   A, B : Vector;
   D    : Integer;
   Dot, NA, NB : Long_Long_Integer;
   Parallel : Boolean;
begin
   for CA in 0 .. 63 loop
      for CB in 0 .. 63 loop
         A := Vec (CA);
         B := Vec (CB);
         D := Distance (A, B);
         Dot := 0; NA := 0; NB := 0;
         for I in Index loop
            Dot := Dot + Long_Long_Integer (A (I)) * Long_Long_Integer (B (I));
            NA := NA + Long_Long_Integer (A (I)) ** 2;
            NB := NB + Long_Long_Integer (B (I)) ** 2;
         end loop;
         declare
            First  : constant Vector := B;
            Second : constant Vector := A;
         begin
            Report (D = Distance (First, Second),
                    "symmetric" & Img (A) & " /" & Img (B));
         end;
         if NA = 0 or else NB = 0 then
            Report (D = 0, "zero vector gives 0:" & Img (A) & " /" & Img (B));
         else
            Report (D in 0 .. 1000, "range" & Img (A) & " /" & Img (B));
            Report (Long_Long_Integer (1000 - D) * NA * NB <= 1000 * Dot * Dot
                    and then 1000 * Dot * Dot
                             < Long_Long_Integer (1001 - D) * NA * NB,
                    "floor definition" & Img (A) & " /" & Img (B));
            --  Parallel: B (I) * A (J) = A (I) * B (J) for all I, J.
            Parallel := True;
            for I in Index loop
               for J in Index loop
                  if B (I) * A (J) /= A (I) * B (J) then
                     Parallel := False;
                  end if;
               end loop;
            end loop;
            if Parallel then
               Report (D = 0, "parallel gives 0:" & Img (A) & " /" & Img (B));
            end if;
            if Dot = 0 then
               Report (D = 1000, "orthogonal gives 1000:" & Img (A) & " /" & Img (B));
            end if;
         end if;
      end loop;
   end loop;
   Ada.Text_IO.Put_Line
     ("Own checks:" & Checked'Image & " checks," & Failures'Image
      & " failures");
   if Failures > 0 then
      raise Program_Error with "own checks failed";
   end if;
end Own_Checks;
