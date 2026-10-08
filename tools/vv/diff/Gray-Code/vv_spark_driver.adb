pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Long_Long_Integer_Text_IO; use Ada.Long_Long_Integer_Text_IO;
with Gray_Code;
--  Differential-test driver (tools/vv/difftest.py): reads one case per
--  line (count, then values) on stdin, prints one result line per case.
procedure VV_Spark_Driver is
   N, V : Long_Long_Integer;
begin
   while not End_Of_File loop
      Get (N);
      Get (V);
      Put_Line (Gray_Code.Encode (Gray_Code.Word (V))'Image & Gray_Code.Decode (Gray_Code.Word (V))'Image);
   end loop;
end VV_Spark_Driver;
