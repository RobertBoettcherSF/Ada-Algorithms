pragma SPARK_Mode (On);
package Design_An_Ordered_Stream is
   Capacity : constant := 3;
   subtype Position is Positive range 1 .. Capacity;
   subtype Item is Integer range -100 .. 100;
   type Stream is private;
   function Empty return Stream with Global => null;
   procedure Put (S : in out Stream; P : Position; V : Item) with Global => null;
   function Ready (S : Stream) return Boolean with Global => null;
   function Read (S : Stream) return Item with Global => null, Pre => Ready (S);
   procedure Advance (S : in out Stream) with Global => null, Pre => Ready (S);
private
   subtype Slot is Positive range 1 .. Capacity + 1;
   type Item_Array is array (Slot) of Item;
   type Mark_Array is array (Slot) of Boolean;
   type Stream is record
      Values : Item_Array := (others => 0);
      Present : Mark_Array := (others => False);
      Cursor : Slot := 1;
   end record;
end Design_An_Ordered_Stream;
