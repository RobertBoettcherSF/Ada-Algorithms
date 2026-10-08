pragma Ada_2022;

package body Magnetic_Force_Between_Two_Balls with SPARK_Mode => On is
   function Maximum_Force (Positions : Position_Array) return Distance is
   begin
      return Positions (Index'Last) - Positions (Index'First);
   end Maximum_Force;
end Magnetic_Force_Between_Two_Balls;
