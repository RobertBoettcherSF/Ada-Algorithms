pragma Ada_2022;
package body Rectangle_Area with SPARK_Mode => On is
   function Area (R : Rectangle) return Area_Value is
      Result : constant Area_Value := R.Width * R.Height;
   begin
      pragma Assert (Result <= 100);
      return Result;
   end Area;
end Rectangle_Area;
