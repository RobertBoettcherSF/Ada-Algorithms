--  Binary_Search body — classic iterative binary search with overflow-safe
--  midpoint, plus leftmost / rightmost duplicate-key variants (Wikipedia).

pragma Ada_2022;

package body Binary_Search
  with SPARK_Mode => Off
is

   procedure Check_Bounds (A : Element_Array) is
   begin
      if A'Length > Max_N then
         raise Invalid_Argument
           with "array length exceeds Max_N";
      end if;
   end Check_Bounds;

   function Sentinel (A : Element_Array) return Integer is
   begin
      return Integer (A'First) - 1;
   end Sentinel;

   ---------------------------------------------------------------------------
   -- Classic iterative Find (Wikipedia "Procedure")
   ---------------------------------------------------------------------------

   function Find (A : Element_Array; Key : Integer) return Integer is
      Lo  : Integer;
      Hi  : Integer;
      Mid : Integer;
   begin
      Check_Bounds (A);

      if A'Length = 0 then
         return Sentinel (A);
      end if;

      Lo := Integer (A'First);
      Hi := Integer (A'Last);

      while Lo <= Hi loop
         --  Overflow-safe midpoint (Bentley / Java library lesson):
         --  mid = lo + (hi − lo) / 2, never (lo + hi) / 2.
         Mid := Lo + (Hi - Lo) / 2;

         if A (Natural (Mid)) < Key then
            Lo := Mid + 1;
         elsif A (Natural (Mid)) > Key then
            Hi := Mid - 1;
         else
            return Mid;
         end if;
      end loop;

      return Sentinel (A);
   end Find;

   ---------------------------------------------------------------------------
   -- Leftmost (Find_First) — Wikipedia "Procedure for finding the leftmost
   -- element" / lower_bound style on half-open [L, R).
   ---------------------------------------------------------------------------

   function Find_First (A : Element_Array; Key : Integer) return Integer is
      Lo  : Integer;
      Hi  : Integer;
      Mid : Integer;
   begin
      Check_Bounds (A);

      if A'Length = 0 then
         return Sentinel (A);
      end if;

      --  Half-open interval over Ada indices: [A'First, A'Last + 1).
      Lo := Integer (A'First);
      Hi := Integer (A'Last) + 1;

      while Lo < Hi loop
         Mid := Lo + (Hi - Lo) / 2;
         if A (Natural (Mid)) < Key then
            Lo := Mid + 1;
         else
            --  A(Mid) ≥ Key: keep Mid as exclusive upper (may be equal).
            Hi := Mid;
         end if;
      end loop;

      --  Lo is the first index with A(Lo) ≥ Key, or one past A'Last.
      if Lo <= Integer (A'Last) and then A (Natural (Lo)) = Key then
         return Lo;
      else
         return Sentinel (A);
      end if;
   end Find_First;

   ---------------------------------------------------------------------------
   -- Rightmost (Find_Last) — Wikipedia "Procedure for finding the rightmost
   -- element" / upper_bound − 1.
   ---------------------------------------------------------------------------

   function Find_Last (A : Element_Array; Key : Integer) return Integer is
      Lo  : Integer;
      Hi  : Integer;
      Mid : Integer;
      Cand : Integer;
   begin
      Check_Bounds (A);

      if A'Length = 0 then
         return Sentinel (A);
      end if;

      Lo := Integer (A'First);
      Hi := Integer (A'Last) + 1;

      while Lo < Hi loop
         Mid := Lo + (Hi - Lo) / 2;
         if A (Natural (Mid)) > Key then
            Hi := Mid;
         else
            --  A(Mid) ≤ Key: advance past Mid.
            Lo := Mid + 1;
         end if;
      end loop;

      --  Wikipedia returns R − 1 (here Hi − 1); that is the last ≤ Key.
      Cand := Hi - 1;
      if Cand >= Integer (A'First) and then A (Natural (Cand)) = Key then
         return Cand;
      else
         return Sentinel (A);
      end if;
   end Find_Last;

end Binary_Search;
