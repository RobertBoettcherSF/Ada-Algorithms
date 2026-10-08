pragma SPARK_Mode (On);
package BST_Iterator_Stub is
   Capacity : constant := 8;
   subtype Count is Natural range 0 .. Capacity;
   subtype Value is Integer range -100 .. 100;
   subtype Index is Positive range 1 .. Capacity + 30;
   type Tree is private;
   type Iterator is private;
   function Empty return Tree with Global => null;
   procedure Insert (T : in out Tree; V : Value) with Global => null, Pre => Size (T) < Capacity;
   function Size (T : Tree) return Count with Global => null;
   function Create (T : Tree) return Iterator with Global => null;
   function Has_Next (It : Iterator) return Boolean with Global => null;
   procedure Next (It : in out Iterator; Result : out Value) with Global => null, Pre => Has_Next (It);
private
   subtype Cursor_Position is Natural range 0 .. Capacity + 20;
   type Value_Array is array (Index) of Value;
   type Tree is record Data : Value_Array := (others => 0); Size : Count := 0; end record;
   type Iterator is record Data : Value_Array := (others => 0); Size : Count := 0; Position : Cursor_Position := 0; end record;
end BST_Iterator_Stub;
