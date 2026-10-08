pragma Ada_2022;

package Beautiful_Array with SPARK_Mode => On is
   Length : constant := 8;
   subtype Index is Positive range 1 .. Length;
   subtype Value is Integer range 1 .. Length;
   type Input_Array is array (Index) of Value;

   function Is_Beautiful (Input : Input_Array) return Boolean
     with Global => null;
end Beautiful_Array;
