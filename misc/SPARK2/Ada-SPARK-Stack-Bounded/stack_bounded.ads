pragma Ada_2022;
package Stack_Bounded with SPARK_Mode => On is
   Capacity : constant := 8; type Stack is private;
   procedure Initialize (S : out Stack); function Is_Empty (S : Stack) return Boolean;
   function Is_Full (S : Stack) return Boolean; function Depth (S : Stack) return Natural;
   procedure Push (S : in out Stack; Value : Integer) with Pre => Depth (S) < Capacity;
   procedure Pop (S : in out Stack; Value : out Integer) with Pre => Depth (S) > 0;
   function Top (S : Stack) return Integer with Pre => Depth (S) > 0;
private
   subtype Index is Positive range 1 .. Capacity; subtype Count_Range is Natural range 0 .. Capacity;
   type Data_Array is array (Index) of Integer;
   type Stack is record Data : Data_Array; Count : Count_Range; end record;
end Stack_Bounded;
