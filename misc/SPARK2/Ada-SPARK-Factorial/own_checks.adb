pragma Ada_2022;
--  Own checks for Factorial.Compute (see tests/SOURCES.txt). No expected
--  value comes from the program:
--  * a multiplication-free reference: N! = N copies of (N - 1)! added up;
--  * Compute (N) / Compute (N - 1) = N exactly;
--  * trailing zeros of N! = N / 5 + N / 25 (Legendre's formula for 5);
--  * 21! would not fit: Long_Long_Integer'Last / 21 < 20!;
--  * the ghost Fact_Table regenerated entry by entry.
with Ada.Text_IO;
with Factorial; use Factorial;

procedure Own_Checks with SPARK_Mode => Off is
   Failures : Natural := 0;
   Checked  : Natural := 0;

   procedure Report (Ok : Boolean; Label : String) is
   begin
      Checked := Checked + 1;
      if not Ok then
         Failures := Failures + 1;
         Ada.Text_IO.Put_Line ("  FAIL own check: " & Label);
      end if;
   end Report;

   Ref : Long_Long_Integer := 1;   --  (N - 1)! before the step, N! after
begin
   for N in Input loop
      if N > 0 then
         declare
            Sum : Long_Long_Integer := 0;
         begin
            for Copy in 1 .. N loop
               Sum := Sum + Ref;
            end loop;
            Ref := Sum;
         end;
         Report (Compute (N) / Compute (N - 1) = Long_Long_Integer (N)
                 and then Compute (N) mod Compute (N - 1) = 0, "ratio N =" & N'Image);
      end if;
      Report (Compute (N) = Ref, "repeated addition N =" & N'Image);
      pragma Assert (Fact_Table (N) = Ref);
      declare
         Zeros : Natural := 0;
         V     : Long_Long_Integer := Compute (N);
      begin
         while V mod 10 = 0 loop
            Zeros := Zeros + 1;
            V := V / 10;
         end loop;
         Report (Zeros = N / 5 + N / 25, "trailing zeros N =" & N'Image);
      end;
   end loop;
   Report (Long_Long_Integer'Last / 21 < Compute (20), "21! does not fit");

   Ada.Text_IO.Put_Line ("own checks:" & Checked'Image & " checks," & Failures'Image & " failures");
   if Failures > 0 then
      raise Program_Error with "own checks failed";
   end if;
end Own_Checks;
