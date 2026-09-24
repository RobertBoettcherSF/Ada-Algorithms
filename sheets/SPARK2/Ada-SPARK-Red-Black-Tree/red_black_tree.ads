pragma Ada_2022;
package Red_Black_Tree
  with SPARK_Mode => On
is
   Max_Nodes : constant := 16;
   subtype Node_Index is Natural range 0 .. Max_Nodes;
   type Color is (Red, Black);
   type Node is record
      Key : Integer := 0;
      Shade : Color := Black;
   end record;

   function Is_Red (C : Color) return Boolean
     with Global => null;
   procedure Rotate_Left (Root : in out Node_Index)
     with Global => null;
end Red_Black_Tree;
