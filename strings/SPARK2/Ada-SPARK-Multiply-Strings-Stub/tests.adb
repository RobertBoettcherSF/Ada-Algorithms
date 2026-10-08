pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Command_Line;
with Multiply_Strings; use Multiply_Strings;
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

   function Img (N : Long_Long_Integer) return String is
      S : constant String := N'Image;
   begin
      return S (S'First + 1 .. S'Last);
   end Img;

   Seed : Long_Long_Integer := 7;
   All_Ok : Boolean := True;
   Nines : constant String (1 .. 30) := [others => '9'];
   Expect : constant String :=
     "999999999999999999999999999998000000000000000000000000000001";
   Offset_Left : constant String (100 .. 102) := "123";
begin
   --  old stub cases (Naturals) as strings
   Check (Multiply ("0", "9999") = "0", "0 * 9999");
   Check (Multiply ("12", "34") = "408", "12 * 34");
   Check (Multiply ("9999", "9999") = "99980001", "9999 * 9999");
   --  small products, checked by hand arithmetic
   Check (Multiply ("2", "3") = "6", "2 * 3");
   Check (Multiply ("123", "456") = "56088", "123 * 456");
   Check (Multiply ("000", "45") = "0", "leading zeros in input");
   Check (Multiply (Offset_Left, "1") = "123", "input with offset index");
   Check (Multiply (Nines, Nines) = Expect, "(10**30 - 1) ** 2");
   --  random pairs against Long_Long_Integer arithmetic
   for K in 1 .. 2_000 loop
      Seed := (Seed * 1_103_515_245 + 12_345) mod 2_147_483_648;
      declare
         A : constant Long_Long_Integer := Seed mod 1_000_000_000;
         B : constant Long_Long_Integer := (Seed / 7) mod 1_000_000_000;
      begin
         if Multiply (Img (A), Img (B)) /= Img (A * B) then
            All_Ok := False;
         end if;
      end;
   end loop;
   Check (All_Ok, "2000 random 9-digit pairs match Long_Long_Integer");
   if Failures = 0 then
      Put_Line ("PASS Multiply_Strings");
   else
      Put_Line ("FAIL" & Failures'Image & " checks");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Tests;
