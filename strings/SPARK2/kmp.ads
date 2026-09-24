pragma Ada_2022;
package KMP
  with SPARK_Mode => On
is
   Max_Len : constant := 16;
   type Char_Array is array (Positive range <>) of Character;
   type Prefix_Table is array (Positive range <>) of Natural;

   procedure Build_Prefix (Pat : Char_Array; Pi : out Prefix_Table)
     with
       Global => null,
       Pre    => Pat'First = 1 and then Pat'Last in 1 .. Max_Len
                 and then Pi'First = 1 and then Pi'Last = Pat'Last;
end KMP;
