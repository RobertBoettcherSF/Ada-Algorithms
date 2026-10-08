pragma SPARK_Mode (On);

package Convert_Binary_Number_In_A_Linked_List_To_Integer is
   subtype Count is Natural range 0 .. 16;
   subtype Position is Count range 1 .. 16;
   subtype Bit is Integer range 0 .. 1;
   subtype Result is Natural range 0 .. 65_535;
   type List is private;

   function Empty return List;
   procedure Append (L : in out List; V : Bit);
   function Length (L : List) return Count;
   function To_Integer (L : List) return Result;
private
   type Bit_Array is array (Position) of Bit;
   type List is record
      Data : Bit_Array := (others => 0);
      Size : Count := 0;
   end record;
end Convert_Binary_Number_In_A_Linked_List_To_Integer;
