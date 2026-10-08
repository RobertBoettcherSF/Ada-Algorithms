pragma SPARK_Mode (On);

package Merge_In_Between_Linked_Lists is
   subtype Count is Natural range 0 .. 16;
   subtype Position is Count range 1 .. 16;
   subtype Value is Integer range -100 .. 100;
   type List is private;

   function Empty return List;
   procedure Append (L : in out List; V : Value);
   function Length (L : List) return Count;
   function Element (L : List; P : Position) return Value
     with Pre => P <= Length (L);
   procedure Merge_In_Between (L : in out List; First, Last : Position; V : Value)
     with Pre => First <= Last and then Last <= Length (L);
private
   type Value_Array is array (Position) of Value;
   type List is record
      Data : Value_Array := (others => 0);
      Size : Count := 0;
   end record;
end Merge_In_Between_Linked_Lists;
