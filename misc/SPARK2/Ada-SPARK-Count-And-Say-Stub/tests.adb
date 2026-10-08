pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Command_Line;
with Count_And_Say_Stub; use Count_And_Say_Stub;
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

   function Term (N : Positive) return String is
      T    : Text_Buffer;
      Last : Natural;
      Ok   : Boolean;
   begin
      Describe (N, T, Last, Ok);
      if not Ok then
         return "";
      end if;
      return S : String (1 .. Last) do
         for K in 1 .. Last loop
            S (K) := T (K);
         end loop;
      end return;
   end Term;

   --  OEIS A005341: lengths of the count-and-say terms 1 .. 20
   Lengths : constant array (1 .. 20) of Positive :=
     [1, 2, 2, 4, 6, 6, 8, 10, 14, 20, 26, 34, 46, 62, 78, 102, 134, 176,
      226, 302];
   Len_Ok : Boolean := True;
begin
   --  old stub cases
   Check (Term (1) = "1", "term 1");
   Check (Term (4) = "1211", "term 4");
   Check (Term (5) = "111221", "term 5");
   --  OEIS A005150
   Check (Term (6) = "312211", "term 6");
   Check (Term (8) = "1113213211", "term 8");
   Check (Term (10) = "13211311123113112211", "term 10");
   for N in Lengths'Range loop
      if Term (N)'Length /= Lengths (N) then
         Len_Ok := False;
      end if;
   end loop;
   Check (Len_Ok, "lengths of terms 1 .. 20 (OEIS A005341)");
   Check (Term (31)'Length = 5_808, "term 31 has 5808 characters");
   Check (Term (33)'Length = 9_898, "term 33 (9898 characters) fits");
   Check (Term (34) = "", "term 34 (12884 characters) reports not Ok");
   if Failures = 0 then
      Put_Line ("PASS Count_And_Say_Stub");
   else
      Put_Line ("FAIL" & Failures'Image & " checks");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Tests;
