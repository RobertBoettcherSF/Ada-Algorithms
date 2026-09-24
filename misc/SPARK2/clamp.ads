pragma SPARK_Mode (On);

package Clamp is
   function Value (Input, Lower, Upper : Integer) return Integer
     with Pre => Lower <= Upper,
          Post => Value'Result >= Lower and then Value'Result <= Upper;
end Clamp;
