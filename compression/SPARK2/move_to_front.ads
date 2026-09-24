pragma Ada_2022;
package Move_To_Front with SPARK_Mode => On is
   Table_Size : constant := 16;
   subtype Index is Positive range 1 .. Table_Size;
   type Table is array (Index) of Character;

   procedure Move (Values : in out Table; Position : Index)
     with Global => null;
end Move_To_Front;
