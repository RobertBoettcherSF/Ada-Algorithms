pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Long_Long_Integer_Text_IO; use Ada.Long_Long_Integer_Text_IO;
with Extended_Euclidean; use Extended_Euclidean;
--  Differential-test driver (tools/vv/difftest.py): reads one case per
--  line (count, then values) on stdin, prints one result line per case.
--  Case = (A, B), both 1 .. 1000; prints the gcd.
procedure VV_SPARK_Driver is

   N : Long_Long_Integer;
   V : array (1 .. 64) of Long_Long_Integer;
begin
   while not End_Of_File loop
      Get (N);
      for I in 1 .. Integer (N) loop
         Get (V (I));
      end loop;
      declare

      begin
         Put (GCD (Input (V (1)), Input (V (2)))'Image);
      end;
      New_Line;
   end loop;
end VV_SPARK_Driver;
