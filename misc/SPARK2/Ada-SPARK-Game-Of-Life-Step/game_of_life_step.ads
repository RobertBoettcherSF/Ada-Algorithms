pragma Ada_2022;

package Game_Of_Life_Step with SPARK_Mode => On is
   Side : constant := 3;
   subtype Index is Positive range 1 .. Side;
   subtype Cell is Natural range 0 .. 1;
   type Board is array (Index, Index) of Cell;

   procedure Step (Input : in out Board);
end Game_Of_Life_Step;
