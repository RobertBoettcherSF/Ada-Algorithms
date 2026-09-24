pragma Ada_2022;

package Find_Peak_Element with SPARK_Mode => On is
   Length : constant := 8;
   subtype Index is Positive range 1 .. Length;
   subtype Value is Integer range -1000 .. 1000;
   type Input_Array is array (Index) of Value;

   function Find_Peak (Input : Input_Array) return Index
     with Global => null;
end Find_Peak_Element;
