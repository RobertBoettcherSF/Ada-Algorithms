pragma Ada_2022;

package Count_And_Say with SPARK_Mode => On is
   Length : constant := 6;
   subtype Index is Positive range 1 .. Length;
   subtype Digit is Natural range 0 .. 9;
   subtype Run_Count is Positive range 1 .. Length;
   type Digit_Array is array (Index) of Digit;
   type Run is record
      Count : Run_Count;
      Value : Digit;
   end record;

   function First_Run (Input : Digit_Array) return Run
     with Global => null;
end Count_And_Say;
