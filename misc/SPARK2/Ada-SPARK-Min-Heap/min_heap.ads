pragma Ada_2022;
package Min_Heap with SPARK_Mode => On is
   Capacity : constant := 32;
   subtype Size is Natural range 0 .. Capacity;
   type Heap is private;
   procedure Initialize (H : out Heap);
   procedure Push (H : in out Heap; Value : Integer; Added : out Boolean);
   procedure Pop (H : in out Heap; Value : out Integer; Removed : out Boolean);
   function Empty (H : Heap) return Boolean;
private
   subtype Position is Positive range 1 .. Capacity;
   type Data_Array is array (Position) of Integer;
   type Heap is record Data : Data_Array; Length : Size; end record;
end Min_Heap;
