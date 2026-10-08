pragma Ada_2022;

package Sort_An_Array with SPARK_Mode => On is
   Length : constant := 8;
   subtype Index is Positive range 1 .. Length;
   subtype Value is Integer range -100 .. 100;
   type Input_Array is array (Index) of Value;

   procedure Sort (Data : in out Input_Array)
     with Global => null;
end Sort_An_Array;
