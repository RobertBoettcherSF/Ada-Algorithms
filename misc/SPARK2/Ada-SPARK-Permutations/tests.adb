with Ada.Text_IO;
with Permutations; use Permutations;
with Own_Checks;

procedure Tests is
   function Img (A : Index_Array) return String is
     (if A'Length = 0 then "" else A (A'First)'Image & Img (A (A'First + 1 .. A'Last)));

   procedure Expect (Got, Want : Index_Array; Label : String) is
   begin
      if Got /= Want then
         raise Program_Error with Label & ": got" & Img (Got) & ", expected" & Img (Want);
      end if;
   end Expect;

   procedure Step (P : in out Perm; Want : Index_Array; Want_Found : Boolean) is
      Found : Boolean;
   begin
      Next_Permutation (P, Found);
      Expect (P.Order, Want, "Next_Permutation");
      if Found /= Want_Found then
         raise Program_Error with "Found after" & Img (Want);
      end if;
   end Step;

   type Three is array (1 .. 6) of Index_Array (1 .. 3);
   All_3 : constant Three := [[1, 2, 3], [1, 3, 2], [2, 1, 3], [2, 3, 1], [3, 1, 2], [3, 2, 1]];
   P3 : Perm := Identity (3);
   P5 : Perm := (N => 5, Order => [1, 3, 5, 4, 2], Place => [1, 5, 2, 4, 3]);
   L5 : Perm := (N => 5, Order => [5, 4, 3, 2, 1], Place => [5, 4, 3, 2, 1]);
   P0 : Perm := Identity (0);
   P1 : Perm := Identity (1);
   Old : constant array (0 .. 12) of Positive :=
     [1, 1, 2, 6, 24, 120, 720, 5_040, 40_320, 362_880, 3_628_800, 39_916_800, 479_001_600];
begin
   --  The old table: N! for N <= 12.
   for N in Old'Range loop
      if Count (N) /= Old (N) then
         raise Program_Error with "Count" & N'Image;
      end if;
   end loop;

   --  All six permutations of 1 2 3 in order, then the wrap-around.
   Expect (P3.Order, All_3 (1), "Identity (3)");
   for K in 2 .. 6 loop
      Step (P3, All_3 (K), True);
   end loop;
   Step (P3, All_3 (1), False);

   --  By hand: 1 3 5 4 2: pivot 3 (position 2), the rightmost larger item
   --  is 4 (position 4); swap to 1 4 5 3 2, reverse the tail: 1 4 2 3 5.
   Step (P5, [1, 4, 2, 3, 5], True);
   Step (P5, [1, 4, 2, 5, 3], True);
   --  The last permutation of five wraps to the first.
   Step (L5, [1, 2, 3, 4, 5], False);
   if L5.Place /= [1, 2, 3, 4, 5] then
      raise Program_Error with "Place after the wrap-around";
   end if;
   --  No items, one item: a single permutation each.
   Step (P0, [1 .. 0 => 1], False);
   Step (P1, [1 => 1], False);

   Own_Checks;
   Ada.Text_IO.Put_Line ("permutations tests passed");
end Tests;
