pragma Ada_2022;
package Power_Of_Four with SPARK_Mode => On is
   subtype Input is Positive range 1 .. Integer'Last / 4;

   function Is_Power (Value : Input) return Boolean with Global => null;
end Power_Of_Four;
