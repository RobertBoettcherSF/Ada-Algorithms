pragma Ada_2022;

package body N_Repeated_Element_In_Size_2N_Array with SPARK_Mode => On is
   function Has_Repeated (Input : Input_Array) return Boolean is
   begin
      return Input (1) = Input (2) or else Input (1) = Input (3)
        or else Input (1) = Input (4) or else Input (2) = Input (3)
        or else Input (2) = Input (4) or else Input (3) = Input (4);
   end Has_Repeated;
end N_Repeated_Element_In_Size_2N_Array;
