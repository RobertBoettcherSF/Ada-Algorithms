pragma Ada_2022;
package body Can_Place_Flowers with SPARK_Mode => On is
   function Can_Place (Available, Requested : Flower_Count) return Boolean is
   begin
      return Available >= Requested;
   end Can_Place;
end Can_Place_Flowers;
