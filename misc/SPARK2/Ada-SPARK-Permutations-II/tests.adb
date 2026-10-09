with Ada.Text_IO;
with Permutations_II; use Permutations_II;

procedure Tests is
   function Img (A : Value_Array) return String is
     (if A'Length = 0 then "" else A (A'First)'Image & Img (A (A'First + 1 .. A'Last)));

   procedure Step (A : in out Arrangement; Want : Value_Array; Want_Found : Boolean) is
      Found : Boolean;
   begin
      Next_Permutation (A, Found);
      if Values (A) /= Want or else Found /= Want_Found then
         raise Program_Error with "Next_Permutation: got" & Img (Values (A)) & ", expected" & Img (Want);
      end if;
   end Step;

   procedure Check_Count (Items : Small_List; Want : Positive) is
   begin
      if Count_Distinct (Items) /= Want then
         raise Program_Error with "Count_Distinct" & Img (Items) & " =" & Count_Distinct (Items)'Image;
      end if;
   end Check_Count;

   Twelve : constant Small_List := [1, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];
   Same   : constant Small_List (1 .. 12) := [others => 7];
   A : Arrangement := Start ([1, 1, 2]);
   B : Arrangement := Start ([1, 3, 2, 2]);
   L : Arrangement := Start ([3, 2, 2, 1]);
   E : Arrangement := Start ([1 .. 0 => 0]);
   M : Arrangement := Start ([-5, 0, -5]);
begin
   --  The old answers: 4 distinct items, 4 with one repeated pair, 12 with
   --  one repeated pair (12! / 2).
   Check_Count ([1, 2, 3, 4], 24);
   Check_Count ([1, 1, 2, 3], 12);
   Check_Count (Twelve, 239_500_800);
   --  By hand: 3! / 2! = 3, 4! / (2! 2!) = 6, 6! / (1! 2! 3!) = 60.
   Check_Count ([1, 1, 2], 3);
   Check_Count ([1, 1, 2, 2], 6);
   Check_Count ([1, 2, 2, 3, 3, 3], 60);
   Check_Count ([1, 1, 1], 1);
   Check_Count (Same, 1);
   Check_Count ([1 .. 0 => 0], 1);

   --  1 1 2 -> 1 2 1 -> 2 1 1 -> wraps to 1 1 2.
   Step (A, [1, 2, 1], True);
   Step (A, [2, 1, 1], True);
   Step (A, [1, 1, 2], False);
   --  By hand: 1 3 2 2: pivot 1, the rightmost larger value is the last 2;
   --  swap to 2 3 2 1 and reverse the tail: 2 1 2 3.
   Step (B, [2, 1, 2, 3], True);
   --  The last arrangement wraps to the sorted one.
   Step (L, [1, 2, 2, 3], False);
   Step (E, [1 .. 0 => 0], False);
   --  Negative values: -5 0 -5 -> 0 -5 -5 -> wraps to -5 -5 0.
   Step (M, [0, -5, -5], True);
   Step (M, [-5, -5, 0], False);
   Step (M, [-5, 0, -5], True);

   Ada.Text_IO.Put_Line ("permutations II tests passed");
end Tests;
