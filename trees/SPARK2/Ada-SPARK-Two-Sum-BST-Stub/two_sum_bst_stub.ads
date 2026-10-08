pragma Ada_2022;

package Two_Sum_BST_Stub with SPARK_Mode => On is
   Length : constant := 8;
   subtype Index is Positive range 1 .. Length;
   subtype Value is Integer range -100 .. 100;
   type Input_Array is array (Index) of Value;
   function Has_Two_Sum (Input : Input_Array; Target : Integer) return Boolean with Global => null;
end Two_Sum_BST_Stub;
