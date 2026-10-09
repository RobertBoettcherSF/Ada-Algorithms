pragma Ada_2022;
--  Own checks for Count_Sorted_Vowel_Strings (see tests/SOURCES.txt). No
--  expected value comes from the program. The inputs are fixed lists
--  (no random draws, so no seed):
--  * brute force for N <= 8: every one of the 5 ** N strings is written
--    out and tested for being sorted, counting separately for each
--    smallest allowed vowel;
--  * for N <= 120, every 11th N and 473 (all five vowels; the other
--    first vowels for N <= 40, every 37th N and 473): an own Pascal
--    triangle of binomial coefficients (additions only, in
--    Long_Long_Integer) gives C (N + k, k) with k = 4 - Vowel'Pos (From);
--  * the limit: C (477, 4) fits Natural and C (478, 4) does not.
with Ada.Text_IO;
with Count_Sorted_Vowel_Strings; use Count_Sorted_Vowel_Strings;

procedure Own_Checks with SPARK_Mode => Off is
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

   --  Pascal (R, C) = C (R, C) for R <= Max_Length + 4.
   type Row is array (0 .. 4) of Long_Long_Integer;
   Pascal : array (0 .. Max_Length + 4) of Row := [others => [others => 0]];
begin
   for R in Pascal'Range loop
      Pascal (R) (0) := 1;
      for C in 1 .. 4 loop
         if R > 0 then
            Pascal (R) (C) := Pascal (R - 1) (C - 1) + Pascal (R - 1) (C);
         end if;
      end loop;
   end loop;

   --  Brute force.
   for N in 0 .. 8 loop
      declare
         Counts : array (Vowel) of Natural := [others => 0];
         Letter : array (1 .. 8) of Natural := [others => 0];
         Total  : constant Natural := 5 ** N;
      begin
         for Code in 0 .. Total - 1 loop
            declare
               X      : Natural := Code;
               Sorted : Boolean := True;
            begin
               for P in 1 .. N loop
                  Letter (P) := X mod 5;
                  X := X / 5;
               end loop;
               for P in 2 .. N loop
                  Sorted := Sorted and then Letter (P - 1) <= Letter (P);
               end loop;
               if Sorted then
                  for F in Vowel loop
                     if N = 0 or else Letter (1) >= Vowel'Pos (F) then
                        Counts (F) := Counts (F) + 1;
                     end if;
                  end loop;
               end if;
            end;
         end loop;
         for F in Vowel loop
            Report (Number_Of_Strings (N, F) = Counts (F), "brute force" & N'Image & " " & F'Image);
         end loop;
      end;
   end loop;

   --  Pascal's triangle for N <= 120, every 11th N above and N = 473 over
   --  all five vowels; the other first vowels for N <= 40, every 37th N
   --  and N = 473. (Each call also runs the -gnata contract checks, which
   --  cost O (N) Big_Integer operations, so not every N is called.)
   for N in Length loop
      for F in Vowel loop
         if N = Max_Length
           or else (if F = A then N <= 120 or else N mod 11 = 0 else N <= 40 or else N mod 37 = 0)
         then
         declare
            K : constant Natural := 4 - Vowel'Pos (F);
         begin
            Report (Long_Long_Integer (Number_Of_Strings (N, F)) = Pascal (N + K) (K),
                    "Pascal" & N'Image & " " & F'Image);
         end;
         end if;
      end loop;
   end loop;
   --  The next length would overflow: C (478, 4) > Natural'Last.
   Report (Pascal (Max_Length + 4) (4) <= Long_Long_Integer (Natural'Last)
           and then Pascal (Max_Length + 3) (3) + Pascal (Max_Length + 4) (4) > Long_Long_Integer (Natural'Last),
           "limit 473");

   Ada.Text_IO.Put_Line ("own checks:" & Checked'Image & " checks," & Failures'Image & " failures");
   if Failures > 0 then
      raise Program_Error with "own checks failed";
   end if;
end Own_Checks;
