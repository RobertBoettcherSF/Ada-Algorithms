pragma Ada_2022;

package body Sliding_Window_Max with SPARK_Mode => On is
   function Maximum (A, B, C : Value) return Value is
      Result : Value := A;
   begin
      if B > Result then
         Result := B;
      end if;
      if C > Result then
         Result := C;
      end if;
      return Result;
   end Maximum;

   function Max_Window (Input : Input_Array) return Output_Array is
   begin
      return [Maximum (Input (1), Input (2), Input (3)),
              Maximum (Input (2), Input (3), Input (4)),
              Maximum (Input (3), Input (4), Input (5))];
   end Max_Window;
end Sliding_Window_Max;
