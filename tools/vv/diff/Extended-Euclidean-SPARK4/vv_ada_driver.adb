pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Long_Long_Integer_Text_IO; use Ada.Long_Long_Integer_Text_IO;
with Extended_Euclidean; use Extended_Euclidean;
--  Differential-test driver (tools/vv/difftest.py): reads one case per
--  line (count, then values) on stdin, prints one result line per case.
--  Case = (A, B); prints Gcd, Bezout X, Y of Extended_Gcd.
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
         R : constant Extended_Gcd_Result := Extended_Gcd (Long_Integer (V (1)), Long_Integer (V (2)));
      begin
         Put (Gcd (Long_Integer (V (1)), Long_Integer (V (2)))'Image); Put (R.Gcd'Image); Put (R.X'Image); Put (R.Y'Image);
      end;
      New_Line;
   end loop;
end VV_Ada_Driver;
