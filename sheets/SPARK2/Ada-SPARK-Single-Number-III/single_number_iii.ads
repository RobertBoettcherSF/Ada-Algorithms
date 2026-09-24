pragma Ada_2022;
package Single_Number_III with SPARK_Mode => On is
   subtype Index is Positive range 1 .. 6;
   subtype Value is Integer range -100 .. 100;
   type Vector is array (Index) of Value;
   type Pair is record
      First  : Value;
      Second : Value;
   end record;
   function Singles (Values : Vector) return Pair
     with Global => null,
          Pre => Values (1) = Values (4)
            and then Values (2) = Values (5),
          Post => Singles'Result.First = Values (3)
            and then Singles'Result.Second = Values (6);
end Single_Number_III;
