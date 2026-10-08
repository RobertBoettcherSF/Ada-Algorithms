pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Long_Long_Integer_Text_IO; use Ada.Long_Long_Integer_Text_IO;
with Euclidean_Algorithm;
--  Differential-test driver (tools/vv/difftest.py): reads one case per
--  line (count, then values) on stdin, prints one result line per case.
procedure VV_Spark_Driver is
   N, V : Long_Long_Integer;
begin
   while not End_Of_File loop
      Get (N);
      Get (V); Get (N);
      Put_Line (Euclidean_Algorithm.Gcd (Euclidean_Algorithm.Value (V), Euclidean_Algorithm.Value (N))'Image);
   end loop;
end VV_Spark_Driver;
