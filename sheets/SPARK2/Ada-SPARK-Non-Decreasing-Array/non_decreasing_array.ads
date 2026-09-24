pragma Ada_2022;
pragma SPARK_Mode (On);
package Non_Decreasing_Array is
   subtype Value is Integer range -32 .. 32;
   function Can_Be_Non_Decreasing (First, Second, Third : Value) return Boolean
     with Global => null;
end Non_Decreasing_Array;
