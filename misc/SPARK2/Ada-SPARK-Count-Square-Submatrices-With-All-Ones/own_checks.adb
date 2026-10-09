pragma Ada_2022;
--  Own checks (V&V sweep, agent A3). Every 4 x 4 bit matrix (2 ** 16 =
--  65,536) against a brute-force count from the definition: for every
--  size K in 1 .. 4 and every top-left corner (R, C) with the K x K square
--  inside the matrix, count the square when all K * K cells are 1.
--  Also: the count never exceeds 30 and equals the number of 1 cells when
--  no 2 x 2 square is all ones.
with Ada.Text_IO;
with Count_Square_Submatrices_With_All_Ones;
use Count_Square_Submatrices_With_All_Ones;

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

   N : constant := 4;
   M : Matrix;
   Want, Ones : Natural;
   Bigger : Boolean;
   All_One : Boolean;
   Got : Long_Long_Integer;
begin
   for Code in 0 .. 2 ** 16 - 1 loop
      for R in Index loop
         for C in Index loop
            M (R, C) := (Code / 2 ** ((R - 1) * N + C - 1)) mod 2;
         end loop;
      end loop;
      Want := 0;
      Ones := 0;
      Bigger := False;
      for K in 1 .. N loop
         for R in 1 .. N - K + 1 loop
            for C in 1 .. N - K + 1 loop
               All_One := True;
               for DR in 0 .. K - 1 loop
                  for DC in 0 .. K - 1 loop
                     if M (R + DR, C + DC) /= 1 then
                        All_One := False;
                     end if;
                  end loop;
               end loop;
               if All_One then
                  Want := Want + 1;
                  if K = 1 then
                     Ones := Ones + 1;
                  else
                     Bigger := True;
                  end if;
               end if;
            end loop;
         end loop;
      end loop;
      Got := Count_Squares (M);
      Report (Got = Long_Long_Integer (Want), "brute force, matrix" & Code'Image);
      Report (Got in 0 .. 30, "range, matrix" & Code'Image);
      if not Bigger then
         Report (Got = Long_Long_Integer (Ones), "only 1 x 1 squares, matrix" & Code'Image);
      end if;
   end loop;
   Ada.Text_IO.Put_Line
     ("Own checks:" & Checked'Image & " checks," & Failures'Image
      & " failures");
   if Failures > 0 then
      raise Program_Error with "own checks failed";
   end if;
end Own_Checks;
