pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Long_Long_Integer_Text_IO; use Ada.Long_Long_Integer_Text_IO;
with Run_Length_Encoding; use Run_Length_Encoding;
--  Differential-test driver (tools/vv/difftest.py): reads one case per
--  line (count, then values) on stdin, prints one result line per case.
--  Case = up to 32 bits; prints the number of runs (Ada: length of Encode_Binary).
procedure VV_Ada_Driver is

   N : Long_Long_Integer;
   V : array (1 .. 64) of Long_Long_Integer;
begin
   while not End_Of_File loop
      Get (N);
      for I in 1 .. Integer (N) loop
         Get (V (I));
      end loop;
      declare
         B : Binary_Array (1 .. Integer (N));
         S : Boolean;
      begin
         for I in B'Range loop B (I) := V (I) = 1; end loop;
         Put (Encode_Binary (B, S)'Length'Image);
      end;
      New_Line;
   end loop;
end VV_Ada_Driver;
