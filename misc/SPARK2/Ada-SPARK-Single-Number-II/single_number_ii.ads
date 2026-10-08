pragma Ada_2022;
package Single_Number_II with SPARK_Mode => On is
   subtype Index is Positive range 1 .. 5;
   subtype Value is Integer range -100 .. 100;
   type Vector is array (Index) of Value;
   function Single (Values : Vector) return Value
     with Global => null,
          Pre => Values (1) = Values (2)
            and then Values (2) = Values (4)
            and then Values (4) = Values (5),
          Post => Single'Result = Values (3);
end Single_Number_II;
