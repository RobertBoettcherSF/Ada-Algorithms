pragma Ada_2022;
package Deque_Bounded with SPARK_Mode => On is
   Capacity : constant := 8; type Deque is private;
   procedure Initialize (D : out Deque); function Length (D : Deque) return Natural;
   function Is_Empty (D : Deque) return Boolean; function Is_Full (D : Deque) return Boolean;
   procedure Push_Front (D : in out Deque; Value : Integer) with Pre => Length (D) < Capacity;
   procedure Push_Back (D : in out Deque; Value : Integer) with Pre => Length (D) < Capacity;
   procedure Pop_Front (D : in out Deque; Value : out Integer) with Pre => Length (D) > 0;
   procedure Pop_Back (D : in out Deque; Value : out Integer) with Pre => Length (D) > 0;
private
   subtype Index is Positive range 1 .. Capacity; subtype Count_Range is Natural range 0 .. Capacity;
   type Data_Array is array (Index) of Integer;
   type Deque is record Data : Data_Array; Head, Tail : Index; Count : Count_Range; end record;
end Deque_Bounded;
