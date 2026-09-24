pragma Ada_2022;

package body Binary_Tree_Right_Side_View with SPARK_Mode => On is
   function Right_View (Input : Tree) return View is
   begin
      return (1 => Input (1), 2 => Input (3), 3 => Input (7), 4 => Input (15));
   end Right_View;
end Binary_Tree_Right_Side_View;
