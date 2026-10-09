pragma Ada_2022;
--  Scaffold for the failing test: the new API, still answering from the
--  old table (1 .. 8 operands); All_Results returns nothing yet.
package Different_Ways_Parentheses with SPARK_Mode => On is
   subtype Operand_Count is Positive range 1 .. 20;
   function Number_Of_Ways (Operands : Operand_Count) return Positive with Global => null;

   Max_Expression : constant := 8;
   subtype Operand is Integer range -99 .. 99;
   type Operator is (Plus, Minus, Times);
   type Operand_List is array (Positive range <>) of Operand;
   type Operator_List is array (Positive range <>) of Operator;
   type Value_List is array (Positive range <>) of Long_Long_Integer;

   function All_Results (Values : Operand_List; Ops : Operator_List) return Value_List
   with
     Global => null,
     Pre    => Values'First = 1 and then Values'Length in 1 .. Max_Expression
               and then Ops'First = 1 and then Ops'Length = Values'Length - 1;
end Different_Ways_Parentheses;
