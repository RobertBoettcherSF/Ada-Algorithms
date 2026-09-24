pragma Ada_2022;
package Design_Front_Middle_Back_Queue with SPARK_Mode => On is
   Capacity : constant := 16; subtype Count_Type is Natural range 0 .. Capacity; subtype Index_Type is Positive range 1 .. Capacity;
   type Queue is private;
   procedure Initialize (Q : out Queue); procedure Enqueue (Q : in out Queue; Value : Integer); procedure Dequeue (Q : in out Queue; Value : out Integer);
   function Is_Empty (Q : Queue) return Boolean; function Length (Q : Queue) return Count_Type;
private
   type Items is array (Index_Type) of Integer; type Queue is record Data : Items; Count : Count_Type; end record;
end Design_Front_Middle_Back_Queue;
