pragma Ada_2022;

package body Leaf_Similar_Trees with SPARK_Mode => On is
   function Leaf_Similar (Left, Right : Tree) return Boolean is
   begin
      for I in Leaf_Index loop
         if Left (I) /= Right (I) then
            return False;
         end if;
      end loop;
      return True;
   end Leaf_Similar;
end Leaf_Similar_Trees;
