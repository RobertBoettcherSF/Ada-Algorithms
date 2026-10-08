pragma Ada_2022;
package body Red_Black_Tree
  with SPARK_Mode => On
is
   function Is_Red (C : Color) return Boolean is
   begin
      return C = Red;
   end Is_Red;

   procedure Rotate_Left (Root : in out Node_Index) is
   begin
      -- The bounded index is the teaching stub for a future tree rotation.
      if Root < Node_Index'Last then
         Root := Root + 1;
      end if;
   end Rotate_Left;
end Red_Black_Tree;
