pragma Ada_2022;
--  Own checks for Delete_And_Earn (see tests/SOURCES.txt). No expected
--  value comes from the program:
--  * small random arrays against a brute force over every set of distinct
--    values with no two adjacent (each value's copies all taken);
--  * Maximum (N) against the closed form (all values of N's parity);
--  * large random arrays: the order of the numbers does not matter
--    (reversed and rotated copies give the same answer), the answer is at
--    least the best single value's points and at most the array's sum, and
--    two halves with a gap of two or more values add up.
with Ada.Text_IO;
with Ada.Assertions;
with Ada.Environment_Variables;
with Interfaces; use Interfaces;
with Delete_And_Earn; use Delete_And_Earn;

procedure Own_Checks with SPARK_Mode => Off is
   Failures : Natural := 0;
   Checked  : Natural := 0;

   procedure Report (Ok : Boolean; Label : String) is
   begin
      Checked := Checked + 1;
      if not Ok then
         Failures := Failures + 1;
         if Failures <= 10 then
            Ada.Text_IO.Put_Line ("  FAIL own check: " & Label);
         end if;
      end if;
   end Report;

   --  Default seed: FNV-1a (32 bit) of the folder name, folded into the
   --  Park-Miller range; printed; AA_SEED=<n> overrides it.
   function Name_Hash return Long_Long_Integer is
      Name : constant String := "Ada-SPARK-Delete-And-Earn";
      H    : Unsigned_32 := 2_166_136_261;
   begin
      for C of Name loop
         H := (H xor Unsigned_32 (Character'Pos (C))) * 16_777_619;
      end loop;
      return Long_Long_Integer (H) mod 2_147_483_646 + 1;
   end Name_Hash;

   function AA_Seed (Default : Long_Long_Integer) return Long_Long_Integer is
      V : constant String := Ada.Environment_Variables.Value ("AA_SEED", "");
      S : constant Long_Long_Integer := (if V = "" then Default else Long_Long_Integer'Value (V));
   begin
      Ada.Text_IO.Put_Line ("AA_SEED =" & S'Image & (if V = "" then " (default: FNV-1a of the folder name)" else " (from AA_SEED)"));
      return S;
   end AA_Seed;

   Seed : Long_Long_Integer := AA_Seed (Name_Hash);
   function Next return Natural is
   begin
      Seed := (Seed * 16_807) mod 2_147_483_647;
      return Natural (Seed);
   end Next;
   function Pick (Lo, Hi : Integer) return Integer is (Lo + Next mod (Hi - Lo + 1));

   --  Brute force: every subset of the values Base .. Base + Span - 1,
   --  skipping subsets with two adjacent values; a value contributes all
   --  its copies.
   function Brute (Nums : Num_Array; Base, Span : Positive) return Natural is
      Copies : array (0 .. Span - 1) of Natural := [others => 0];
      Best   : Natural := 0;
   begin
      for X of Nums loop
         Copies (X - Base) := Copies (X - Base) + 1;
      end loop;
      for Mask in 0 .. 2 ** Span - 1 loop
         declare
               Sum  : Natural := 0;
               Ok   : Boolean := True;
               Prev : Boolean := False;
               Bits : Natural := Mask;
            begin
               for J in 0 .. Span - 1 loop
                  if Bits mod 2 = 1 then
                     Ok := Ok and then not Prev;
                     Prev := True;
                     Sum := Sum + (Base + J) * Copies (J);
                  else
                     Prev := False;
                  end if;
                  Bits := Bits / 2;
               end loop;
               if Ok and then Sum > Best then
                  Best := Sum;
               end if;
            end;
      end loop;
      return Best;
   end Brute;

   function Img (Nums : Num_Array) return String is
     (if Nums'Length = 0 then ""
      else Nums (Nums'First)'Image & Img (Nums (Nums'First + 1 .. Nums'Last)));
begin
   --  1. Maximum (N) for every N: all values with N's parity.
   for N in Number loop
      Report (Maximum (N) = (if N mod 2 = 1 then ((N + 1) / 2) ** 2 else (N / 2) * (N / 2 + 1)),
              "closed form N =" & N'Image);
   end loop;

   --  2. 2,000 small arrays (length 0 .. 12, values in a window of 12
   --  starting anywhere in 1 .. 89) against the brute force.
   for T in 1 .. 2_000 loop
      declare
         Len  : constant Natural := Pick (0, 12);
         Base : constant Positive := Pick (1, 89);
         Nums : Num_Array (1 .. Len);
      begin
         for I in Nums'Range loop
            Nums (I) := Pick (Base, Base + 11);
         end loop;
         Report (Max_Earn (Nums) = Brute (Nums, Base, 12), "brute force on" & Img (Nums));
      end;
   end loop;

   --  3. 30 arrays of length 100 over all of 1 .. 100: order does not
   --  matter, bounds, and splitting at a gap.
   for T in 1 .. 30 loop
      declare
         Nums     : Num_Array (1 .. 100);
         Rev, Rot : Num_Array (1 .. 100);
         Sum, Top : Natural := 0;
         Copies   : array (Number) of Natural := [others => 0];
         Got      : Natural;
         Shift    : constant Natural := Pick (1, 99);
      begin
         for I in Nums'Range loop
            Nums (I) := Pick (1, 100);
            Copies (Nums (I)) := Copies (Nums (I)) + 1;
            Sum := Sum + Nums (I);
         end loop;
         for X in Number loop
            Top := Natural'Max (Top, X * Copies (X));
         end loop;
         for I in Nums'Range loop
            Rev (I) := Nums (101 - I);
            Rot (I) := Nums ((I - 1 + Shift) mod 100 + 1);
         end loop;
         Got := Max_Earn (Nums);
         Report (Max_Earn (Rev) = Got and then Max_Earn (Rot) = Got, "order" & T'Image);
         Report (Top <= Got and then Got <= Sum, "bounds" & T'Image);
         --  Values below Cut and above Cut + 1 never interact.
         declare
            Cut       : constant Positive := Pick (2, 98);
            Lo_N, Hi_N : Natural := 0;
         begin
            for X of Nums loop
               if X < Cut then
                  Lo_N := Lo_N + 1;
               elsif X > Cut + 1 then
                  Hi_N := Hi_N + 1;
               end if;
            end loop;
            declare
               Lo : Num_Array (1 .. Lo_N);
               Hi : Num_Array (1 .. Hi_N);
               All_N : Num_Array (1 .. Lo_N + Hi_N);
               L, H : Natural := 0;
            begin
               for X of Nums loop
                  if X < Cut then
                     L := L + 1;
                     Lo (L) := X;
                     All_N (L) := X;
                  elsif X > Cut + 1 then
                     H := H + 1;
                     Hi (H) := X;
                     All_N (Lo_N + H) := X;
                  end if;
               end loop;
               Report (Max_Earn (All_N) = Max_Earn (Lo) + Max_Earn (Hi), "gap split" & T'Image);
            end;
         end;
      end;
   end loop;

   --  4. Any origin (H140): the same numbers at Nums'First = 2, 7, 50 and
   --  ending at Index'Last must give the origin-1 answer and the brute
   --  force; 300 random arrays (seed 20261009), plus empty arrays at the
   --  top of Index.
   Seed := 20_261_009;
   declare
      function Earn_At (Nums : Num_Array; First : Index) return Integer is
         Moved : constant Num_Array (First .. First + Nums'Length - 1) := Nums;
      begin
         return Max_Earn (Moved);
      exception
         when Constraint_Error | Ada.Assertions.Assertion_Error =>
            return -1;
      end Earn_At;
   begin
      for T in 1 .. 300 loop
         declare
            Len  : constant Natural := Pick (0, 12);
            Base : constant Positive := Pick (1, 89);
            Nums : Num_Array (1 .. Len);
            Want : Natural;
            type Origins is array (1 .. 4) of Index;
            Os   : constant Origins := [2, 7, 50, Index'Last + 1 - Natural'Max (Len, 1)];
         begin
            for I in Nums'Range loop
               Nums (I) := Pick (Base, Base + 11);
            end loop;
            Want := Brute (Nums, Base, 12);
            Report (Max_Earn (Nums) = Want, "origin 1 on" & Img (Nums));
            for O of Os loop
               Report (Earn_At (Nums, O) = Want, "origin" & O'Image & " on" & Img (Nums));
            end loop;
         end;
      end loop;
      declare
         Empty : constant Num_Array (Index'Last .. Index'Last - 1) := [];
         Full  : constant Num_Array (1 .. 100) := [for I in 1 .. 100 => I];
      begin
         Report (Max_Earn (Empty) = 0, "empty at 'First = 100");
         Report (Earn_At (Full, 1) = Maximum (100), "1 .. 100 at origin 1");
      end;
   end;

   Ada.Text_IO.Put_Line ("own checks:" & Checked'Image & " checks," & Failures'Image & " failures");
   if Failures > 0 then
      raise Program_Error with "own checks failed";
   end if;
end Own_Checks;
