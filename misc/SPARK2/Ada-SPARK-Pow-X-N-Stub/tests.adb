pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Command_Line;
with Pow_X_N_Stub; use Pow_X_N_Stub;
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

   function Gives (X : Integer; N : Natural; Expect : Integer) return Boolean is
      R  : Integer;
      Ok : Boolean;
   begin
      Power (X, N, R, Ok);
      return Ok and then R = Expect;
   end Gives;

   function Overflows (X : Integer; N : Natural) return Boolean is
      R  : Integer;
      Ok : Boolean;
   begin
      Power (X, N, R, Ok);
      return not Ok and then R = 0;
   end Overflows;

   --  Reference: naive repeated multiplication in Long_Long_Integer.
   function Agrees (X : Integer; N : Natural) return Boolean is
      Acc : Long_Long_Integer := 1;
      Fits : Boolean := True;
   begin
      for K in 1 .. N loop
         Acc := Acc * Long_Long_Integer (X);
         if abs Acc > 2 ** 40 then
            Fits := False;
            exit;
         end if;
      end loop;
      Fits := Fits and then Acc in Long_Long_Integer (Integer'First)
                                .. Long_Long_Integer (Integer'Last);
      return (if Fits then Gives (X, N, Integer (Acc)) else Overflows (X, N));
   end Agrees;

   All_Ok : Boolean := True;
begin
   --  old stub cases
   Check (Gives (2, 0, 1), "2 ** 0");
   Check (Gives (2, 5, 32), "2 ** 5");
   Check (Gives (4, 5, 1024), "4 ** 5");
   --  general
   Check (Gives (0, 0, 1), "0 ** 0 = 1");
   Check (Gives (0, 7, 0), "0 ** 7");
   Check (Gives (-3, 3, -27), "(-3) ** 3");
   Check (Gives (-1, Natural'Last, -1), "(-1) ** Natural'Last");
   Check (Gives (1, Natural'Last, 1), "1 ** Natural'Last");
   Check (Gives (2, 30, 2 ** 30), "2 ** 30");
   Check (Overflows (2, 31), "2 ** 31 overflows");
   Check (Gives (-2, 31, Integer'First), "(-2) ** 31 = Integer'First");
   Check (Gives (46_340, 2, 46_340 * 46_340), "46340 ** 2");
   Check (Overflows (46_341, 2), "46341 ** 2 overflows");
   Check (Overflows (10, Natural'Last), "10 ** Natural'Last overflows");
   for X in -50 .. 50 loop
      for N in 0 .. 40 loop
         if not Agrees (X, N) then
            All_Ok := False;
         end if;
      end loop;
   end loop;
   Check (All_Ok, "X in -50 .. 50, N in 0 .. 40 match naive reference");
   if Failures = 0 then
      Put_Line ("PASS Pow_X_N_Stub");
   else
      Put_Line ("FAIL" & Failures'Image & " checks");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Tests;
