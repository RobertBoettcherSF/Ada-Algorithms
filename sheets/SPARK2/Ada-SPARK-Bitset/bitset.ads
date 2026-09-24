pragma Ada_2022;
package Bitset with SPARK_Mode => On is
   Capacity : constant := 32; subtype Bit_Index is Natural range 0 .. Capacity - 1; type Set is private;
   procedure Initialize (S : out Set); procedure Include (S : in out Set; Bit : Bit_Index);
   procedure Exclude (S : in out Set; Bit : Bit_Index); function Contains (S : Set; Bit : Bit_Index) return Boolean;
   function Cardinality (S : Set) return Natural;
private
   type Bits is array (Bit_Index) of Boolean; type Set is record Data : Bits; end record;
end Bitset;
