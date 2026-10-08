pragma Ada_2022;
package Rectangle_Area with SPARK_Mode => On is
   subtype Side_Length is Natural range 0 .. 10;
   subtype Area_Value is Natural range 0 .. 100;
   type Rectangle is record
      Width, Height : Side_Length;
   end record;
   function Area (R : Rectangle) return Area_Value with Global => null;
end Rectangle_Area;
