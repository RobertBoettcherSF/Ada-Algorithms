pragma Ada_2022;
with Ada.Environment_Variables;
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Numerics; use Ada.Numerics;
with Ada.Numerics.Long_Elementary_Functions; use Ada.Numerics.Long_Elementary_Functions;
with Cooley_Tukey_FFT; use Cooley_Tukey_FFT;
procedure Tests is
   type Int_Vec is array (Index) of Integer;

   --  the call under test: plain integers in, plain integers out
   procedure Transform (In_Re, In_Im : Int_Vec; Out_Re, Out_Im : out Int_Vec) is
      Input : Input_Array;
      X : Complex_Array;
   begin
      for I in Index loop
         Input (I) := (Re => Input_Sample (In_Re (I)), Im => Input_Sample (In_Im (I)));
      end loop;
      FFT (Input, X);
      for I in Index loop
         Out_Re (I) := X (I).Re;
         Out_Im (I) := X (I).Im;
      end loop;
   end Transform;

   --  own reference: the unnormalised DFT X(k) = sum x(n) * exp (-2 pi i k n / 8) in Long_Float.
   --  Only the 45-degree twiddles of the last stage round (Q10 constant 724 / 1024 and
   --  truncation of the product), which keeps every output component within 1.5 of the
   --  reference for inputs of magnitude <= 212 (see tests/SOURCES.txt)
   Tolerance : constant Long_Float := 1.5;
   Checked : Natural := 0;

   procedure Check (In_Re, In_Im : Int_Vec; Label : String) is
      Out_Re, Out_Im : Int_Vec;
   begin
      Transform (In_Re, In_Im, Out_Re, Out_Im);
      for K in Index loop
         declare
            Sr, Si : Long_Float := 0.0;
         begin
            for N in Index loop
               declare
                  A : constant Long_Float := -2.0 * Pi * Long_Float (K * N) / 8.0;
               begin
                  Sr := Sr + Long_Float (In_Re (N)) * Cos (A) - Long_Float (In_Im (N)) * Sin (A);
                  Si := Si + Long_Float (In_Re (N)) * Sin (A) + Long_Float (In_Im (N)) * Cos (A);
               end;
            end loop;
            if abs (Long_Float (Out_Re (K)) - Sr) > Tolerance or else abs (Long_Float (Out_Im (K)) - Si) > Tolerance then
               Put_Line ("FAIL " & Label & ": bin" & Integer'Image (K) & " got" & Integer'Image (Out_Re (K))
                         & Integer'Image (Out_Im (K)) & ", DFT" & Long_Float'Image (Sr) & Long_Float'Image (Si));
               raise Program_Error;
            end if;
         end;
      end loop;
      Checked := Checked + 1;
   end Check;

   --  an input whose spectrum does not fit Sample must be rejected, not clamped
   procedure Check_Rejected (In_Re, In_Im : Int_Vec; Label : String) is
      Out_Re, Out_Im : Int_Vec;
   begin
      Transform (In_Re, In_Im, Out_Re, Out_Im);
      Put_Line ("FAIL " & Label & ": accepted, bin 0 =" & Integer'Image (Out_Re (0)) & Integer'Image (Out_Im (0)));
      raise Program_Error;
   exception
      when Constraint_Error => null;
   end Check_Rejected;

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
   function Next (Lo, Hi : Integer) return Integer is
   begin
      Seed := (Seed * 16807) mod 2147483647;   --  Park-Miller minimal standard
      return Lo + Integer (Seed mod Long_Long_Integer (Hi - Lo + 1));
   end Next;

   B : constant := 212;   --  largest input magnitude the tests use for answers
   Zero : constant Int_Vec := [others => 0];
   R, I : Int_Vec;
   O_Re, O_Im : Int_Vec;
begin
   --  hand cases: an impulse at 0 gives a flat real spectrum; zero stays zero
   R := Zero; R (0) := 100;
   Transform (R, Zero, O_Re, O_Im);
   Assert (O_Re = Int_Vec'[others => 100] and then O_Im = Zero, "impulse");
   Transform (Zero, Zero, O_Re, O_Im);
   Assert (O_Re = Zero and then O_Im = Zero, "zero");
   --  alternating +50 / -50: all energy in bin 4 (8 * 50 = 400)
   for N in Index loop
      R (N) := (if N mod 2 = 0 then 50 else -50);
   end loop;
   Transform (R, Zero, O_Re, O_Im);
   Assert (O_Re (4) = 400 and then (for all K in Index => (if K /= 4 then O_Re (K) = 0 and O_Im (K) = 0)), "alternating");
   Put_Line ("PASS hand cases");

   --  every single impulse of magnitude B, real and imaginary, positive and negative
   for N in Index loop
      for S in -1 .. 1 loop
         if S /= 0 then
            R := Zero; I := Zero; R (N) := S * B; Check (R, Zero, "impulse re");
            I (N) := S * B; Check (Zero, I, "impulse im");
         end if;
      end loop;
   end loop;
   --  random inputs over the whole range, and inputs at the corners (+-B in every component)
   for Trial in 1 .. 20_000 loop
      for N in Index loop
         if Trial mod 5 = 0 then
            R (N) := (if Next (0, 1) = 0 then -B else B); I (N) := (if Next (0, 1) = 0 then -B else B);
         else
            R (N) := Next (-B, B); I (N) := Next (-B, B);
         end if;
      end loop;
      Check (R, I, "random");
   end loop;
   Put_Line ("PASS DFT reference:" & Natural'Image (Checked) & " inputs");

   --  spectra that do not fit Sample (bin 0 = 8 * 1000, 8 * 2048, 8 * 300 + i * 8 * 300)
   Check_Rejected ([others => 1000], Zero, "eight 1000s");
   Check_Rejected ([others => 2048], Zero, "eight 2048s");
   Check_Rejected ([others => 300], [others => 300], "eight 300 + 300i");
   Put_Line ("All Cooley_Tukey_FFT tests passed.");
end Tests;
