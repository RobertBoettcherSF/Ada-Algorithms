pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Long_Long_Integer_Text_IO; use Ada.Long_Long_Integer_Text_IO;
with Adler32;
with Interfaces;
--  Differential-test driver (tools/vv/difftest.py): reads one case per
--  line (count, then values) on stdin, prints one result line per case.
procedure VV_Spark_Driver is
   N, V : Long_Long_Integer;
begin
   while not End_Of_File loop
      Get (N);
      declare
         D : Adler32.Byte_Array (1 .. Positive (N));
      begin
         for I in D'Range loop
            Get (V); D (I) := Interfaces.Unsigned_8 (V);
         end loop;
         Put_Line (Adler32.Compute (D)'Image);
      end;
   end loop;
end VV_Spark_Driver;
