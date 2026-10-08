pragma Ada_2022;

package body Convert_BST_To_Greater_Tree with SPARK_Mode => On is
   function Convert (Input : Tree) return Greater_Tree is
      Result : Greater_Tree;
      Running : Integer := 0;
   begin
      for I in reverse Index loop
         Running := Running + Input (I);
         Result (I) := Running;
      end loop;
      return Result;
   end Convert;
end Convert_BST_To_Greater_Tree;
