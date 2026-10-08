pragma Ada_2022;

package body Tim_Sort_Stub with SPARK_Mode => On is
   function Sort (Input : Value_Array) return Value_Array is
      Work      : Value_Array := Input;
      Temporary : Value;
      J         : Positive;
   begin
      if Work'Length <= 1 then
         return Work;
      end if;
      for I in Work'First + 1 .. Work'Last loop
         pragma Loop_Invariant (Sorted (Work, Work'First, I - 1));
         J := I;
         while J > Work'First and then Work (J - 1) > Work (J) loop
            pragma Loop_Invariant (J in Work'First + 1 .. I);
            pragma Loop_Invariant (Sorted (Work, Work'First, J - 1));
            pragma Loop_Invariant (Sorted (Work, J, I));
            pragma Loop_Invariant
              (for all A in Work'First .. J - 1 =>
                 (for all B in J + 1 .. I => Work (A) <= Work (B)));
            pragma Loop_Variant (Decreases => J);
            Temporary := Work (J - 1);
            Work (J - 1) := Work (J);
            Work (J) := Temporary;
            J := J - 1;
         end loop;
         pragma Assert (Sorted (Work, Work'First, I));
      end loop;
      return Work;
   end Sort;
end Tim_Sort_Stub;
