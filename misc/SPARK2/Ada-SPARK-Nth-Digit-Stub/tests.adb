pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Command_Line;
with Nth_Digit_Stub; use Nth_Digit_Stub;
procedure Tests is
   Failures : Natural := 0;

   procedure Check (Ok : Boolean; Name : String) is
   begin
      if Ok then
         Put_Line ("PASS " & Name);
      else
         Put_Line ("FAIL " & Name);
         Failures := Failures + 1;
      end if;
   end Check;

   --  Reference: build "123456789101112..." directly and compare.
   Ref : String (1 .. 20_000);
   Len : Natural := 0;
   K   : Positive := 1;
   All_Ok : Boolean := True;
begin
   while Len < Ref'Last - 10 loop
      declare
         Img : constant String := K'Image;
         S   : constant String := Img (Img'First + 1 .. Img'Last);
      begin
         Ref (Len + 1 .. Len + S'Length) := S;
         Len := Len + S'Length;
         K := K + 1;
      end;
   end loop;
   for P in 0 .. Len - 1 loop
      if Nth_Digit (P) /= Character'Pos (Ref (P + 1)) - Character'Pos ('0') then
         All_Ok := False;
      end if;
   end loop;
   Check (All_Ok, "first" & Len'Image & " positions match the reference");
   Check (Nth_Digit (0) = 1, "position 0 (old stub)");
   Check (Nth_Digit (4) = 5, "position 4 (old stub)");
   Check (Nth_Digit (9) = 1, "position 9 is '1' of 10 (old stub said 0)");
   Check (Nth_Digit (10) = 0, "position 10 is '0' of 10");
   Check (Nth_Digit (2) = 3, "LeetCode n=3 -> 3");
   Check (Nth_Digit (10) = 0, "LeetCode n=11 -> 0");
   Check (Nth_Digit (188) = 9 and then Nth_Digit (189) = 1,
          "boundary 99|100");
   --  n = 1_000_000_000 (one-based) is digit 1 (OEIS A033307 index)
   Check (Nth_Digit (999_999_999) = 1, "n = 10**9 -> 1");
   Check (Nth_Digit (Natural'Last) = 5, "position Natural'Last (n = 2**31) -> 5");
   if Failures = 0 then
      Put_Line ("PASS Nth_Digit_Stub");
   else
      Put_Line ("FAIL" & Failures'Image & " checks");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Tests;
