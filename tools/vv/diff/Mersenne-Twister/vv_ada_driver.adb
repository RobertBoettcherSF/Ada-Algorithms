pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Long_Long_Integer_Text_IO; use Ada.Long_Long_Integer_Text_IO;
with Interfaces; use Interfaces;
with Mersenne_Twister; use Mersenne_Twister;
--  Differential-test driver (tools/vv/difftest.py): reads one case per
--  line (count, then values) on stdin, prints one result line per case.
--  Case = seed; prints outputs 1, 2, 624, 625 and 1300 (crosses two twists).
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
         G : MT19937_State;
         R : Unsigned_32;
      begin
         Init (G, Unsigned_32 (V (1)));
         for K in 1 .. 1300 loop
            R := Random (G);
            if K in 1 | 2 | 624 | 625 | 1300 then Put (R'Image); end if;
         end loop;
      end;
      New_Line;
   end loop;
end VV_Ada_Driver;
