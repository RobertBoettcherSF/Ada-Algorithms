pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Long_Long_Integer_Text_IO; use Ada.Long_Long_Integer_Text_IO;
with Delta_Encoding;
--  Differential-test driver (tools/vv/difftest.py): reads one case per
--  line (count, then values) on stdin, prints one result line per case.
procedure VV_Ada_Driver is
   N, V : Long_Long_Integer;
begin
   while not End_Of_File loop
      Get (N);
      declare
         A : Delta_Encoding.Integer_Array (1 .. Positive (N));
         S : Integer := 0;
      begin
         for I in A'Range loop
            Get (V); A (I) := Integer (V);
         end loop;
         declare
            E : constant Delta_Encoding.Integer_Array := Delta_Encoding.Encode_Integer_Delta (A);
         begin
            for I in E'First + 1 .. E'Last loop
               S := S + E (I);
            end loop;
         end;
         Put_Line (S'Image);
      end;
   end loop;
end VV_Ada_Driver;
