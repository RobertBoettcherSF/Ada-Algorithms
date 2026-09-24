pragma Ada_2022;

package Next_Permutation_Stub with SPARK_Mode => On is
   Length : constant := 4;
   subtype Index is Positive range 1 .. Length;
   subtype Value is Integer range 0 .. 9;
   type Input_Array is array (Index) of Value;

   function Next (Input : Input_Array) return Input_Array
     with Global => null;
end Next_Permutation_Stub;
