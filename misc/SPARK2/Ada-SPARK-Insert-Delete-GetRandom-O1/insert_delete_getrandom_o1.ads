pragma Ada_2022;
package Insert_Delete_GetRandom_O1 with SPARK_Mode => On is
   Capacity : constant := 16; subtype Count_Type is Natural range 0 .. Capacity; type Set is private;
   procedure Initialize (S : out Set); procedure Insert (S : in out Set; Value : Integer); procedure Delete_Last (S : in out Set; Value : out Integer);
   function Get_At (S : Set; Position : Positive) return Integer with Pre => Position <= Capacity; function Length (S : Set) return Count_Type;
private
   subtype Index_Type is Positive range 1 .. Capacity; type Items is array (Index_Type) of Integer; type Set is record Data : Items; Count : Count_Type; end record;
end Insert_Delete_GetRandom_O1;
