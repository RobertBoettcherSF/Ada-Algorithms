with Ada.Text_IO; use Ada.Text_IO;
with Interfaces; use Interfaces;
with Redundancy_Checks; use Redundancy_Checks;

procedure Main is
   -- Representation of ASCII String "Hello"
   Data : Byte_Array := (16#48#, 16#65#, 16#6C#, 16#6C#, 16#6F#); 
   CRC  : Unsigned_32;
   Adler: Unsigned_32;
begin
   Put_Line ("=== Redundancy Check Demonstration ===");
   
   CRC := Calculate_CRC32 (Data);
   Put_Line ("1. CRC-32 of 'Hello'   : 0x" & CRC'Image);
   
   Adler := Calculate_Adler32 (Data);
   Put_Line ("2. Adler-32 of 'Hello' : 0x" & Adler'Image);
   
   Put_Line ("3. LRC of 'Hello'      : 0x" & Calculate_LRC(Data)'Image);
end Main;
