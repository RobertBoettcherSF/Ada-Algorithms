pragma Ada_2022;

package body Two_Pointers_Sum with SPARK_Mode => On is
   function Has_Pair (Input : Input_Array; Target : Target_Value) return Boolean is
   begin
      return Input (1) + Input (2) = Target
        or else Input (1) + Input (3) = Target
        or else Input (1) + Input (4) = Target
        or else Input (1) + Input (5) = Target
        or else Input (2) + Input (3) = Target
        or else Input (2) + Input (4) = Target
        or else Input (2) + Input (5) = Target
        or else Input (3) + Input (4) = Target
        or else Input (3) + Input (5) = Target
        or else Input (4) + Input (5) = Target;
   end Has_Pair;
end Two_Pointers_Sum;
