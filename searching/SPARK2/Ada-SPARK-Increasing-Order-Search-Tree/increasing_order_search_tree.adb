pragma Ada_2022;

package body Increasing_Order_Search_Tree with SPARK_Mode => On is
   function Increasing_Order (Input : Tree) return Tree is
      Work : Tree := Input;
      Temporary : Value;
   begin
      for I in Index loop
         for J in Index loop
            if J > I and then Work (J) < Work (I) then
               Temporary := Work (I);
               Work (I) := Work (J);
               Work (J) := Temporary;
            end if;
         end loop;
      end loop;
      return Work;
   end Increasing_Order;
end Increasing_Order_Search_Tree;
