pragma Ada_2022;
with Ada.Text_IO;
with Subsets; use Subsets;

procedure Tests is
   function Img (S : Selection) return String is
     (if S'Length = 0 then "" else (if S (S'First) then "T" else "F") & Img (S (S'First + 1 .. S'Last)));

   procedure Step (S : in out Small_Selection; Want : Selection; Want_Found : Boolean) is
      Found : Boolean;
   begin
      Next_Subset (S, Found);
      if S /= Want or else Found /= Want_Found then
         raise Program_Error with "Next_Subset: got " & Img (S) & " " & Found'Image & ", expected " & Img (Want);
      end if;
   end Step;

   procedure Expect (Got, Want : Item_List; Label : String) is
   begin
      if Got'Length /= Want'Length or else (Got'Length > 0 and then (Got'First /= 1 or else Got /= Want)) then
         raise Program_Error with Label;
      end if;
   end Expect;

   Old : constant array (0 .. 12) of Positive :=
     [1, 2, 4, 8, 16, 32, 64, 128, 256, 512, 1_024, 2_048, 4_096];
   --  Item 1 is the lowest bit: the subsets of three items in counting order.
   type Three is array (1 .. 8) of Selection (1 .. 3);
   Order : constant Three :=
     [[False, False, False], [True, False, False], [False, True, False], [True, True, False],
      [False, False, True], [True, False, True], [False, True, True], [True, True, True]];
   S3 : Small_Selection := [False, False, False];
   S0 : Small_Selection (1 .. 0);
   S5 : Small_Selection := [True, True, False, True, False];
   Items : constant Item_List (5 .. 7) := [10, 20, 30];
   Found : Boolean;
begin
   for N in Old'Range loop
      if Count (N) /= Old (N) then
         raise Program_Error with "Count" & N'Image;
      end if;
   end loop;
   --  2 ** 30 = 1_073_741_824 is the largest power of two in Natural.
   if Count (30) /= 1_073_741_824 or else Count (13) /= 8_192 then
      raise Program_Error with "Count 13 / 30";
   end if;

   for K in 2 .. 8 loop
      Step (S3, Order (K), True);
   end loop;
   Step (S3, Order (1), False);   --  wraps to the empty subset

   --  T T F T F = 1 + 2 + 8 = 11; the next one is 12 = F F T T F.
   Step (S5, [False, False, True, True, False], True);

   Next_Subset (S0, Found);
   if Found then
      raise Program_Error with "empty selection has one subset";
   end if;

   Expect (Subset (Items, [5 => True, 6 => False, 7 => True]), [10, 30], "Subset T F T");
   Expect (Subset (Items, [5 => False, 6 => True, 7 => False]), [20], "Subset F T F");
   Expect (Subset (Items, [5 .. 7 => True]), [10, 20, 30], "Subset all");
   Expect (Subset (Items, [5 .. 7 => False]), [], "Subset none");

   Ada.Text_IO.Put_Line ("subsets tests passed");
end Tests;
