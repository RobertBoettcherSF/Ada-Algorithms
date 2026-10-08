pragma Ada_2022;
pragma SPARK_Mode (On);
package body Non_Decreasing_Array is
   function Can_Be_Non_Decreasing (First, Second, Third : Value) return Boolean is
   begin
      return (First <= Second and then Second <= Third)
        or else First <= Third or else Second <= Third;
   end Can_Be_Non_Decreasing;
end Non_Decreasing_Array;
