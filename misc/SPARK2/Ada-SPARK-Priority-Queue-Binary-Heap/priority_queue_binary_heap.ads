pragma Ada_2022;
package Priority_Queue_Binary_Heap with SPARK_Mode => On is
   Capacity : constant := 16; type Queue is private; procedure Initialize (Q : out Queue);
   function Size (Q : Queue) return Natural; function Is_Empty (Q : Queue) return Boolean;
   procedure Insert (Q : in out Queue; Priority : Integer) with Pre => Size (Q) < Capacity;
   procedure Remove_Min (Q : in out Queue; Priority : out Integer) with Pre => Size (Q) > 0;
   function Minimum (Q : Queue) return Integer with Pre => Size (Q) > 0;
private
   subtype Index is Positive range 1 .. Capacity; subtype Count_Range is Natural range 0 .. Capacity;
   type Data_Array is array (Index) of Integer; type Queue is record Data : Data_Array; Count : Count_Range; end record;
end Priority_Queue_Binary_Heap;
