pragma Ada_2022;

package body Sliding_Window_Maximum with SPARK_Mode => On is
   function Maximum (A, B, C : Value) return Value is
      R : Value := A;
   begin
      if B > R then R := B; end if;
      if C > R then R := C; end if;
      return R;
   end Maximum;

   function Maximums (Input : Input_Array) return Output_Array is
   begin
      return [Maximum (Input (1), Input (2), Input (3)), Maximum (Input (2), Input (3), Input (4)), Maximum (Input (3), Input (4), Input (5)), Maximum (Input (4), Input (5), Input (6)), Maximum (Input (5), Input (6), Input (7)), Maximum (Input (6), Input (7), Input (8))];
   end Maximums;
end Sliding_Window_Maximum;
