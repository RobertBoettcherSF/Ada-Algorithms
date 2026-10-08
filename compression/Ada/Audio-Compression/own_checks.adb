--  Own checks (see tests/SOURCES.txt). Assume Audio_Compression is wrong or
--  does nothing, and show otherwise with properties and an independent
--  evaluation: DPCM must round-trip every buffer exactly (the spec calls it
--  the foundation of lossless codecs), including full-scale jumps; mu-law and
--  A-law codes are checked over all 65,536 samples and all 256 codes for
--  monotonicity, odd symmetry and agreement with the companding curves
--  evaluated in Long_Float (rounded to nearest, as Ada's conversion does).
pragma Ada_2022;
with Ada.Text_IO;
with Ada.Numerics.Long_Elementary_Functions; use Ada.Numerics.Long_Elementary_Functions;
with Audio_Compression; use Audio_Compression;

procedure Own_Checks is
   Seed : Long_Long_Integer := 20261008;
   Checked : Natural := 0;

   function Rand (Lo, Hi : Integer) return Integer is   --  Park-Miller
   begin
      Seed := (Seed * 16807) mod 2147483647;
      return Lo + Integer (Seed mod Long_Long_Integer (Hi - Lo + 1));
   end Rand;

   procedure Expect (Cond : Boolean; What : String) is
   begin
      if not Cond then
         Ada.Text_IO.Put_Line ("FAIL own check: " & What);
         raise Program_Error;
      end if;
      Checked := Checked + 1;
   end Expect;

   Mu : constant Long_Float := 255.0;
   A  : constant Long_Float := 87.6;

   function F_Mu (X : Long_Float) return Long_Float is
     ((if X < 0.0 then -1.0 else 1.0) * Log (1.0 + Mu * abs X) / Log (1.0 + Mu));
   function F_A (X : Long_Float) return Long_Float is
     ((if X < 0.0 then -1.0 else 1.0)
      * (if abs X < 1.0 / A then A * abs X / (1.0 + Log (A)) else (1.0 + Log (A * abs X)) / (1.0 + Log (A))));

   --  code expected from a curve value V in [-1, 1]: nearest integer of 128 V, at most 127;
   --  True also when 128 V is within 1e-3 of a rounding boundary (either side is fine)
   function Code_OK (Got : PCM_8; V : Long_Float) return Boolean is
      S : constant Long_Float := 128.0 * V;
      R : constant Long_Float := Long_Float'Rounding (S);
   begin
      if Integer (Got) = Integer'Min (127, Integer (R)) then
         return True;
      end if;
      return abs (abs (S - Long_Float'Floor (S)) - 0.5) < 1.0E-3
        and then abs (Long_Float (Got) - S) < 0.501;
   end Code_OK;
begin
   --  DPCM: exact round trip, also across full-scale jumps
   for Round in 1 .. 2_000 loop
      declare
         Len : constant Natural := Rand (0, 12);
         X   : Buffer_16 (5 .. 4 + Len);
      begin
         for I in X'Range loop
            X (I) := PCM_16 (case Rand (0, 3) is
                               when 0 => -32768, when 1 => 32767,
                               when others => Rand (-32768, 32767));
         end loop;
         declare
            E : constant Buffer_16 := Encode_DPCM (X);
            D : constant Buffer_16 := Decode_DPCM (E);
         begin
            Expect (E'First = X'First and then E'Length = X'Length and then D = X,
                    "DPCM round trip is not exact (length" & Len'Image & ")");
            for I in X'Range loop
               declare
                  Prev : constant Integer := (if I = X'First then 0 else Integer (X (I - 1)));
                  Diff : constant Integer := Integer (X (I)) - Prev;
               begin
                  if Diff in -32768 .. 32767 then
                     Expect (Integer (E (I)) = Diff, "Encode_DPCM difference at" & I'Image);
                  end if;
               end;
            end loop;
         end;
      end;
   end loop;
   Expect (Decode_DPCM (Encode_DPCM ([32767, -32768, 32767])) = [32767, -32768, 32767],
           "DPCM round trip of [32767, -32768, 32767]");

   --  companding curves over every sample
   declare
      Prev_Mu, Prev_A : PCM_8 := -128;
   begin
      for S in PCM_16 loop
         declare
            X  : constant Long_Float := Long_Float (S) / 32768.0;
            EM : constant PCM_8 := Encode_Mu_Law (S);
            EA : constant PCM_8 := Encode_A_Law (S);
         begin
            Expect (EM >= Prev_Mu and then EA >= Prev_A, "encoders not monotonic at" & S'Image);
            Expect (Code_OK (EM, F_Mu (X)), "Encode_Mu_Law" & S'Image & " gave" & EM'Image);
            Expect (Code_OK (EA, F_A (X)), "Encode_A_Law" & S'Image & " gave" & EA'Image);
            --  odd symmetry away from the asymmetric 8-bit ends (+127 / -128)
            if S > PCM_16'First and then abs Integer (EM) < 127 then
               Expect (Integer (Encode_Mu_Law (-S)) = -Integer (EM), "Encode_Mu_Law not odd at" & S'Image);
            end if;
            if S > PCM_16'First and then abs Integer (EA) < 127 then
               Expect (Integer (Encode_A_Law (-S)) = -Integer (EA), "Encode_A_Law not odd at" & S'Image);
            end if;
            Prev_Mu := EM; Prev_A := EA;
         end;
      end loop;
   end;
   --  decoders over every code: monotonic, odd, and the curve maps the result back near the code
   declare
      Prev_Mu, Prev_A : PCM_16 := PCM_16'First;
   begin
      for K in PCM_8 loop
         declare
            DM : constant PCM_16 := Decode_Mu_Law (K);
            DA : constant PCM_16 := Decode_A_Law (K);
            Y  : constant Long_Float := Long_Float (K) / 128.0;
         begin
            Expect (DM >= Prev_Mu and then DA >= Prev_A, "decoders not monotonic at" & K'Image);
            if K > PCM_8'First then
               Expect (Integer (Decode_Mu_Law (-K)) = -Integer (DM) and then Integer (Decode_A_Law (-K)) = -Integer (DA),
                       "decoders not odd at" & K'Image);
            end if;
            Expect (abs (F_Mu (Long_Float (DM) / 32768.0) - Y) < 2.0E-3, "Decode_Mu_Law" & K'Image & " gave" & DM'Image);
            Expect (abs (F_A (Long_Float (DA) / 32768.0) - Y) < 2.0E-3, "Decode_A_Law" & K'Image & " gave" & DA'Image);
            Prev_Mu := DM; Prev_A := DA;
         end;
      end loop;
   end;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Checked'Image
                         & " checks (exact DPCM round trips; companding curves in Long_Float over all samples and codes)");
end Own_Checks;
