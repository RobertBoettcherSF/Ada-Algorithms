pragma Ada_2022;

package N_Repeated_Element_In_Size_2N_Array with SPARK_Mode => On is
   Length : constant := 4;
   subtype Index is Positive range 1 .. Length;
   subtype Value is Integer range 0 .. 10;
   type Input_Array is array (Index) of Value;

   function Has_Repeated (Input : Input_Array) return Boolean
     with Global => null;
end N_Repeated_Element_In_Size_2N_Array;
