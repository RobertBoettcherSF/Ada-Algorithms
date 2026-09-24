pragma Ada_2022;
package Ring_Buffer with SPARK_Mode => On is
   Capacity : constant := 8;
   type Buffer is private;
   procedure Initialize (B : out Buffer);
   function Is_Empty (B : Buffer) return Boolean;
   function Is_Full (B : Buffer) return Boolean;
   function Length (B : Buffer) return Natural;
   procedure Append (B : in out Buffer; Value : Integer) with Pre => Length (B) < Capacity;
   procedure Remove (B : in out Buffer; Value : out Integer) with Pre => Length (B) > 0;
   function Front (B : Buffer) return Integer with Pre => Length (B) > 0;
private
   subtype Index is Positive range 1 .. Capacity;
   subtype Count_Range is Natural range 0 .. Capacity;
   type Data_Array is array (Index) of Integer;
   type Buffer is record Data : Data_Array; Head, Tail : Index; Count : Count_Range; end record;
end Ring_Buffer;
