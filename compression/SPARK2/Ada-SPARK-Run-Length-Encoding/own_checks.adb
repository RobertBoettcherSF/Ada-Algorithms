pragma Ada_2022;
--  Own tests for Run_Length_Encoding (see tests/SOURCES.txt).
--  Number_Of_Runs against an own run-length encoder (emit (char, count) pairs, count the pairs).
with Ada.Text_IO; use Ada.Text_IO;
with Run_Length_Encoding; use Run_Length_Encoding;

procedure Own_Checks is
   Failures : Natural := 0;
   Checked : Natural := 0;
   Seed : Long_Long_Integer := 20261008;
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
begin
   for Run in 1 .. 20000 loop
      declare
         N : constant Natural := Next (0, Max_Length);
         S : Char_Array (1 .. N);
         Runs : Natural := 0;
         I : Positive := 1;
      begin
         for K in 1 .. N loop
            S (K) := Character'Val (Character'Pos ('a') + Next (0, (if Run mod 3 = 0 then 0 else (if Run mod 3 = 1 then 1 else 25))));
         end loop;
         while I <= N loop   --  own encoder: one (char, count) pair per maximal run
            declare
               J : Positive := I;
            begin
               while J < N and then S (J + 1) = S (I) loop J := J + 1; end loop;
               Runs := Runs + 1;
               I := J + 1;
            end;
         end loop;
         Report (Number_Of_Runs (S) = Runs, "runs, run" & Run'Image);
      end;
   end loop;
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;
