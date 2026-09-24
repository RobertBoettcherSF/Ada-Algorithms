pragma Ada_2022;
package body Partition_Labels with SPARK_Mode => On is
   function Length_Of (First_Position, Last_Position : Position)
     return Partition_Length is
   begin
      return Last_Position - First_Position + 1;
   end Length_Of;
end Partition_Labels;
