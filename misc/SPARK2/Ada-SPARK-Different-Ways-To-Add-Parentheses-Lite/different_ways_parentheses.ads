pragma Ada_2022;

package Different_Ways_Parentheses with SPARK_Mode => On is
   subtype Operand_Count is Positive range 1 .. 8;
   subtype Way_Count is Natural range 0 .. 1000;

   function Number_Of_Ways (Operands : Operand_Count) return Way_Count
     with Global => null;
end Different_Ways_Parentheses;
