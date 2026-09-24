pragma Ada_2022;

package body Sliding_Window_Median with SPARK_Mode => On is
   function Median_Of_Three (A, B, C : Value) return Value is
   begin
      if A > B then
         if B > C then
            return B;
         elsif A > C then
            return C;
         else
            return A;
         end if;
      else
         if A > C then
            return A;
         elsif B > C then
            return C;
         else
            return B;
         end if;
      end if;
   end Median_Of_Three;

   function Medians (Input : Input_Array) return Output_Array is
   begin
      return [Median_Of_Three (Input (1), Input (2), Input (3)),
              Median_Of_Three (Input (2), Input (3), Input (4)),
              Median_Of_Three (Input (3), Input (4), Input (5)),
              Median_Of_Three (Input (4), Input (5), Input (6)),
              Median_Of_Three (Input (5), Input (6), Input (7)),
              Median_Of_Three (Input (6), Input (7), Input (8))];
   end Medians;
end Sliding_Window_Median;
