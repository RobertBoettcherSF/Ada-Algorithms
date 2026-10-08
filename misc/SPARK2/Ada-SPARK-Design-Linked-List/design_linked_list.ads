pragma SPARK_Mode (On);

package Design_Linked_List is
   Capacity : constant := 8;
   subtype Count is Natural range 0 .. Capacity;
   subtype Value is Integer range -100 .. 100;
   type List is private;

   function Empty return List with Global => null;
   function Length (L : List) return Count with Global => null;
   procedure Push_Front (L : in out List; V : Value)
     with Global => null, Pre => Length (L) < Capacity;
   procedure Append (L : in out List; V : Value)
     with Global => null, Pre => Length (L) < Capacity;
   function Contains (L : List; V : Value) return Boolean with Global => null;
   function Element_At (L : List; Position : Positive) return Value
     with Global => null, Pre => Position <= Length (L);
private
   subtype Index is Positive range 1 .. Capacity;
   type Value_Array is array (Index) of Value;
   type List is record
      Values : Value_Array := (others => 0);
      Size : Count := 0;
   end record;
end Design_Linked_List;
