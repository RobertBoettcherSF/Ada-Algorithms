pragma Ada_2022;
package KMP
  with SPARK_Mode => On
is
   Max_Len : constant := 16;
   subtype Pat_Index is Positive range 1 .. Max_Len;
   type Char_Array is array (Pat_Index range <>) of Character;
   type Prefix_Table is array (Pat_Index range <>) of Natural;

   --  Pi slot k (k = 1 .. Pat'Length) is Pi (Pi'First + k - 1) and holds
   --  the border length of Pat's first k characters — a length (offset),
   --  so Pat and Pi may each sit at any origin.
   procedure Build_Prefix (Pat : Char_Array; Pi : out Prefix_Table)
     with
       Global => null,
       Pre    => Pat'Length >= 1
                 and then Pi'Length = Pat'Length,
       Post   => (for all J in Pi'Range => Pi (J) < J - Pi'First + 1);
end KMP;
