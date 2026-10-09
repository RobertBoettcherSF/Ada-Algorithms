pragma Ada_2022;
with Ada.Text_IO;
with Climbing_Stairs; use Climbing_Stairs;

procedure Tests is
   function Img (A : Step_List) return String is
     (if A'Length = 0 then "" else A (A'First)'Image & Img (A (A'First + 1 .. A'Last)));

   procedure Expect (N : Steps; K : Natural; Want : Step_List) is
      Got : constant Step_List := Climb (N, K);
   begin
      if Got'Length /= Want'Length or else (Got'Length > 0 and then (Got'First /= 1 or else Got /= Want)) then
         raise Program_Error with "Climb" & N'Image & K'Image & ": got" & Img (Got) & ", expected" & Img (Want);
      end if;
   end Expect;

   Old : constant array (0 .. 10) of Positive := [1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89];
   Last_45 : constant Step_List (1 .. 23) := [1 .. 22 => 2, 23 => 1];
begin
   for N in Old'Range loop
      if Count (N) /= Old (N) then
         raise Program_Error with "Count" & N'Image;
      end if;
   end loop;
   --  Count (20) = 10_946; the limit Count (45) = 1_836_311_903 fits
   --  Natural, Count (46) = 2_971_215_073 would not.
   if Count (20) /= 10_946 or else Count (45) /= 1_836_311_903 then
      raise Program_Error with "Count 20 / 45";
   end if;

   --  The five ways to climb 4 stairs in dictionary order.
   Expect (4, 0, [1, 1, 1, 1]);
   Expect (4, 1, [1, 1, 2]);
   Expect (4, 2, [1, 2, 1]);
   Expect (4, 3, [2, 1, 1]);
   Expect (4, 4, [2, 2]);
   Expect (0, 0, []);
   Expect (1, 0, [1]);
   Expect (45, 0, [1 .. 45 => 1]);
   Expect (45, 1_836_311_902, Last_45);   --  22 double steps, then one single

   Ada.Text_IO.Put_Line ("climbing stairs tests passed");
end Tests;
