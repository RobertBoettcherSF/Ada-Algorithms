pragma Ada_2022;

package body Maximum_Subarray_Circular with SPARK_Mode => On is
   function Max_Subarray (Input : Input_Array) return Integer is
      Sum : Integer range -160 .. 160 := Input (Index'First);
      Current_Max : Integer range -160 .. 160 := Input (Index'First);
      Best_Max : Integer range -160 .. 160 := Input (Index'First);
      Current_Min : Integer range -160 .. 160 := Input (Index'First);
      Best_Min : Integer range -160 .. 160 := Input (Index'First);
      With_Max : Integer range -160 .. 160;
      With_Min : Integer range -160 .. 160;
   begin
      for I in Index range 2 .. Index'Last loop
         Sum := Sum + Input (I);
         With_Max := Current_Max + Input (I);
         if Input (I) > With_Max then
            Current_Max := Input (I);
         else
            Current_Max := With_Max;
         end if;
         if Current_Max > Best_Max then
            Best_Max := Current_Max;
         end if;
         With_Min := Current_Min + Input (I);
         if Input (I) < With_Min then
            Current_Min := Input (I);
         else
            Current_Min := With_Min;
         end if;
         if Current_Min < Best_Min then
            Best_Min := Current_Min;
         end if;
      end loop;
      if Best_Max < 0 then
         return Best_Max;
      elsif Best_Max > Sum - Best_Min then
         return Best_Max;
      else
         return Sum - Best_Min;
      end if;
   end Max_Subarray;
end Maximum_Subarray_Circular;
