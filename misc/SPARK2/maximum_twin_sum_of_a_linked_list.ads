pragma SPARK_Mode (On);

package Maximum_Twin_Sum_Of_A_Linked_List is
   subtype Count is Natural range 0 .. 16;
   subtype Position is Count range 1 .. 16;
   subtype Value is Integer range 0 .. 100;
   subtype Twin_Sum is Integer range 0 .. 200;
   type List is private;

   function Empty return List;
   procedure Append (L : in out List; V : Value);
   function Length (L : List) return Count;
   function Maximum_Twin_Sum (L : List) return Twin_Sum
     with Pre => Length (L) > 0 and then Length (L) mod 2 = 0;
private
   type Value_Array is array (Position) of Value;
   type List is record
      Data : Value_Array := (others => 0);
      Size : Count := 0;
   end record;
end Maximum_Twin_Sum_Of_A_Linked_List;
