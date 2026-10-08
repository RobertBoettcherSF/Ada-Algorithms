--  Own tests for Encode_And_Decode_Strings_Lite (see tests/SOURCES.txt).
--  Decode (Encode (X)) = X for all bytes, and Encode is X xor K for one fixed K /= 0.
pragma Ada_2022;
with Ada.Text_IO;
with Interfaces;
with Encode_And_Decode_Strings_Lite; use Encode_And_Decode_Strings_Lite;

procedure Own_Checks is
   Failures : Natural := 0;
   Cases    : Natural := 0;

   --  Park-Miller "minimal standard" generator (x := 16807 x mod (2**31 - 1)).
   Seed : Long_Long_Integer := 20_261_008;
   function Next (Lo, Hi : Integer) return Integer is
   begin
      Seed := (Seed * 16_807) mod 2_147_483_647;
      return Integer (Long_Long_Integer (Lo)
                      + Seed mod (Long_Long_Integer (Hi) - Long_Long_Integer (Lo) + 1));
   end Next;
   pragma Warnings (Off, Next);

   procedure Report (Ok : Boolean; Label : String) is
   begin
      Cases := Cases + 1;
      if not Ok then
         Failures := Failures + 1;
         if Failures <= 5 then
            Ada.Text_IO.Put_Line ("  FAIL own check: " & Label);
         end if;
      end if;
   end Report;

   --  Own reference: straight insertion sort.
   type IArr is array (Positive range <>) of Integer;
   procedure Ins_Sort (A : in out IArr) is
      T : Integer;
      J : Positive;
   begin
      for I in A'First + 1 .. A'Last loop
         T := A (I);
         J := I;
         while J > A'First and then A (J - 1) > T loop
            A (J) := A (J - 1);
            J := J - 1;
         end loop;
         A (J) := T;
      end loop;
   end Ins_Sort;
   pragma Warnings (Off, Ins_Sort);

   use type Interfaces.Unsigned_8;
   Key : constant Byte := Encode (0);
begin
   Report (Key /= 0, "key is not zero (Encode is not the identity)");
   for X in Byte loop
      Report (Decode (Encode (X)) = X, "round trip" & X'Image);
      Report (Encode (Decode (X)) = X, "inverse round trip" & X'Image);
      Report ((Encode (X) xor X) = Key, "constant XOR key" & X'Image);
   end loop;
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (round trip + XOR-key property, every byte)");
end Own_Checks;
