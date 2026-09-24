--  Interpolation_Search body — classic linear-interpolation probe search.

pragma Ada_2022;

package body Interpolation_Search
  with SPARK_Mode => Off
is

   function Find (A : Element_Array; Key : Integer) return Integer is
      Lo, Hi : Integer;
      Pos    : Integer;
      --  Wider arithmetic for (Key - A(Lo)) * (Hi - Lo) avoids Integer
      --  overflow when value span and index span are both large.
      Diff_Key : Long_Long_Integer;
      Diff_Val : Long_Long_Integer;
      Span     : Long_Long_Integer;
      Offset   : Long_Long_Integer;
   begin
      if A'Length > Max_N then
         raise Invalid_Argument with
           "Find: array length exceeds Max_N";
      end if;

      if A'Length = 0 then
         return Integer (A'First) - 1;
      end if;

      Lo := Integer (A'First);
      Hi := Integer (A'Last);

      while Lo <= Hi
        and then Key >= A (Natural (Lo))
        and then Key <= A (Natural (Hi))
      loop
         --  Equal bounds: whole remaining window shares one value.
         if A (Natural (Hi)) = A (Natural (Lo)) then
            if A (Natural (Lo)) = Key then
               return Lo;
            else
               return Integer (A'First) - 1;
            end if;
         end if;

         Diff_Key := Long_Long_Integer (Key)
           - Long_Long_Integer (A (Natural (Lo)));
         Span     := Long_Long_Integer (Hi - Lo);
         Diff_Val := Long_Long_Integer (A (Natural (Hi)))
           - Long_Long_Integer (A (Natural (Lo)));
         Offset   := (Diff_Key * Span) / Diff_Val;
         Pos      := Lo + Integer (Offset);

         --  Defensive clamp: for sorted data with Key in [A(Lo), A(Hi)]
         --  the estimate lands in [Lo, Hi]; clamp covers edge rounding.
         if Pos < Lo then
            Pos := Lo;
         elsif Pos > Hi then
            Pos := Hi;
         end if;

         if A (Natural (Pos)) = Key then
            return Pos;
         elsif A (Natural (Pos)) < Key then
            Lo := Pos + 1;
         else
            Hi := Pos - 1;
         end if;
      end loop;

      return Integer (A'First) - 1;
   end Find;

end Interpolation_Search;
