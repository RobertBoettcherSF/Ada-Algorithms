--  Own checks (see tests/SOURCES.txt). Assume Hidden_Subgroup_Problem is
--  wrong or does nothing. Oracles are built with a KNOWN hidden subgroup, so
--  the expected answer is the construction parameter, not a recomputation:
--  * Z_N, N = 2 .. 40: f (x) = 7 * (x mod r) + 1 for every divisor r of N
--    (r = N included: one-to-one, H = {0}) hides H = r Z_N (period r); answers are checked by certificate
--    (Verify_Hidden_Subgroup) and by comparing the generated subgroup with H;
--  * Verify_Hidden_Subgroup: h is in H iff r divides h (every h, every r);
--  * characters: g annihilates h iff N / gcd (N, h) divides g;
--  * GCD: largest common divisor by downward search;
--  * Simon, n = 1 .. 5 bits, every s /= 0: f (x) = min (x, x xor s).
--  * Simon_Null_Vector (the GF(2) step, called directly): every s at n = 1 .. 6
--    from all of s-perp and from random growing subsets of it, plus random
--    equation sets, against a brute-force null space (parity by xor folding).
--  * Simon_Sample_Equations: for a hidden s the support is exactly s-perp
--    (brute-force parity); one-to-one gives every y, constant gives {0}.
--  * Solve_Simons_Problem end to end at n = 6 .. 8 (oracle min (x, x xor s)
--    xor 165), each x queried once (2**n queries, no collision search), and
--    oracles invariant under a subspace of dimension >= 2 -> Invalid_Oracle.
pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Hidden_Subgroup_Problem; use Hidden_Subgroup_Problem;

