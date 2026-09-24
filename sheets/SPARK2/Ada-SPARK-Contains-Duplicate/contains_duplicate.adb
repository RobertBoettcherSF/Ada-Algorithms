pragma Ada_2022;

package body Contains_Duplicate with SPARK_Mode => On is
   function Has_Duplicate (Input : Input_Array) return Boolean is
   begin
      return Input (1) = Input (2) or else Input (1) = Input (3)
        or else Input (1) = Input (4) or else Input (1) = Input (5)
        or else Input (1) = Input (6) or else Input (2) = Input (3)
        or else Input (2) = Input (4) or else Input (2) = Input (5)
        or else Input (2) = Input (6) or else Input (3) = Input (4)
        or else Input (3) = Input (5) or else Input (3) = Input (6)
        or else Input (4) = Input (5) or else Input (4) = Input (6)
        or else Input (5) = Input (6);
   end Has_Duplicate;
end Contains_Duplicate;
