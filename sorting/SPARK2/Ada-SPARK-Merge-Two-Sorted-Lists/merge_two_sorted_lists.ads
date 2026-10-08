pragma Ada_2022;
pragma SPARK_Mode (On);

package Merge_Two_Sorted_Lists is
   pragma Assertion_Policy (Pre => Check);
   subtype Count is Natural range 0 .. 16;
   subtype Position is Count range 1 .. 16;
   subtype Cursor is Natural range 1 .. 17;
   subtype Value is Integer range -100 .. 100;

   type List is private;
   function Empty return List
     with Post => Length (Empty'Result) = 0;
   procedure Append (L : in out List; V : Value)
     with Pre  => Length (L) < Count'Last,   --  no silent drop when full
          Post => Length (L) = Length (L'Old) + 1;
   function Length (L : List) return Count;
   function Element (L : List; P : Position) return Value;
   --  The merged list must fit: no silent truncation.
   function Merge (A, B : List) return List
     with Pre  => Length (A) + Length (B) <= Count'Last,
          Post => Length (Merge'Result) = Length (A) + Length (B);
private
   type Value_Array is array (Cursor) of Value;
   type List is record
      Data : Value_Array := [others => 0];
      Size : Count := 0;
   end record;
   function Length (L : List) return Count is (L.Size);
end Merge_Two_Sorted_Lists;
