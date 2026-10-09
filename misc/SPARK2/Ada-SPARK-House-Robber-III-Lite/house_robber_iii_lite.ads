pragma Ada_2022;
--  Scaffold for the failing test (replaced by the proved version).
package House_Robber_III_Lite with SPARK_Mode => On is
   Max_Nodes : constant := 100;
   Max_Value : constant := 10_000;
   subtype Node_Count is Natural range 0 .. Max_Nodes;
   subtype Index is Positive range 1 .. Max_Nodes;
   subtype Link is Natural range 0 .. Max_Nodes;
   subtype House_Value is Natural range 0 .. Max_Value;
   type Value_Array is array (Index range <>) of House_Value;
   type Link_Array is array (Index range <>) of Link;
   type Choice is array (Index range <>) of Boolean;
   type Tree (N : Node_Count) is record
      Value : Value_Array (1 .. N);
      Left  : Link_Array (1 .. N);
      Right : Link_Array (1 .. N);
   end record;
   function Max_Loot (T : Tree) return Natural;
   function Best_Choice (T : Tree) return Choice;
end House_Robber_III_Lite;
