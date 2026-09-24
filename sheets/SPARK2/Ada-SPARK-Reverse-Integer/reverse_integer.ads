pragma SPARK_Mode (On);

package Reverse_Integer is
   subtype Input is Integer range -99 .. 99;

   function Reversed (Value : Input) return Input
     with Global => null;
end Reverse_Integer;
