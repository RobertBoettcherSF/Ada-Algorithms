pragma Ada_2022;

package Contains_Duplicate_II with SPARK_Mode => On is
   Length : constant := 8;
   Distance : constant := 2;
   subtype Index is Positive range 1 .. Length;
   subtype Value is Integer range -20 .. 20;
   type Input_Array is array (Index) of Value;

   function Has_Nearby_Duplicate (Input : Input_Array) return Boolean
     with Global => null;
end Contains_Duplicate_II;
