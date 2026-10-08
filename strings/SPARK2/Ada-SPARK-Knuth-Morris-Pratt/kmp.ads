pragma Ada_2022;
package KMP
  with SPARK_Mode => On
is
   Max_Len : constant := 16;
   subtype Pat_Index is Positive range 1 .. Max_Len;
   type Char_Array is array (Pat_Index range <>) of Character;
   type Prefix_Table is array (Pat_Index range <>) of Natural;

   procedure Build_Prefix (Pat : Char_Array; Pi : out Prefix_Table)
     with
       Global => null,
       Pre    => Pat'First = 1 and then Pat'Last in 1 .. Max_Len
                 and then Pi'First = 1 and then Pi'Last = Pat'Last;
end KMP;
