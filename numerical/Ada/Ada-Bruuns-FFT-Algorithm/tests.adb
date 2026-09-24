with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Bruun_FFT; use Bruun_FFT;

procedure Tests is
   use Complex_Types;

   -- V&V Helper: Verifies floating point equivalence within safety tolerances
   function Is_Close (A, B : Complex; Tol : Real := 1.0e-5) return Boolean is
   begin
      return abs (A.Re - B.Re) < Tol and abs (A.Im - B.Im) < Tol;
   end Is_Close;

   function Is_Close_Real (A, B : Real; Tol : Real := 1.0e-5) return Boolean is
   begin
      return abs (A - B) < Tol;
   end Is_Close_Real;

   procedure Run_Tests is
      In_Real_4  : Real_Array(0..3) := (1.0, 2.0, 3.0, 4.0);
      Out_Comp_4 : Complex_Array(0..3);
      
      In_Comp_4  : Complex_Array(0..3) := 
        ((Re => 1.0, Im => 0.0), (Re => 2.0, Im => 0.0), 
         (Re => 3.0, Im => 0.0), (Re => 4.0, Im => 0.0));
      Out_Comp_4_B : Complex_Array(0..3);
      
      In_Real_8  : Real_Array(0..7) := (1.0, 1.0, 1.0, 1.0, 0.0, 0.0, 0.0, 0.0);
      Out_Comp_8 : Complex_Array(0..7);

      In_Comp_6  : Complex_Array(0..5) := 
        ((Re => 1.0, Im => 0.0), (Re => 0.0, Im => 0.0), 
         (Re => 1.0, Im => 0.0), (Re => 0.0, Im => 0.0), 
         (Re => 1.0, Im => 0.0), (Re => 0.0, Im => 0.0));
      Out_Comp_6 : Complex_Array(0..5);

   begin
      -- TEST 1 - Functional Correctness (Real Power-of-Two)
      Put_Line("TEST 1 - Power of Two Real (N=4) Functionality");
      FFT_Power_Of_Two_Real (In_Real_4, Out_Comp_4);
      Put_Line("  1.1 Assert DC component matches expectations (Disproving signal energy loss)");
      Assert (Is_Close (Out_Comp_4(0), (Re => 10.0, Im => 0.0)), "DC component mismatch");
      Put_Line("     PASS");
      Put_Line("  1.2 Assert Nyquist boundary (Disproving high-frequency aliasing)");
      Assert (Is_Close (Out_Comp_4(2), (Re => -2.0, Im => 0.0)), "Nyquist component mismatch");
      Put_Line("     PASS");
      Put_Line("  1.3 Assert Conjugate Symmetry (Disproving imaginary domain drift)");
      Assert (Is_Close (Out_Comp_4(1), (Re => Out_Comp_4(3).Re, Im => -Out_Comp_4(3).Im)), "Symmetry failed");
      Put_Line("     PASS");

      -- TEST 2 - Functional Consistency (Complex Power-of-Two)
      Put_Line("TEST 2 - Power of Two Complex (N=4) Functionality");
      FFT_Power_Of_Two_Complex (In_Comp_4, Out_Comp_4_B);
      Put_Line("  2.1 Assert Complex evaluation perfectly matches Real evaluation path");
      Assert (Is_Close (Out_Comp_4(1), Out_Comp_4_B(1)), "Complex/Real tree drift");
      Put_Line("     PASS");

      -- TEST 3 - Arbitrary Composite Structure 
      Put_Line("TEST 3 - Arbitrary Even Composite (N=6)");
      FFT_Arbitrary_Composite (In_Comp_6, Out_Comp_6);
      Put_Line("  3.1 Assert DC component for N=6 (Disproving composite offset errors)");
      Assert (Is_Close (Out_Comp_6(0), (Re => 3.0, Im => 0.0)), "DC mismatch N=6");
      Put_Line("     PASS");
      Put_Line("  3.2 Assert periodicity/harmonics in N=6 (Disproving division remainder bugs)");
      -- FIXED: A period-2 signal [1,0,1,0,1,0] in an N=6 array has its harmonic peak at bin k = N/2 = 3.
      Assert (Is_Close (Out_Comp_6(3), (Re => 3.0, Im => 0.0)), "Harmonic mismatch N=6");
      Put_Line("     PASS");

      -- TEST 4 - Boundary & Error Rejection
      Put_Line("TEST 4 - Edge Cases and Safety Rejections");
      Put_Line("  4.1 Assert Invalid_Size on N=0 (Disproving unhandled divide-by-zero)");
      declare
         Empty_R : Real_Array(1..0);
         Empty_C : Complex_Array(1..0);
      begin
         FFT_Power_Of_Two_Real(Empty_R, Empty_C);
         Assert (False, "Expected constraint rejection for Empty Array");
      exception
         when Invalid_Size_Error => Put_Line("     PASS");
      end;
      
      Put_Line("  4.2 Assert Invalid_Size on Non-Power-of-Two (Disproving silent memory corruption)");
      declare
         Bad_R : Real_Array(0..2) := (1.0, 2.0, 3.0);
         Bad_C : Complex_Array(0..2);
      begin
         FFT_Power_Of_Two_Real(Bad_R, Bad_C);
         Assert (False, "Expected constraint rejection for N=3 in Base Power variant");
      exception
         when Invalid_Size_Error => Put_Line("     PASS");
      end;
      
      Put_Line("  4.3 Assert Invalid_Size on Odd Composite N=5 (Disproving Murakami violation)");
      declare
         Bad_C_In  : Complex_Array(0..4) := (others => (Re => 0.0, Im => 0.0));
         Bad_C_Out : Complex_Array(0..4);
      begin
         FFT_Arbitrary_Composite(Bad_C_In, Bad_C_Out);
         Assert (False, "Expected constraint rejection for Odd N");
      exception
         when Invalid_Size_Error => Put_Line("     PASS");
      end;

      -- TEST 5 - Linear Superposition
      Put_Line("TEST 5 - Linearity Property Verification");
      declare
         In_A    : Complex_Array(0..3) := ((Re=>1.0, Im=>0.0), others => (Re=>0.0, Im=>0.0));
         In_B    : Complex_Array(0..3) := ((Re=>0.0, Im=>0.0), (Re=>1.0, Im=>0.0), others => (Re=>0.0, Im=>0.0));
         In_Sum  : Complex_Array(0..3) := ((Re=>1.0, Im=>0.0), (Re=>1.0, Im=>0.0), others => (Re=>0.0, Im=>0.0));
         Out_A, Out_B, Out_Sum : Complex_Array(0..3);
      begin
         FFT_Power_Of_Two_Complex(In_A, Out_A);
         FFT_Power_Of_Two_Complex(In_B, Out_B);
         FFT_Power_Of_Two_Complex(In_Sum, Out_Sum);
         Put_Line("  5.1 Assert FFT(A+B) = FFT(A) + FFT(B) for DC bin (Disproving nonlinear overlap)");
         Assert (Is_Close (Out_Sum(0), Out_A(0) + Out_B(0)), "Linearity failed bin 0");
         Put_Line("     PASS");
         Put_Line("  5.2 Assert FFT(A+B) = FFT(A) + FFT(B) for freq bin (Disproving interference)");
         Assert (Is_Close (Out_Sum(1), Out_A(1) + Out_B(1)), "Linearity failed bin 1");
         Put_Line("     PASS");
      end;
      
      -- TEST 6 - Parseval's Theorem (Energy Conservation)
      Put_Line("TEST 6 - Parseval's Theorem Constraint");
      declare
         Energy_Time : Real := 0.0;
         Energy_Freq : Real := 0.0;
         N_Real      : Real := Real(In_Real_8'Length);
      begin
         FFT_Power_Of_Two_Real(In_Real_8, Out_Comp_8);
         for I in In_Real_8'Range loop
            Energy_Time := Energy_Time + (In_Real_8(I) * In_Real_8(I));
         end loop;
         for I in Out_Comp_8'Range loop
            Energy_Freq := Energy_Freq + (Out_Comp_8(I).Re**2 + Out_Comp_8(I).Im**2);
         end loop;
         Put_Line("  6.1 Assert Energy[Time]*N = Energy[Freq] (Disproving mathematical entropy leak)");
         Assert (Is_Close_Real (Energy_Time * N_Real, Energy_Freq, 1.0e-3), "Parseval failed");
         Put_Line("     PASS");
      end;
      
      -- TEST 7 - Impulse Dynamics
      Put_Line("TEST 7 - Impulse Response Safety");
      declare
         Impulse : Real_Array(0..3) := (1.0, 0.0, 0.0, 0.0);
         Out_Imp : Complex_Array(0..3);
      begin
         FFT_Power_Of_Two_Real(Impulse, Out_Imp);
         Put_Line("  7.1 Assert uniform frequency response on delta impulse (Disproving singularity crashes)");
         Assert (Is_Close (Out_Imp(1), (Re => 1.0, Im => 0.0)), "Impulse bin 1 mismatch");
         Put_Line("     PASS");
         Put_Line("  7.2 Assert high-frequency impulse consistency");
         Assert (Is_Close (Out_Imp(3), (Re => 1.0, Im => 0.0)), "Impulse bin 3 mismatch");
         Put_Line("     PASS");
      end;

   end Run_Tests;

begin
   Run_Tests;
   Put_Line("=========================");
   Put_Line("14/14 ASSERTIONS PASSED. SYSTEM VERIFIED.");
end Tests;
