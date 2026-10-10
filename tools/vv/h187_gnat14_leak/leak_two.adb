pragma Ada_2022;
--  H189: 100_000 assertions on P_Two.Part (5, 4) = 14 from a client unit, then VmRSS.
--  Build with assertions on:  gnatmake -gnat2022 -gnata leak_two.adb
with Ada.Text_IO;
with Ada.Numerics.Big_Numbers.Big_Integers; use Ada.Numerics.Big_Numbers.Big_Integers;
with P_Two;
procedure Leak_Two is
   function Rss return String is
      F : Ada.Text_IO.File_Type;
      S : String (1 .. 200);
      N : Natural;
   begin
      Ada.Text_IO.Open (F, Ada.Text_IO.In_File, "/proc/self/status");
      loop
         Ada.Text_IO.Get_Line (F, S, N);
         if N > 6 and then S (1 .. 6) = "VmRSS:" then
            Ada.Text_IO.Close (F);
            return S (1 .. N);
         end if;
      end loop;
   end Rss;
begin
   for I in 1 .. 100_000 loop
      pragma Assert (P_Two.Part (5, 4) = To_Big_Integer (14));
   end loop;
   Ada.Text_IO.Put_Line ("two " & Rss);
end Leak_Two;
