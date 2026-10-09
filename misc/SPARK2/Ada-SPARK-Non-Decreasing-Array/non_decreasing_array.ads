pragma Ada_2022;
pragma SPARK_Mode (On);
package Non_Decreasing_Array is
   subtype Value is Integer range -32 .. 32;

   --  True when (First, Second, Third) can be made non-decreasing by
   --  changing at most one element. Changing First works when
   --  Second <= Third, changing Second when First <= Third, changing
   --  Third when First <= Second (an already sorted triple satisfies all
   --  three).
   function Can_Be_Non_Decreasing (First, Second, Third : Value) return Boolean
     with Global => null,
          Post   => Can_Be_Non_Decreasing'Result =
                      (Second <= Third or else First <= Third or else First <= Second);
end Non_Decreasing_Array;
