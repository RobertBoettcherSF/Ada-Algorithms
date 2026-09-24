pragma Ada_2022;
package Can_Place_Flowers with SPARK_Mode => On is
   subtype Flower_Count is Natural range 0 .. 32;

   function Can_Place (Available, Requested : Flower_Count) return Boolean
     with Global => null;
end Can_Place_Flowers;
