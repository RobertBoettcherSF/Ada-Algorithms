--  Own checks (see tests/SOURCES.txt). Assume Poly1305 is wrong or does
--  nothing; compare it with a reference that uses a different method: plain
--  schoolbook arithmetic on base-256 digit arrays (no 26-bit limbs, no
--  precomputed 5 * r), reducing modulo 2**130 - 5 by folding the part above
--  bit 130 back in times 5 and subtracting p at the end. Seeded random keys
--  and messages of every length 0 .. 80, extreme keys and messages (all
--  0xFF), and every split of a message into two Update calls.
pragma Ada_2022;
with Ada.Environment_Variables;
with Ada.Text_IO;
with Poly1305; use Poly1305;

procedure Own_Checks is
   subtype Digit_Index is Natural range 0 .. 39;
   type Big is array (Digit_Index) of Natural;   --  base 256, little endian
   Zero : constant Big := [others => 0];
   Checked : Natural := 0;
   --  Random test inputs: fixed default seed, printed at start; AA_SEED=<n> overrides it.
   function AA_Seed (Default : Long_Long_Integer) return Long_Long_Integer is
      V : constant String := Ada.Environment_Variables.Value ("AA_SEED", "");
      S : Long_Long_Integer := Default;
   begin
      if V /= "" then
         S := Long_Long_Integer (1 + abs (Long_Long_Integer'Value (V)) mod 2_147_483_646);
      end if;
      Ada.Text_IO.Put_Line ("AA_SEED =" & Long_Long_Integer'Image (S) & (if V = "" then " (default)" else " (from AA_SEED)"));
      return S;
   end AA_Seed;
   Seed : Long_Long_Integer := AA_Seed (20261008);

   function Rand_Byte return Byte is   --  Park-Miller minimal standard
   begin
      Seed := (Seed * 16807) mod 2147483647;
      return Byte (Seed mod 256);
   end Rand_Byte;

   procedure Normalize (X : in out Big) is
      C : Natural := 0;
   begin
      for I in Digit_Index loop
         X (I) := X (I) + C;
         C := X (I) / 256;
         X (I) := X (I) mod 256;
      end loop;
      pragma Assert (C = 0);
   end Normalize;

   function Add (A, B : Big) return Big is
      R : Big;
   begin
      for I in Digit_Index loop R (I) := A (I) + B (I); end loop;
      Normalize (R);
      return R;
   end Add;

   function Mul (A, B : Big) return Big is
      R : Big := Zero;
   begin
      for I in 0 .. 19 loop
         for J in 0 .. 19 loop
            R (I + J) := R (I + J) + A (I) * B (J);
         end loop;
         Normalize (R);
      end loop;
      return R;
   end Mul;

   --  X >= 2**130 - 5 ?  (p = 2**130 - 5: bytes 0 = 16#FB#, 1 .. 15 = 16#FF#, 16 = 3)
   function Ge_P (X : Big) return Boolean is
      P : Big := Zero;
   begin
      P (0) := 16#FB#;
      for I in 1 .. 15 loop P (I) := 16#FF#; end loop;
      P (16) := 3;
      for I in reverse Digit_Index loop
         if X (I) /= P (I) then
            return X (I) > P (I);
         end if;
      end loop;
      return True;
   end Ge_P;

   function Mod_P (X0 : Big) return Big is
      X : Big := X0;
   begin
      loop
         declare
            Hi, Lo : Big := Zero;
            Five   : Big := Zero;
            Any    : Boolean := False;
         begin
            --  Hi = X / 2**130, Lo = X mod 2**130
            for I in 0 .. 15 loop Lo (I) := X (I); end loop;
            Lo (16) := X (16) mod 4;
            for I in 0 .. 22 loop
               Hi (I) := X (I + 16) / 4 + (X (I + 17) mod 4) * 64;
               Any := Any or else Hi (I) /= 0;
            end loop;
            exit when not Any;
            Five (0) := 5;
            X := Add (Lo, Mul (Hi, Five));
         end;
      end loop;
      while Ge_P (X) loop   --  X - p = X + 5 - 2**130
         X (0) := X (0) + 5;
         Normalize (X);
         X (16) := X (16) - 4;
      end loop;
      return X;
   end Mod_P;

   function Ref_MAC (Msg : Byte_Array; Key : Key_Type) return MAC_Type is
      R, S, Acc : Big := Zero;
      Pos : Natural := Msg'First;
      M   : MAC_Type;
   begin
      for I in 0 .. 15 loop
         R (I) := Natural (Key (Key'First + I));
         S (I) := Natural (Key (Key'First + 16 + I));
      end loop;
      --  clamp r: top four bits of bytes 3, 7, 11, 15 and low two bits of 4, 8, 12 cleared
      for I in 0 .. 3 loop
         R (4 * I + 3) := R (4 * I + 3) mod 16;
         if I > 0 then
            R (4 * I) := R (4 * I) - R (4 * I) mod 4;
         end if;
      end loop;
      while Pos <= Msg'Last loop
         declare
            Len : constant Natural := Natural'Min (16, Msg'Last - Pos + 1);
            N   : Big := Zero;
         begin
            for I in 0 .. Len - 1 loop N (I) := Natural (Msg (Pos + I)); end loop;
            N (Len) := 1;
            Acc := Mod_P (Mul (Add (Acc, N), R));
            Pos := Pos + Len;
         end;
      end loop;
      Acc := Add (Acc, S);
      for I in 0 .. 15 loop M (I) := Byte (Acc (I)); end loop;   --  mod 2**128
      return M;
   end Ref_MAC;

   procedure Check (Msg : Byte_Array; Key : Key_Type; What : String) is
      Want : constant MAC_Type := Ref_MAC (Msg, Key);
      Ctx  : Context;
      Got  : MAC_Type;
   begin
      if Generate_MAC (Msg, Key) /= Want then
         Ada.Text_IO.Put_Line ("FAIL own check: Generate_MAC differs from the base-256 reference, "
                               & What & ", length" & Msg'Length'Image);
         raise Program_Error;
      end if;
      --  every split into two Update calls (shifted index range on the second part)
      for Cut in 0 .. Msg'Length loop
         Init (Ctx, Key);
         Update (Ctx, Msg (Msg'First .. Msg'First + Cut - 1));
         declare
            Rest : constant Byte_Array (100 .. 99 + Msg'Length - Cut) :=
              Msg (Msg'First + Cut .. Msg'Last);
         begin
            Update (Ctx, Rest);
         end;
         Final (Ctx, Got);
         if Got /= Want then
            Ada.Text_IO.Put_Line ("FAIL own check: Init/Update/Update/Final differs from the reference, "
                                  & What & ", length" & Msg'Length'Image & ", cut" & Cut'Image);
            raise Program_Error;
         end if;
      end loop;
      Checked := Checked + 1;
   end Check;

   Key : Key_Type;
begin
   for Round in 1 .. 25 loop
      for I in Key'Range loop Key (I) := Rand_Byte; end loop;
      for Len in 0 .. 80 loop
         declare
            Msg : Byte_Array (0 .. Len - 1);
         begin
            for I in Msg'Range loop Msg (I) := Rand_Byte; end loop;
            Check (Msg, Key, "random key round" & Round'Image);
         end;
      end loop;
   end loop;
   --  extremes: r and s all ones (clamped), messages of 0xFF bytes push h close to p
   Key := [others => 16#FF#];
   for Len in 0 .. 80 loop
      Check ([0 .. Len - 1 => 16#FF#], Key, "all-0xFF key and message");
      Check ([0 .. Len - 1 => 0], Key, "all-0xFF key, zero message");
   end loop;
   Key := [others => 0];
   Key (0) := 1;   --  r = 1: the tag is the sum of the blocks mod p, plus s = 0
   for Len in 0 .. 80 loop
      Check ([0 .. Len - 1 => 16#FF#], Key, "r = 1 key");
   end loop;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Checked'Image
                         & " messages (base-256 schoolbook reference, all two-part splits)");
end Own_Checks;
