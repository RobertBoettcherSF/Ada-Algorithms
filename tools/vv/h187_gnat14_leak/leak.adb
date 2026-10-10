pragma Ada_2022;
--  H187 reproducer: 100_000 assertions on Part (5, 4) = 14, then VmRSS.
--  Build with assertions on:  gnatmake -gnat2022 -gnata leak.adb
--  Run:  ./leak sep   (separate declaration)   ./leak one   (single expression function)
with Ada.Text_IO; with Ada.Command_Line;
with Ada.Numerics.Big_Numbers.Big_Integers; use Ada.Numerics.Big_Numbers.Big_Integers;
with P_Sep; with P_One;
procedure Leak is
   Mode : constant String := Ada.Command_Line.Argument (1);
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
      if Mode = "sep" then
         pragma Assert (P_Sep.Part (5, 4) = To_Big_Integer (14));
      else
         pragma Assert (P_One.Part (5, 4) = To_Big_Integer (14));
      end if;
   end loop;
   Ada.Text_IO.Put_Line (Mode & " " & Rss);
end Leak;
