--  Shell_Sort body — Ciura gaps (+ floor(h/2.25) extension), gapped insert.

pragma Ada_2022;

package body Shell_Sort
  with SPARK_Mode => Off
is

   --  Marcin Ciura's empirically derived gaps (descending), Wikipedia table.
   --  Extended beyond 701 with h_k = floor(2.25 · h_{k-1}) when n is larger.
   Ciura_Gaps : constant array (Positive range <>) of Natural :=
     [701, 301, 132, 57, 23, 10, 4, 1];

   procedure Check_Bounds (A : Element_Array) is
   begin
      if A'Length > Max_N then
         raise Invalid_Argument
           with "array length exceeds Max_N";
      end if;
   end Check_Bounds;

   --  Insertion-sort each of the Gap interleaved subsequences (h-sort).
   --  Works for any A'First. Gap must be >= 1 and < A'Length.
   procedure Gap_Insertion_Sort
     (A   : in out Element_Array;
      Gap : Positive)
   is
      Key : Integer;
      J   : Natural;
   begin
      for I in A'First + Gap .. A'Last loop
         Key := A (I);
         J   := I;
         while J >= A'First + Gap and then A (J - Gap) > Key loop
            A (J) := A (J - Gap);
            J     := J - Gap;
         end loop;
         A (J) := Key;
      end loop;
   end Gap_Insertion_Sort;

   --  floor(2.25 · H) via integer arithmetic: floor(9H / 4).
   function Floor_Times_2_25 (H : Natural) return Natural is
   begin
      return (H * 9) / 4;
   end Floor_Times_2_25;

   --  floor(H / 2.25) via integer arithmetic: floor(4H / 9).
   function Floor_Div_2_25 (H : Natural) return Natural is
   begin
      return (H * 4) / 9;
   end Floor_Div_2_25;

   procedure Sort (A : in out Element_Array) is
      N : constant Natural := A'Length;
   begin
      Check_Bounds (A);

      if N <= 1 then
         return;
      end if;

      --  Extended gaps > 701 when n is large enough to need them.
      if N > Ciura_Gaps (Ciura_Gaps'First) then
         declare
            Gap  : Natural := Ciura_Gaps (Ciura_Gaps'First);
            Next : Natural;
         begin
            --  Grow to the largest extended gap strictly less than N.
            loop
               Next := Floor_Times_2_25 (Gap);
               exit when Next >= N or else Next <= Gap;
               Gap := Next;
            end loop;

            --  Descend with floor(gap / 2.25) until Ciura's top gap.
            while Gap > Ciura_Gaps (Ciura_Gaps'First) loop
               Gap_Insertion_Sort (A, Gap);
               Gap := Floor_Div_2_25 (Gap);
            end loop;
         end;
      end if;

      --  Published Ciura sequence (only gaps strictly less than n).
      for K in Ciura_Gaps'Range loop
         if Ciura_Gaps (K) < N then
            Gap_Insertion_Sort (A, Ciura_Gaps (K));
         end if;
      end loop;
   end Sort;

   function Is_Sorted (A : Element_Array) return Boolean is
   begin
      if A'Length <= 1 then
         return True;
      end if;
      for I in A'First + 1 .. A'Last loop
         if A (I - 1) > A (I) then
            return False;
         end if;
      end loop;
      return True;
   end Is_Sorted;

end Shell_Sort;
