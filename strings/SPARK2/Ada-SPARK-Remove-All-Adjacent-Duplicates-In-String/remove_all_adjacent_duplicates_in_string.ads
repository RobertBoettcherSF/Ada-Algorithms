pragma Ada_2022;
package Remove_All_Adjacent_Duplicates_In_String with SPARK_Mode => On is
   Capacity : constant := 16;
   subtype Length is Natural range 0 .. Capacity;
   subtype Slot is Positive range 1 .. Capacity;
   type Buffer is array (Slot) of Character;
   procedure Reduce (Input : Buffer; N : Length; Output : out Buffer; M : out Length) with Global => null;
end Remove_All_Adjacent_Duplicates_In_String;
