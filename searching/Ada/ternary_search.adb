--  Ternary_Search body — discrete unimodal peak finding and optional
--  ternary key search on a sorted ascending array.

pragma Ada_2022;

package body Ternary_Search
  with SPARK_Mode => Off
is

   --  When Hi - Lo <= Threshold, finish with a linear scan (avoids
   --  degenerate m1/m2 collisions on tiny windows).
   Threshold : constant Natural := 2;

   function Find_Maximum_Index (A : Element_Array) return Natural is
      Lo, Hi : Natural;
      M1, M2 : Natural;
      Best   : Natural;
   begin
      if A'Length = 0 or else A'Length > Max_N then
         raise Invalid_Argument;
      end if;

      if A'Length = 1 then
         return A'First;
      end if;

      Lo := A'First;
      Hi := A'Last;

      while Hi - Lo > Threshold loop
         M1 := Lo + (Hi - Lo) / 3;
         M2 := Hi - (Hi - Lo) / 3;

         if A (M1) < A (M2) then
            --  Peak cannot lie at or left of M1 on a unimodal array.
            Lo := M1 + 1;
         elsif A (M1) > A (M2) then
            --  Peak cannot lie at or right of M2.
            Hi := M2 - 1;
         else
            --  Equal: for (non-)strict unimodal, a maximum lies in [M1, M2].
            Lo := M1;
            Hi := M2;
         end if;
      end loop;

      Best := Lo;
      for I in Lo + 1 .. Hi loop
         if A (I) > A (Best) then
            Best := I;
         end if;
      end loop;
      return Best;
   end Find_Maximum_Index;

   function Find (A : Element_Array; Key : Integer) return Integer is
      Lo, Hi : Integer;
      M1, M2 : Integer;
   begin
      if A'Length > Max_N then
         raise Invalid_Argument;
      end if;

      if A'Length = 0 then
         --  Empty: sentinel relative to the (vacuous) first bound.
         --  Use 0'Pred style: Natural'First is 0, so First-1 = -1 when
         --  the subtype lower bound is 0; for a constrained empty slice
         --  A'First is still defined.
         return Integer (A'First) - 1;
      end if;

      Lo := Integer (A'First);
      Hi := Integer (A'Last);

      while Lo <= Hi loop
         declare
            Span : constant Integer := Hi - Lo;
         begin
            M1 := Lo + Span / 3;
            M2 := Hi - Span / 3;

            if A (Natural (M1)) = Key then
               return M1;
            end if;
            if M2 /= M1 and then A (Natural (M2)) = Key then
               return M2;
            end if;

            if Key < A (Natural (M1)) then
               Hi := M1 - 1;
            elsif Key > A (Natural (M2)) then
               Lo := M2 + 1;
            else
               --  Key is strictly between A(M1) and A(M2).
               Lo := M1 + 1;
               Hi := M2 - 1;
            end if;
         end;
      end loop;

      return Integer (A'First) - 1;
   end Find;

end Ternary_Search;
