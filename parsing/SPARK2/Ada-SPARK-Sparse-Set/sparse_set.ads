pragma Ada_2022;
package Sparse_Set with SPARK_Mode => On is
   Capacity : constant := 32; subtype Value is Natural range 0 .. Capacity - 1; type Set is private;
   procedure Initialize (S : out Set); function Contains (S : Set; V : Value) return Boolean;
   function Length (S : Set) return Natural; procedure Include (S : in out Set; V : Value) with Pre => Length (S) < Capacity;
   procedure Exclude (S : in out Set; V : Value);
private
   subtype Position is Natural range 0 .. Capacity - 1; subtype Count_Range is Natural range 0 .. Capacity;
   type Dense_Array is array (Position) of Value; type Sparse_Array is array (Value) of Position;
   type Set is record Dense : Dense_Array; Sparse : Sparse_Array; Count : Count_Range; end record;
end Sparse_Set;
