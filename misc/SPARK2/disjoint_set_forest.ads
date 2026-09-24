pragma Ada_2022;
package Disjoint_Set_Forest with SPARK_Mode => On is
   Nodes : constant := 8; subtype Node is Positive range 1 .. Nodes; type Forest is private;
   procedure Initialize (F : out Forest); function Find (F : Forest; N : Node) return Node;
   procedure Union (F : in out Forest; A, B : Node); function Same (F : Forest; A, B : Node) return Boolean;
private
   subtype Rank is Natural range 0 .. Nodes; type Parent_Array is array (Node) of Node; type Rank_Array is array (Node) of Rank;
   type Forest is record Parent : Parent_Array; Rank_Of : Rank_Array; end record;
end Disjoint_Set_Forest;
