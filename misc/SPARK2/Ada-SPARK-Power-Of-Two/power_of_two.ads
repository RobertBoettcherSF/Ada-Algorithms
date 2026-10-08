pragma SPARK_Mode (On);

package Power_Of_Two is
   subtype Input is Positive range 1 .. Integer'Last / 2;

   function Is_Power (Value : Input) return Boolean
     with Global => null;
end Power_Of_Two;
