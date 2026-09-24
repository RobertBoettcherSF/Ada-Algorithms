pragma SPARK_Mode (On);
package Design_Ordered_Stream is
   Capacity : constant := 4;
   subtype Position is Positive range 1 .. Capacity;
   subtype Item is Integer range -100 .. 100;
   type Stream is private;
   function Empty return Stream with Global => null;
   procedure Insert (S : in out Stream; P : Position; V : Item) with Global => null;
   function Has_Next (S : Stream) return Boolean with Global => null;
   function Next (S : Stream) return Item with Global => null,
     Pre => Has_Next (S);
   procedure Consume (S : in out Stream) with Global => null,
     Pre => Has_Next (S);
private
   subtype Slot is Positive range 1 .. Capacity + 1;
   type Item_Array is array (Slot) of Item;
   type Mark_Array is array (Slot) of Boolean;
   type Stream is record
      Values : Item_Array := (others => 0);
      Present : Mark_Array := (others => False);
      Cursor : Slot := 1;
   end record;
end Design_Ordered_Stream;
