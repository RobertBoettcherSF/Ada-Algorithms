pragma SPARK_Mode (On);

package Delete_Node_In_A_Linked_List is
   subtype Count is Natural range 0 .. 16;
   subtype Position is Count range 1 .. 16;
   subtype Value is Integer range -100 .. 100;
   type List is private;

   function Empty return List;
   procedure Append (L : in out List; V : Value);
   function Length (L : List) return Count;
   function Element (L : List; P : Position) return Value
     with Pre => P <= Length (L);
   procedure Delete_At (L : in out List; P : Position);
private
   type Value_Array is array (Position) of Value;
   type List is record
      Data : Value_Array := (others => 0);
      Size : Count := 0;
   end record;
end Delete_Node_In_A_Linked_List;
