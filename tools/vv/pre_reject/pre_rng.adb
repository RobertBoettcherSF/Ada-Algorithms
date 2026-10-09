with Interfaces; use Interfaces;
with Ada.Text_IO;
package body Pre_Rng is
   State : Unsigned_64 := Unsigned_64 (Seed);
   procedure Reset is
   begin
      State := Unsigned_64 (Seed);
   end Reset;
   function Draw (Lo, Hi : Long_Long_Integer) return Long_Long_Integer is
      Span : constant Unsigned_64 := Unsigned_64 (Hi - Lo) + 1;
      Z : Unsigned_64;
   begin
      --  SplitMix64 (all output bits well mixed, unlike plain LCG low bits).
      State := State + 16#9E37_79B9_7F4A_7C15#;
      Z := State;
      Z := (Z xor Shift_Right (Z, 30)) * 16#BF58_476D_1CE4_E5B9#;
      Z := (Z xor Shift_Right (Z, 27)) * 16#94D0_49BB_1331_11EB#;
      Z := Z xor Shift_Right (Z, 31);
      return Lo + Long_Long_Integer (Z mod Span);
   end Draw;
   function Draw (Lo, Hi : Integer) return Integer is
     (Integer (Long_Long_Integer'(Draw (Long_Long_Integer (Lo), Long_Long_Integer (Hi)))));
   procedure Report (Folder, Subprogram, Generator : String; Rejected : Natural) is
   begin
      Ada.Text_IO.Put_Line (Folder & "|" & Subprogram & "|" & Generator & "|"
                            & Integer'Image (Sample) & "|" & Natural'Image (Rejected));
   end Report;
end Pre_Rng;
