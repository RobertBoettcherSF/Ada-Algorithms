pragma SPARK_Mode (On);

package Special_Array_With_X_Elements is
   subtype Value is Integer range 0 .. 8;
   type Array_Of_Values is array (1 .. 8) of Value;

   function Is_Special (A : Array_Of_Values; X : Value) return Boolean;
end Special_Array_With_X_Elements;
