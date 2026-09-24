pragma Ada_2022;

package Daily_Temperatures with SPARK_Mode => On is
   subtype Position is Positive range 1 .. 8;
   type Temperature_Array is array (Position) of Integer range -100 .. 100;
   type Distance_Array is array (Position) of Natural range 0 .. 7;

   function Next_Warmer (Temps : Temperature_Array) return Distance_Array
     with Global => null;
end Daily_Temperatures;
