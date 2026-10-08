pragma Ada_2022;

package Binary_Tree_Right_Side_View with SPARK_Mode => On is
   Capacity : constant := 15;
   subtype Index is Positive range 1 .. Capacity;
   subtype Level is Positive range 1 .. 4;
   subtype Value is Integer range -100 .. 100;
   type Tree is array (Index) of Value;
   type View is array (Level) of Value;

   function Right_View (Input : Tree) return View
     with Global => null;
end Binary_Tree_Right_Side_View;
