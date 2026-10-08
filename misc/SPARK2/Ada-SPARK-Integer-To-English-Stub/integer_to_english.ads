pragma SPARK_Mode (On);

package Integer_To_English is
   subtype Number is Natural range 0 .. 19;
   type English_Number is
     (Zero, One, Two, Three, Four, Five, Six, Seven, Eight, Nine,
      Ten, Eleven, Twelve, Thirteen, Fourteen, Fifteen, Sixteen,
      Seventeen, Eighteen, Nineteen);

   function To_English (Value : Number) return English_Number
     with Global => null;
end Integer_To_English;