procedure Own_Checks is
   Failures : Natural := 0;
   Checked  : Natural := 0;

   procedure Expect (Cond : Boolean; What : String) is
   begin
      Checked := Checked + 1;
      if not Cond then
         Failures := Failures + 1;
         if Failures <= 25 then
            Put_Line ("  FAIL own: " & What);
         end if;
      end if;
   end Expect;

   R_Hidden : Group_Element := 1;
   S_Hidden : Bit_Mask := 1;

   function Coset_Oracle (X : Group_Element) return Group_Element is
     (7 * (X mod R_Hidden) + 1);
   function Simon_Oracle (X : Bit_Mask) return Bit_Mask is
     (Bit_Mask'Min (X, X xor S_Hidden));
   Queries : Natural := 0;
   function Counted_Oracle (X : Bit_Mask) return Bit_Mask is
   begin
      Queries := Queries + 1;
      return Bit_Mask'Min (X, X xor S_Hidden) xor 165;
   end Counted_Oracle;
   --  invariant under every s whose bits lie in S_Hidden
   function Subspace_Oracle (X : Bit_Mask) return Bit_Mask is (X and not S_Hidden);

   --  oracles that are only meaningful on their domain: the value outside
   --  Z_N (x >= N) or outside n bits (x >= 2**n) must never be read
   N_Domain : Group_Element := 2;
   function Domain_Oracle (X : Group_Element) return Group_Element is
     (if X >= N_Domain then 999 else X mod R_Hidden);
   Bits_Domain : Natural := 1;
   function Masked_Identity (X : Bit_Mask) return Bit_Mask is
     (X mod Bit_Mask (2 ** Bits_Domain));

   --  y . x mod 2 by xor folding (not a bit-count loop)
   function Ref_Parity (A, B : Bit_Mask) return Bit_Mask is
      V : Bit_Mask := A and B;
   begin
      V := V xor V / 16;
      V := V xor V / 4;
      V := V xor V / 2;
      return V and 1;
   end Ref_Parity;

   --  brute-force null space: number of non-zero x < 2**Bits orthogonal to
   --  every equation, and the first one
   procedure Ref_Null (Bits : Positive; Eqs : Bit_Mask_Array; Count : out Natural; First : out Bit_Mask) is
   begin
      Count := 0;
      First := 0;
      for X in Bit_Mask range 1 .. Bit_Mask (2 ** Bits - 1) loop
         if (for all E of Eqs => Ref_Parity (E, X) = 0) then
            Count := Count + 1;
            if Count = 1 then
               First := X;
            end if;
         end if;
      end loop;
   end Ref_Null;

   type U32 is mod 2 ** 32;
   Lcg : U32 := 12345;
   function Next_Rand (Modulus : Positive) return Natural is
   begin
      Lcg := Lcg * 1103515245 + 12345;
      return Natural ((Lcg / 65536) mod U32 (Modulus));
   end Next_Rand;

   --  Simon_Null_Vector must agree with the brute-force null space
   procedure Check_Null (Bits : Positive; Eqs : Bit_Mask_Array; What : String) is
      Count : Natural;
      First : Bit_Mask;
   begin
      Ref_Null (Bits, Eqs, Count, First);
      declare
         Got : constant Bit_Mask := Simon_Null_Vector (Bits, Eqs);
      begin
         Expect (Count = 1 and then Got = First,
                 "Simon_Null_Vector " & What & " n=" & Bits'Image & " got" & Got'Image
                 & ", null space has" & Count'Image & " non-zero vectors, first" & First'Image);
      end;
   exception
      when Subgroup_Not_Found =>
         Expect (Count = 0, "Simon_Null_Vector " & What & " n=" & Bits'Image & ": Subgroup_Not_Found, but"
                 & Count'Image & " non-zero null vectors");
      when Invalid_Oracle =>
         Expect (Count > 1, "Simon_Null_Vector " & What & " n=" & Bits'Image & ": Invalid_Oracle, but"
                 & Count'Image & " non-zero null vectors");
   end Check_Null;

   function Ref_GCD (A, B : Group_Element) return Group_Element is
   begin
      if A = 0 then
         return B;
      elsif B = 0 then
         return A;
      end if;
      for D in reverse 1 .. Group_Element'Min (A, B) loop
         if A mod D = 0 and then B mod D = 0 then
            return D;
         end if;
      end loop;
      return 1;
   end Ref_GCD;

   --  subgroup of Z_N generated by Gens, as a membership table
   type Member_Table is array (Group_Element range 0 .. 64) of Boolean;
   function Generated (N : Group_Element; Gens : Element_Array) return Member_Table is
      T : Member_Table := [0 => True, others => False];
      Changed : Boolean := True;
   begin
      while Changed loop
         Changed := False;
         for X in 0 .. N - 1 loop
            if T (X) then
               for G of Gens loop
                  if not T ((X + G) mod N) then
                     T ((X + G) mod N) := True;
                     Changed := True;
                  end if;
               end loop;
            end if;
         end loop;
      end loop;
      return T;
   end Generated;
begin
   for N in Group_Element range 2 .. 40 loop
      for R in Group_Element range 1 .. N loop   --  R = N: one-to-one oracle, H = {0}
         if N mod R = 0 then
            R_Hidden := R;
            declare
               H_Ref : Member_Table := [others => False];
            begin
               for X in 0 .. N - 1 loop
                  H_Ref (X) := X mod R = 0;
               end loop;
               if R = 1 then
                  --  constant oracle: spec / tests expect an exception
                  begin
                     declare
                        P : constant Period_Type := Solve_Period_Finding (N, Coset_Oracle'Unrestricted_Access);
                     begin
                        Expect (False, "constant oracle accepted, period" & P'Image);
                     end;
                  exception
                     when Invalid_Oracle | Subgroup_Not_Found => Expect (True, "");
                  end;
               else
                  begin
                     Expect (Solve_Period_Finding (N, Coset_Oracle'Unrestricted_Access) = Period_Type (R),
                             "period N=" & N'Image & " r=" & R'Image);
                     declare
                        Gens : constant Element_Array := Solve_Abelian_HSP (N, Coset_Oracle'Unrestricted_Access);
                        T    : constant Member_Table := Generated (N, Gens);
                        Same : Boolean := True;
                     begin
                        for X in 0 .. N - 1 loop
                           Same := Same and then T (X) = H_Ref (X);
                        end loop;
                        Expect (Same, "Solve_Abelian_HSP generates H = r Z_N, N=" & N'Image & " r=" & R'Image
                                & " got" & Gens (Gens'First)'Image);
                        Expect (Verify_Hidden_Subgroup (N, Gens, Coset_Oracle'Unrestricted_Access),
                                "certificate: Verify_Hidden_Subgroup accepts the HSP answer, N=" & N'Image
                                & " r=" & R'Image);
                     end;
                  exception
                     when Subgroup_Not_Found | Invalid_Oracle =>
                        Expect (False, "period / HSP raised for N=" & N'Image & " r=" & R'Image);
                  end;
               end if;
               for Hh in 0 .. N - 1 loop
                  Expect (Verify_Hidden_Subgroup (N, [1 => Hh], Coset_Oracle'Unrestricted_Access) = H_Ref (Hh),
                          "Verify_Hidden_Subgroup N=" & N'Image & " r=" & R'Image & " h=" & Hh'Image);
                  Expect (Verify_Hidden_Subgroup (N, [R, Hh], Coset_Oracle'Unrestricted_Access) = H_Ref (Hh),
                          "Verify_Hidden_Subgroup pair N=" & N'Image & " h=" & Hh'Image);
               end loop;
            end;
         end if;
      end loop;
      for G in 0 .. N - 1 loop
         for Hh in 0 .. N - 1 loop
            Expect (Evaluate_Character_Orthogonality (N, G, [1 => Hh])
                      = (G mod (N / Ref_GCD (N, Hh)) = 0),
                    "character N=" & N'Image & " g=" & G'Image & " h=" & Hh'Image);
         end loop;
         Expect (Evaluate_Character_Orthogonality (N, G, [N / 2, 0, 1]) = (G mod N = 0),
                 "character on [N/2, 0, 1]");
      end loop;
   end loop;
   for A in Group_Element range 0 .. 60 loop
      for B in Group_Element range 0 .. 60 loop
         Expect (Greatest_Common_Divisor (A, B) = Ref_GCD (A, B), "gcd" & A'Image & B'Image);
      end loop;
   end loop;
   for Bits in 1 .. 5 loop
      for S in Bit_Mask range 1 .. Bit_Mask (2 ** Bits - 1) loop
         S_Hidden := S;
         Expect (Solve_Simons_Problem (Bits, Simon_Oracle'Unrestricted_Access) = S,
                 "Simon n=" & Bits'Image & " s=" & S'Image);
      end loop;
   end loop;
   --  the GF(2) step on its own: every s at n = 1 .. 6
   for Bits in 1 .. 6 loop
      for S in Bit_Mask range 1 .. Bit_Mask (2 ** Bits - 1) loop
         declare
            Perp : Bit_Mask_Array (1 .. 2 ** Bits);
            Len  : Natural := 0;
         begin
            for Y in Bit_Mask range 0 .. Bit_Mask (2 ** Bits - 1) loop
               if Ref_Parity (Y, S) = 0 then
                  Len := Len + 1;
                  Perp (Len) := Y;
               end if;
            end loop;
            Expect (Len = 2 ** (Bits - 1), "s-perp size");
            Check_Null (Bits, Perp (1 .. Len), "all of s-perp, s=" & S'Image);
            --  random equations from s-perp, checked after every one added
            --  (Invalid_Oracle until they span s-perp, then s)
            declare
               Eqs : Bit_Mask_Array (1 .. 3 * Bits + 2);
            begin
               for K in Eqs'Range loop
                  Eqs (K) := Perp (1 + Next_Rand (Len));
                  Check_Null (Bits, Eqs (1 .. K), "random s-perp subset, s=" & S'Image & " k=" & K'Image);
               end loop;
               Expect (Simon_Null_Vector (Bits, Eqs) = S, "Simon_Null_Vector from 3n+2 samples, s=" & S'Image);
            exception
               when Subgroup_Not_Found | Invalid_Oracle =>
                  Expect (False, "Simon_Null_Vector from 3n+2 samples raised, s=" & S'Image);
            end;
         end;
      end loop;
      Check_Null (Bits, [1 .. 0 => 0], "no equations");
      for Trial in 1 .. 300 loop
         declare
            Eqs : Bit_Mask_Array (1 .. 1 + Next_Rand (Bits + 2));
         begin
            for E of Eqs loop
               E := Bit_Mask (Next_Rand (2 ** Bits));
            end loop;
            Check_Null (Bits, Eqs, "random equations, trial" & Trial'Image);
         end;
      end loop;
   end loop;
   --  the sampling step: support of the measurement is exactly s-perp
   for Bits in 1 .. 6 loop
      for S in Bit_Mask range 0 .. Bit_Mask (2 ** Bits - 1) loop
         S_Hidden := S;
         declare
            Got  : constant Bit_Mask_Array := Simon_Sample_Equations (Bits, Simon_Oracle'Unrestricted_Access);
            Want : Bit_Mask_Array (1 .. 2 ** Bits);
            Len  : Natural := 0;
         begin
            for Y in Bit_Mask range 0 .. Bit_Mask (2 ** Bits - 1) loop
               if S = 0 or else Ref_Parity (Y, S) = 0 then
                  Len := Len + 1;
                  Want (Len) := Y;
               end if;
            end loop;
            Expect (Got = Want (1 .. Len), "Simon_Sample_Equations = s-perp, n=" & Bits'Image & " s=" & S'Image
                    & " got" & Got'Length'Image & " equations");
         end;
      end loop;
      S_Hidden := Bit_Mask (2 ** Bits - 1);   --  constant on n bits
      Expect (Simon_Sample_Equations (Bits, Subspace_Oracle'Unrestricted_Access) = [1 => 0],
              "Simon_Sample_Equations constant oracle = {0}, n=" & Bits'Image);
   end loop;
   --  end to end at n = 6 .. 8, once per x
   for Bits in 6 .. 8 loop
      for K in 1 .. 40 loop
         S_Hidden := Bit_Mask (1 + Next_Rand (2 ** Bits - 1));
         Queries := 0;
         begin
            Expect (Solve_Simons_Problem (Bits, Counted_Oracle'Unrestricted_Access) = S_Hidden,
                    "Simon n=" & Bits'Image & " s=" & S_Hidden'Image);
         exception
            when Subgroup_Not_Found | Invalid_Oracle =>
               Expect (False, "Simon raised, n=" & Bits'Image & " s=" & S_Hidden'Image);
         end;
         Expect (Queries = 2 ** Bits, "Simon queries f once per x, n=" & Bits'Image & " got" & Queries'Image);
      end loop;
   end loop;
   --  invariant under a whole subspace: one bit -> that s; two or more -> Invalid_Oracle
   for Bits in 1 .. 6 loop
      for M in Bit_Mask range 1 .. Bit_Mask (2 ** Bits - 1) loop
         S_Hidden := M;
         declare
            One_Bit : constant Boolean := (M and (M - 1)) = 0;
            Got     : Bit_Mask;
         begin
            Got := Solve_Simons_Problem (Bits, Subspace_Oracle'Unrestricted_Access);   --  may raise
            Expect (One_Bit and then Got = M, "Simon subspace oracle, n=" & Bits'Image & " mask" & M'Image);
         exception
            when Invalid_Oracle =>
               Expect (not One_Bit, "Simon single-bit oracle raised Invalid_Oracle, mask" & M'Image);
            when Subgroup_Not_Found =>
               Expect (False, "Simon subspace oracle raised Subgroup_Not_Found, mask" & M'Image);
         end;
      end loop;
   end loop;
   --  one-to-one on n bits, but x and x + 2**n collide: still no s in Z_2^n
   for Bits in 1 .. 7 loop
      Bits_Domain := Bits;
      begin
         Expect (Solve_Simons_Problem (Bits, Masked_Identity'Unrestricted_Access) = 0,
                 "Simon one-to-one on" & Bits'Image & " bits returned a value");
      exception
         when Subgroup_Not_Found => Expect (True, "");
      end;
   end loop;
   --  oracles with junk outside Z_N: only x in 0 .. N - 1 may be read
   for N in Group_Element range 2 .. 24 loop
      N_Domain := N;
      for R in Group_Element range 1 .. N loop
         if N mod R = 0 then
            R_Hidden := R;
            if R = 1 then
               begin
                  Expect (Solve_Period_Finding (N, Domain_Oracle'Unrestricted_Access) = 0,
                          "constant-on-Z_N oracle accepted, N=" & N'Image);
               exception
                  when Invalid_Oracle | Subgroup_Not_Found => Expect (True, "");
               end;
            else
               begin
                  Expect (Solve_Period_Finding (N, Domain_Oracle'Unrestricted_Access) = Period_Type (R),
                          "period with junk outside Z_N, N=" & N'Image & " r=" & R'Image);
               exception
                  when Invalid_Oracle | Subgroup_Not_Found =>
                     Expect (False, "period with junk outside Z_N raised, N=" & N'Image & " r=" & R'Image);
               end;
            end if;
            for Hh in 0 .. N - 1 loop
               Expect (Verify_Hidden_Subgroup (N, [1 => Hh], Domain_Oracle'Unrestricted_Access) = (Hh mod R = 0),
                       "Verify with junk outside Z_N, N=" & N'Image & " r=" & R'Image & " h=" & Hh'Image);
            end loop;
         end if;
      end loop;
   end loop;
   --  s = 0 (one-to-one oracle): no non-zero s exists
   S_Hidden := 0;
   begin
      Expect (Solve_Simons_Problem (4, Simon_Oracle'Unrestricted_Access) = 0, "Simon s=0 returned a value");
   exception
      when Subgroup_Not_Found => Expect (True, "");
   end;
   if Failures > 0 then
      Put_Line ("FAIL own checks:" & Failures'Image & " of" & Checked'Image);
      raise Program_Error with "own checks failed";
   end if;
   Put_Line ("PASS own checks:" & Checked'Image & " (known hidden subgroups, certificates, gcd and character properties)");
end Own_Checks;
