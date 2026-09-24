pragma SPARK_Mode (On);

package Reverse_String_II is
   subtype Index is Positive range 1 .. 32;
   subtype Length_Type is Natural range 0 .. 32;
   type Items is array (Index) of Character;

   procedure Reverse_First (Data : in out Items; Length : Length_Type)
     with Global => null;
end Reverse_String_II;
