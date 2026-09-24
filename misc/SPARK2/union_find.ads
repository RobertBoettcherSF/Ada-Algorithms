pragma Ada_2022;
package Union_Find with SPARK_Mode => On is
   Capacity : constant := 4;
   subtype Node is Positive range 1 .. Capacity;
   type Set is private;
   procedure Initialize (S : out Set);
   function Find (S : Set; N : Node) return Node;
   procedure Union (S : in out Set; A, B : Node);
   function Same (S : Set; A, B : Node) return Boolean;
private
   type Parent_Array is array (Node) of Node;
   type Set is record Parent : Parent_Array; end record;
end Union_Find;
