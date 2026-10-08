pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Long_Long_Integer_Text_IO; use Ada.Long_Long_Integer_Text_IO;
with Adler32;
--  Differential-test driver (tools/vv/difftest.py): reads one case per
--  line (count, then values) on stdin, prints one result line per case.
procedure VV_Ada_Driver is
   N, V : Long_Long_Integer;
begin
   while not End_Of_File loop
      Get (N);
      declare
         D : Adler32.Byte_Array (1 .. Positive (N));
      begin
         for I in D'Range loop
            Get (V); D (I) := Adler32.Byte (V);
         end loop;
         Put_Line (Adler32.Calculate_Basic (D)'Image);
      end;
   end loop;
end VV_Ada_Driver;
