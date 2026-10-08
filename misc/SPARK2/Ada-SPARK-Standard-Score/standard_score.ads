pragma Ada_2022;

package Standard_Score with SPARK_Mode => On is
   Sample_Count : constant := 5;
   subtype Index is Positive range 1 .. Sample_Count;
   subtype Sample is Integer range 0 .. 10;
   type Sample_Array is array (Index) of Sample;

   function Mean (Data : Sample_Array) return Sample with Global => null;
   function Score (Data : Sample_Array; Position : Index) return Integer
     with Global => null;
end Standard_Score;
