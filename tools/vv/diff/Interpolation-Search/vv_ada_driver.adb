pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Integer_Text_IO; use Ada.Integer_Text_IO;
with Interpolation_Search;
--  Differential-test driver (tools/vv/difftest.py): reads one case per
--  line (count, then values) on stdin, prints one result line per case.
--  First value = key (search) or rank seed (selection); the rest is the array.
procedure VV_Ada_Driver is
   use Interpolation_Search;
   N, V, Key : Integer;
begin
   while not End_Of_File loop
      Get (N); Get (Key);
      declare
         A : Element_Array (1 .. N - 1);
      begin
         for I in A'Range loop
            Get (V); A (I) := V;
         end loop;
         for I in A'First + 1 .. A'Last loop   --  driver-side insertion sort
            for J in reverse A'First + 1 .. I loop
               exit when A (J - 1) <= A (J);
               declare T : constant Integer := A (J); begin A (J) := A (J - 1); A (J - 1) := T; end;
            end loop;
         end loop;
         declare R : constant Integer := Integer (Find (A, Key)); begin
            if R = 0 then Put ("absent");
            elsif A (R) = Key then Put ("found");
            else Put ("BAD" & R'Image); end if;
         end;
         New_Line;
      end;
   end loop;
end VV_Ada_Driver;
