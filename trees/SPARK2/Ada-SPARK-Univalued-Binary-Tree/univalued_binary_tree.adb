pragma Ada_2022;

package body Univalued_Binary_Tree with SPARK_Mode => On is
   function Is_Univalued (Input : Tree) return Boolean is
      First : constant Value := Input (Index'First);
   begin
      for I in Index loop
         if Input (I) /= First then
            return False;
         end if;
      end loop;
      return True;
   end Is_Univalued;
end Univalued_Binary_Tree;
