pragma Ada_2022;

package body Trim_Binary_Search_Tree with SPARK_Mode => On is
   function Trim (Input : Tree; Low, High : Value) return Tree is
      Work : Tree := Input;
   begin
      for I in Index loop
         if Work (I) < Low then
            Work (I) := Low;
         elsif Work (I) > High then
            Work (I) := High;
         end if;
      end loop;
      return Work;
   end Trim;
end Trim_Binary_Search_Tree;
