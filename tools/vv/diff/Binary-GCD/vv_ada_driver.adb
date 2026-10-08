pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Long_Long_Integer_Text_IO; use Ada.Long_Long_Integer_Text_IO;
with Binary_GCD;
--  Differential-test driver (tools/vv/difftest.py): reads one case per
--  line (count, then values) on stdin, prints one result line per case.
procedure VV_Ada_Driver is
   N, V : Long_Long_Integer;
begin
   while not End_Of_File loop
      Get (N);
      Get (V); Get (N);
      Put_Line (Binary_GCD.Gcd (Binary_GCD.U64 (V), Binary_GCD.U64 (N))'Image);
   end loop;
end VV_Ada_Driver;
