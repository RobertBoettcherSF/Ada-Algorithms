pragma Ada_2022;

package body Merge_Sorted_Arrays with SPARK_Mode => On is
   function Merge (Left, Right : Input_Array) return Output_Array is
      Result : Output_Array;
      Left_Position : Integer range 1 .. 4 := 1;
      Right_Position : Integer range 1 .. 4 := 1;
   begin
      for K in Output_Index loop
         if Left_Position <= Left'Last
           and then (Right_Position > Right'Last
                     or else Left (Left_Position) <= Right (Right_Position))
         then
            Result (K) := Left (Left_Position);
            if Left_Position < Left'Last then
               Left_Position := Left_Position + 1;
            else
               Left_Position := Left'Last + 1;
            end if;
         else
            Result (K) := Right (Right_Position);
            if Right_Position < Right'Last then
               Right_Position := Right_Position + 1;
            else
               Right_Position := Right'Last + 1;
            end if;
         end if;
      end loop;
      return Result;
   end Merge;
end Merge_Sorted_Arrays;
