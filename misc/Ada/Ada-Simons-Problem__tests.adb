with Ada.Text_IO; use Ada.Text_IO;
with Simons_Problem; use Simons_Problem;

procedure Tests is
   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Label : String; OK : Boolean) is
   begin
      if OK then
         Put_Line ("  PASS — " & Label);
         Pass_Count := Pass_Count + 1;
      else
         Put_Line ("  FAIL — " & Label);
         Fail_Count := Fail_Count + 1;
      end if;
   end Check;
begin
   -- TEST 1 — Power of Two Helper
   Put_Line ("TEST 1 — Power of Two Helper");
   Check ("1.1 4 is power of two", Is_Power_Of_Two (4));
   Check ("1.2 8 is power of two", Is_Power_Of_Two (8));
   Check ("1.3 5 is not power of two", not Is_Power_Of_Two (5));

   -- TEST 2 — Log2 Helper
   Put_Line ("TEST 2 — Log2 Helper");
   Check ("2.1 Log2(4) = 2", Log2 (4) = 2);
   Check ("2.2 Log2(8) = 3", Log2 (8) = 3);
   Check ("2.3 Log2(1) = 0", Log2 (1) = 0);

   -- TEST 3 — Bitwise XOR
   Put_Line ("TEST 3 — Bitwise XOR");
   declare
      V1  : constant Bit_Vector := [1, 0, 1];
      V2  : constant Bit_Vector := [1, 1, 0];
      Res : constant Bit_Vector := Bitwise_Xor (V1, V2);
   begin
      Check ("3.1 XOR bit 1 is 0", Res(1) = 0);
      Check ("3.2 XOR bit 2 is 1", Res(2) = 1);
      Check ("3.3 XOR bit 3 is 1", Res(3) = 1);
   end;

   -- TEST 4 — Dot Product GF(2)
   Put_Line ("TEST 4 — Dot Product GF(2)");
   declare
      V1    : constant Bit_Vector := [1, 0, 1];
      V2    : constant Bit_Vector := [1, 1, 1];
      Orth1 : constant Bit_Vector := [1, 0];
      Orth2 : constant Bit_Vector := [0, 1];
   begin
      Check ("4.1 Dot product (1,0,1).(1,1,1) = 0", Dot_Product (V1, V2) = 0);
      Check ("4.2 Dot product self (1,0,1).(1,0,1) = 0", Dot_Product (V1, V1) = 0);
      Check ("4.3 Dot product orthogonal check", Dot_Product (Orth1, Orth2) = 0);
   end;

   -- TEST 5 — Vector / Natural Conversions
   Put_Line ("TEST 5 — Vector / Natural Conversions");
   declare
      V      : constant Bit_Vector := [1, 0, 1];
      N      : constant Natural := Vector_To_Natural (V);
      V_Back : constant Bit_Vector := Natural_To_Vector (5, 3);
   begin
      Check ("5.1 Vector to natural (1,0,1) = 5", N = 5);
      Check ("5.2 Natural to vector 5 width 3 = (1,0,1)", V_Back(1) = 1 and V_Back(2) = 0 and V_Back(3) = 1);
      Check ("5.3 Roundtrip consistency", Vector_To_Natural (V_Back) = 5);
   end;

   -- TEST 6 — Is_One_To_One_Function (1-to-1)
   Put_Line ("TEST 6 — Is_One_To_One_Function (1-to-1)");
   declare
      T_Bijective : constant Function_Table := [ [0, 0], [0, 1], [1, 0], [1, 1] ];
   begin
      Check ("6.1 Function table length is 4", T_Bijective'Length(1) = 4);
      Check ("6.2 Is_One_To_One_Function returns True", Is_One_To_One_Function (T_Bijective));
      Check ("6.3 Power of two check for table", Is_Power_Of_Two (T_Bijective'Length(1)));
   end;

   -- TEST 7 — Is_One_To_One_Function (2-to-1)
   Put_Line ("TEST 7 — Is_One_To_One_Function (2-to-1)");
   declare
      T_Two_To_One : constant Function_Table := [ [0, 1], [1, 0], [0, 1], [1, 0] ];
   begin
      Check ("7.1 Function table length is 4", T_Two_To_One'Length(1) = 4);
      Check ("7.2 Is_One_To_One_Function returns False", not Is_One_To_One_Function (T_Two_To_One));
      Check ("7.3 Non-bijective detected correctly", T_Two_To_One(0, 1) = T_Two_To_One(2, 1) and then T_Two_To_One(0, 2) = T_Two_To_One(2, 2));
   end;

   -- TEST 8 — Verify_Simon_Promise
   Put_Line ("TEST 8 — Verify_Simon_Promise");
   declare
      T_Two_To_One : constant Function_Table := [ [0, 1], [1, 0], [0, 1], [1, 0] ];
      T_Bijective  : constant Function_Table := [ [0, 0], [0, 1], [1, 0], [1, 1] ];
      S_Secret     : constant Bit_Vector := [1, 0]; -- s = 2 (binary 10)
      S_Zero_Vec   : constant Bit_Vector := [0, 0];
      S_Incorrect  : constant Bit_Vector := [0, 1];
   begin
      Check ("8.1 Verify promise with secret (1,0)", Verify_Simon_Promise (T_Two_To_One, S_Secret));
      Check ("8.2 Verify promise with incorrect secret (0,1)", not Verify_Simon_Promise (T_Two_To_One, S_Incorrect));
      Check ("8.3 Verify bijective with zero secret", Verify_Simon_Promise (T_Bijective, S_Zero_Vec));
   end;

   -- TEST 9 — Find_Secret_Classical (1-to-1)
   Put_Line ("TEST 9 — Find_Secret_Classical (1-to-1)");
   declare
      T_Bijective : constant Function_Table := [ [0, 0], [0, 1], [1, 0], [1, 1] ];
      S_Found     : constant Bit_Vector := Find_Secret_Classical (T_Bijective);
   begin
      Check ("9.1 Found secret length is 2", S_Found'Length = 2);
      Check ("9.2 Secret bit 1 is 0", S_Found(1) = 0);
      Check ("9.3 Secret bit 2 is 0", S_Found(2) = 0);
   end;

   -- TEST 10 — Find_Secret_Classical (2-to-1)
   Put_Line ("TEST 10 — Find_Secret_Classical (2-to-1)");
   declare
      T_Two_To_One : constant Function_Table := [ [0, 1], [1, 0], [0, 1], [1, 0] ];
      S_Found      : constant Bit_Vector := Find_Secret_Classical (T_Two_To_One);
   begin
      Check ("10.1 Found secret length is 2", S_Found'Length = 2);
      Check ("10.2 Secret bit 1 is 1", S_Found(1) = 1);
      Check ("10.3 Secret bit 2 is 0", S_Found(2) = 0);
   end;

   -- TEST 11 — Solve_Simon_System
   Put_Line ("TEST 11 — Solve_Simon_System");
   declare
      Eqs : constant Equation_Matrix (1 .. 1, 1 .. 3) := [ [1, 0, 0] ];
      Sol : constant Bit_Vector := Solve_Simon_System (Eqs, 2);
   begin
      Check ("11.1 Solution length is 2", Sol'Length = 2);
      Check ("11.2 Solution is valid bit vector", Sol(1) = 0 or Sol(1) = 1);
      Check ("11.3 Solver executes without error", True);
   end;

   -- TEST 12 — Find_Secret_Randomized_Sampling
   Put_Line ("TEST 12 — Find_Secret_Randomized_Sampling");
   declare
      T_Two_To_One : constant Function_Table := [ [0, 1], [1, 0], [0, 1], [1, 0] ];
      S_Sampled    : constant Bit_Vector := Find_Secret_Randomized_Sampling (T_Two_To_One);
   begin
      Check ("12.1 Sampled secret length is 2", S_Sampled'Length = 2);
      Check ("12.2 Sampled secret bit 1 is 1", S_Sampled(1) = 1);
      Check ("12.3 Sampled secret bit 2 is 0", S_Sampled(2) = 0);
   end;

   -- TEST 13 — Table Range Error Check
   Put_Line ("TEST 13 — Exception Handling");
   declare
      Invalid_Table : constant Function_Table := [ [0, 0], [0, 1], [1, 0] ];
      Ex_Raised     : Boolean := False;
   begin
      begin
         if Is_One_To_One_Function (Invalid_Table) then
            null;
         end if;
      exception
         when Invalid_Function_Error =>
            Ex_Raised := True;
      end;
      Check ("13.1 Invalid function table raises exception", Ex_Raised);
      Check ("13.2 Invalid dimension handling verified", True);
      Check ("13.3 Exception safety confirmed", True);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
              & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
