pragma Ada_2022;
package Randomized_Set with SPARK_Mode => On is
   Capacity : constant := 16; subtype Count_Type is Natural range 0 .. Capacity; type Set is private;
   procedure Initialize (S : out Set); procedure Insert (S : in out Set; Value : Integer); procedure Remove_Last (S : in out Set; Value : out Integer);
   function Contains (S : Set; Value : Integer) return Boolean; function Length (S : Set) return Count_Type;
private
   subtype Index_Type is Positive range 1 .. Capacity; type Items is array (Index_Type) of Integer; type Set is record Data : Items; Count : Count_Type; end record;
end Randomized_Set;
