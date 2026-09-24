pragma Ada_2022;

package Next_Greater_Element_I with SPARK_Mode => On is
   subtype Position is Positive range 1 .. 4;
   type Value_Array is array (Position) of Integer range 0 .. 32;
   type Result_Array is array (Position) of Integer range -1 .. 32;

   function Next_Greater (Values : Value_Array) return Result_Array
     with Global => null;
end Next_Greater_Element_I;
