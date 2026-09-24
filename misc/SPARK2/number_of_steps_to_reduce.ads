pragma Ada_2022;
package Number_Of_Steps_To_Reduce with SPARK_Mode => On is
   subtype Input is Positive range 1 .. 15;
   subtype Step_Count is Natural range 0 .. 6;
   function Steps (Value : Input) return Step_Count
     with Global => null;
end Number_Of_Steps_To_Reduce;
