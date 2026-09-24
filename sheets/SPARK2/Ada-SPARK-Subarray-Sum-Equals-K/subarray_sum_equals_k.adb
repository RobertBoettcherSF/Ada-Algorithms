pragma Ada_2022;

package body Subarray_Sum_Equals_K with SPARK_Mode => On is
   function Hit (Condition : Boolean) return Integer is
     (if Condition then 1 else 0);

   function Count (Input : Input_Array; Target : Target_Value) return Integer is
   begin
      return
        Hit (Input (1) = Target)
        + Hit (Input (2) = Target)
        + Hit (Input (3) = Target)
        + Hit (Input (4) = Target)
        + Hit (Input (5) = Target)
        + Hit (Input (6) = Target)
        + Hit (Input (1) + Input (2) = Target)
        + Hit (Input (2) + Input (3) = Target)
        + Hit (Input (3) + Input (4) = Target)
        + Hit (Input (4) + Input (5) = Target)
        + Hit (Input (5) + Input (6) = Target)
        + Hit (Input (1) + Input (2) + Input (3) = Target)
        + Hit (Input (2) + Input (3) + Input (4) = Target)
        + Hit (Input (3) + Input (4) + Input (5) = Target)
        + Hit (Input (4) + Input (5) + Input (6) = Target)
        + Hit (Input (1) + Input (2) + Input (3) + Input (4) = Target)
        + Hit (Input (2) + Input (3) + Input (4) + Input (5) = Target)
        + Hit (Input (3) + Input (4) + Input (5) + Input (6) = Target)
        + Hit (Input (1) + Input (2) + Input (3) + Input (4) + Input (5) = Target)
        + Hit (Input (2) + Input (3) + Input (4) + Input (5) + Input (6) = Target)
        + Hit (Input (1) + Input (2) + Input (3) + Input (4) + Input (5) + Input (6) = Target);
   end Count;
end Subarray_Sum_Equals_K;
