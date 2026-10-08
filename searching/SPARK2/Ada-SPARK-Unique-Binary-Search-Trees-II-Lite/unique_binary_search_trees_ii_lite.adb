pragma Ada_2022;
package body Unique_Binary_Search_Trees_II_Lite with SPARK_Mode => On is
   function Root_Choices (N : Node_Count) return Node_Count is
   begin
      return N;
   end Root_Choices;
end Unique_Binary_Search_Trees_II_Lite;
