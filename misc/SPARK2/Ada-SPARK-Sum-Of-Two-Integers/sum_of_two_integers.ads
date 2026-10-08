pragma Ada_2022;
package Sum_Of_Two_Integers with SPARK_Mode => On is
   subtype Input is Integer range -1_000 .. 1_000;
   subtype Sum is Integer range -2_000 .. 2_000;
   function Add (Left, Right : Input) return Sum
     with Global => null,
          Post => Add'Result = Left + Right;
end Sum_Of_Two_Integers;
