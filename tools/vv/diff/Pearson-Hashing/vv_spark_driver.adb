pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Long_Long_Integer_Text_IO; use Ada.Long_Long_Integer_Text_IO;
with Pearson_Hashing;
--  Differential-test driver (tools/vv/difftest.py): reads one case per
--  line (count, then values) on stdin, prints one result line per case.
procedure VV_Spark_Driver is
   N, V : Long_Long_Integer;
begin
   while not End_Of_File loop
      Get (N);
      declare
         S : Pearson_Hashing.Char_Array (1 .. Positive (N));
      begin
         for I in S'Range loop
            Get (V); S (I) := Character'Val (V);
         end loop;
         Put_Line (Pearson_Hashing.Hash (S)'Image);
      end;
   end loop;
end VV_Spark_Driver;
