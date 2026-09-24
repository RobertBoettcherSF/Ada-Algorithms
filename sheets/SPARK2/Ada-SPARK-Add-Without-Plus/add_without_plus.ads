pragma SPARK_Mode (On);

package Add_Without_Plus is
   subtype Operand is Integer range -100 .. 100;

   function Add (Left, Right : Operand) return Integer
     with Global => null;
end Add_Without_Plus;
