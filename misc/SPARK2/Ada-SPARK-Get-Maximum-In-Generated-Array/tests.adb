pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Get_Maximum_In_Generated_Array; use Get_Maximum_In_Generated_Array;

--  Expected values worked out by hand (see tests/SOURCES.txt).
with Own_Checks;
procedure Tests is
   Failures : Natural := 0;

   procedure Check (Ok : Boolean; Label : String) is
   begin
      if not Ok then
         Failures := Failures + 1;
         Put_Line ("FAIL " & Label);
      end if;
   end Check;

   --  nums (0 .. 16) from the rules nums (0) = 0, nums (1) = 1,
   --  nums (2 i) = nums (i), nums (2 i + 1) = nums (i) + nums (i + 1):
   Nums : constant Value_Array (0 .. 16) := [0, 1, 1, 2, 1, 3, 2, 3, 1, 4, 3, 5, 2, 5, 3, 4, 1];
   --  Their running maximum (the old table gave 2 for N = 5, but
   --  nums (5) = nums (2) + nums (3) = 1 + 2 = 3):
   Max_Of : constant Value_Array (0 .. 16) := [0, 1, 1, 2, 2, 3, 3, 3, 3, 4, 4, 5, 5, 5, 5, 5, 5];
begin
   Check (Generate (0) = [0 => 0], "Generate 0");
   Check (Generate (1) = [0, 1], "Generate 1");
   Check (Generate (16) = Nums, "Generate 16");
   declare
      G : constant Value_Array := Generate (7);
   begin
      Check (G'First = 0 and then G'Last = 7 and then G = Nums (0 .. 7), "Generate 7");
   end;
   for N in Max_Of'Range loop
      Check (Maximum (N) = Max_Of (N), "Maximum" & N'Image);
   end loop;
   --  nums (683) = 89 (the chain in tests/SOURCES.txt), and 89 = F (11)
   --  is the largest value up to 1024 (Lucas), so N = 683 and the
   --  limit N = 1000 both give 89.
   Check (Generate (Max_N) (683) = 89, "nums 683");
   Check (Maximum (Max_N) = 89, "Maximum 1000");
   Check (Maximum (683) = 89, "Maximum 683");
   --  Powers of two: the largest value up to 2 ** K is F (K + 1).
   Check (Maximum (512) = 55 and then Maximum (256) = 34 and then Maximum (32) = 8, "powers of two");
   if Failures = 0 then
      Put_Line ("PASS Get_Maximum_In_Generated_Array");
   else
      Put_Line ("FAIL Get_Maximum_In_Generated_Array:" & Failures'Image);
      raise Program_Error;
   end if;
   Own_Checks;
end Tests;
