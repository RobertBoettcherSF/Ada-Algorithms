pragma SPARK_Mode (On);

package Intersection_Of_Two_Linked_Lists is
   subtype Count is Natural range 0 .. 16;
   subtype Position is Count range 1 .. 16;
   subtype Value is Integer range -100 .. 100;
   type List is private;

   function Empty return List;
   procedure Append (L : in out List; V : Value);
   function Length (L : List) return Count;
   function Common_Suffix_Length (Left, Right : List) return Count;
private
   type Value_Array is array (Position) of Value;
   type List is record
      Data : Value_Array := (others => 0);
      Size : Count := 0;
   end record;
end Intersection_Of_Two_Linked_Lists;
