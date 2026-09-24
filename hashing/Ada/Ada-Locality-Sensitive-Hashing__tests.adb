with Ada.Text_IO; use Ada.Text_IO;
with Locality_Sensitive_Hashing; use Locality_Sensitive_Hashing;

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
   Put_Line ("Locality-Sensitive Hashing Test Suite");
   Put_Line ("=====================================");

   --  TEST 1 — Bit_Sampling_Hash Normal Operations
   Put_Line ("TEST 1 — Bit_Sampling_Hash Normal Ops");
   declare
      Data : constant Bit_Vector := [True, False, True, False];
   begin
      Check ("1.1 Single bit (True)", Bit_Sampling_Hash (Data, [1 => 1]) = 1);
      Check ("1.2 Single bit (False)", Bit_Sampling_Hash (Data, [1 => 2]) = 0);
      Check ("1.3 Multiple bits", Bit_Sampling_Hash (Data, [1, 3]) = 3); -- 11 base 2
   end;

   --  TEST 2 — Bit_Sampling_Hash Complex Indexing
   Put_Line ("TEST 2 — Bit_Sampling_Hash Complex Indexing");
   declare
      Data : constant Bit_Vector (5 .. 8) := [True, True, False, False];
   begin
      Check ("2.1 Offset bounds match", Bit_Sampling_Hash (Data, [1 => 5]) = 1);
      Check ("2.2 Combined shifted bounds", Bit_Sampling_Hash (Data, [1 => 5, 2 => 7]) = 2); -- 10 base 2
      
      declare
         Indices : Index_Array (1 .. 32);
      begin
         for I in Indices'Range loop Indices (I) := 6; end loop;
         Check ("2.3 Max allowed indices (32)", Bit_Sampling_Hash (Data, Indices) = 16#FFFF_FFFF#);
      end;
   end;

   --  TEST 3 — Bit_Sampling_Hash Exceptions
   Put_Line ("TEST 3 — Bit_Sampling_Hash Exceptions");
   declare
      Data  : constant Bit_Vector := [True, False];
      Empty : constant Index_Array (1 .. 0) := [others => 1];
   begin
      begin
         declare Dummy : Hash_Value := Bit_Sampling_Hash (Data, Empty); begin Check ("3.1 Empty indices", False); end;
      exception
         when Empty_Input => Check ("3.1 Caught Empty_Input", True);
      end;
      
      begin
         declare Dummy : Hash_Value := Bit_Sampling_Hash (Data, [1 => 3]); begin Check ("3.2 Invalid index", False); end;
      exception
         when Invalid_Index => Check ("3.2 Caught Invalid_Index", True);
      end;

      begin
         declare 
            Large : constant Index_Array (1 .. 33) := [others => 1];
            Dummy : Hash_Value := Bit_Sampling_Hash (Data, Large); 
         begin Check ("3.3 Dimension mismatch", False); end;
      exception
         when Dimension_Mismatch => Check ("3.3 Caught Dimension_Mismatch", True);
      end;
   end;

   --  TEST 4 — Min_Hash Single Item
   Put_Line ("TEST 4 — Min_Hash Single Item");
   declare
      Data : constant Integer_Array := [1 => 42];
      H1   : constant Hash_Value := Min_Hash (Data, 10);
      H2   : constant Hash_Value := Min_Hash (Data, 20);
      H3   : constant Hash_Value := Min_Hash (Data, 10);
   begin
      Check ("4.1 Same seed -> Same Hash", H1 = H3);
      Check ("4.2 Diff seed -> Diff Hash", H1 /= H2);
      Check ("4.3 Hash boundary stability", H1 > 0); 
   end;

   --  TEST 5 — Min_Hash Multiple Items
   Put_Line ("TEST 5 — Min_Hash Multiple Items");
   declare
      S1 : constant Integer_Array := [1, 2, 3, 4, 5];
      S2 : constant Integer_Array := [5, 4, 3, 2, 1];
      S3 : constant Integer_Array := [1, 2, 3];
      M1 : constant Hash_Value := Min_Hash (S1, 100);
      M2 : constant Hash_Value := Min_Hash (S2, 100);
      M3 : constant Hash_Value := Min_Hash (S3, 100);
   begin
      Check ("5.1 Order independence A", M1 = M2);
      Check ("5.2 Subset relation logic", M1 <= M3); -- MinHash of superset is <= subset
      Check ("5.3 Consistent mapping", Min_Hash (S1, 200) = Min_Hash (S2, 200));
   end;

   --  TEST 6 — Min_Hash_Signature Generation
   Put_Line ("TEST 6 — Min_Hash_Signature");
   declare
      Data_A : constant Integer_Array := [10, 20, 30];
      Data_B : constant Integer_Array := [10, 20, 30];
      Data_C : constant Integer_Array := [40, 50, 60];
      Seeds  : constant Hash_Array    := [1, 2, 3, 4, 5];
      Sig_A  : constant Hash_Array := Min_Hash_Signature (Data_A, Seeds);
      Sig_B  : constant Hash_Array := Min_Hash_Signature (Data_B, Seeds);
      Sig_C  : constant Hash_Array := Min_Hash_Signature (Data_C, Seeds);
   begin
      Check ("6.1 Correct length", Sig_A'Length = 5);
      Check ("6.2 Identical inputs -> identical signatures", Sig_A = Sig_B);
      Check ("6.3 Different inputs -> different signatures", Sig_A /= Sig_C);
   end;

   --  TEST 7 — Min_Hash Exceptions
   Put_Line ("TEST 7 — Min_Hash Exceptions");
   declare
      Empty_Data  : constant Integer_Array (1 .. 0) := [others => 0];
      Empty_Seeds : constant Hash_Array (1 .. 0) := [others => 0];
   begin
      begin
         declare Dummy : Hash_Value := Min_Hash (Empty_Data, 1); begin Check ("7.1 Empty data min hash", False); end;
      exception
         when Empty_Input => Check ("7.1 Caught Empty_Input (Min_Hash)", True);
      end;

      begin
         declare Dummy : Hash_Array := Min_Hash_Signature (Empty_Data, [1 => 1]); begin Check ("7.2 Empty data sig", False); end;
      exception
         when Empty_Input => Check ("7.2 Caught Empty_Input (Data)", True);
      end;

      begin
         declare Dummy : Hash_Array := Min_Hash_Signature ([1 => 1], Empty_Seeds); begin Check ("7.3 Empty seeds sig", False); end;
      exception
         when Empty_Input => Check ("7.3 Caught Empty_Input (Seeds)", True);
      end;
   end;

   --  TEST 8 — Jaccard Estimation Logic
   Put_Line ("TEST 8 — Jaccard Estimation Logic");
   declare
      Sig_A : constant Hash_Array := [1, 2, 3, 4];
      Sig_B : constant Hash_Array := [1, 2, 3, 4];
      Sig_C : constant Hash_Array := [9, 8, 7, 6];
      Sig_D : constant Hash_Array := [1, 2, 99, 100];
   begin
      Check ("8.1 Identical -> 1.0", Estimate_Jaccard_Similarity (Sig_A, Sig_B) = 1.0);
      Check ("8.2 Disjoint -> 0.0", Estimate_Jaccard_Similarity (Sig_A, Sig_C) = 0.0);
      Check ("8.3 Half overlap -> 0.5", Estimate_Jaccard_Similarity (Sig_A, Sig_D) = 0.5);
   end;

   --  TEST 9 — Jaccard Exceptions
   Put_Line ("TEST 9 — Jaccard Exceptions");
   declare
      Empty : constant Hash_Array (1 .. 0) := [others => 0];
      Valid : constant Hash_Array (1 .. 1) := [others => 1];
      Long  : constant Hash_Array (1 .. 2) := [others => 2];
   begin
      begin
         declare Dummy : Long_Float := Estimate_Jaccard_Similarity (Empty, Valid); begin Check ("9.1 Empty Sig A", False); end;
      exception
         when Empty_Input => Check ("9.1 Caught Empty_Input A", True);
      end;

      begin
         declare Dummy : Long_Float := Estimate_Jaccard_Similarity (Valid, Empty); begin Check ("9.2 Empty Sig B", False); end;
      exception
         when Empty_Input => Check ("9.2 Caught Empty_Input B", True);
      end;

      begin
         declare Dummy : Long_Float := Estimate_Jaccard_Similarity (Valid, Long); begin Check ("9.3 Dimension mismatch", False); end;
      exception
         when Dimension_Mismatch => Check ("9.3 Caught Dimension_Mismatch", True);
      end;
   end;

   --  TEST 10 — Random Projection Logic
   Put_Line ("TEST 10 — Random Projection Logic");
   declare
      Vec_A : constant Float_Vector := [1.0, 1.0];
      Vec_B : constant Float_Vector := [-1.0, -1.0];
      Vec_C : constant Float_Vector := [-1.0, 1.0];
   begin
      Check ("10.1 Same direction (>0)", Random_Projection_Hash (Vec_A, Vec_A));
      Check ("10.2 Opposite direction (<0)", not Random_Projection_Hash (Vec_A, Vec_B));
      Check ("10.3 Orthogonal (==0)", not Random_Projection_Hash (Vec_A, Vec_C));
   end;

   --  TEST 11 — Random Projection Edge Cases & Exceptions
   Put_Line ("TEST 11 — Random Projection Edge Cases");
   declare
      Empty : constant Float_Vector (1 .. 0) := [others => 0.0];
      Valid : constant Float_Vector (1 .. 2) := [1.0, 1.0];
      Small : constant Float_Vector (1 .. 2) := [1.0e-15, 1.0e-15];
   begin
      Check ("11.1 Tiny positive float", Random_Projection_Hash (Valid, Small));
      
      begin
         declare Dummy : Boolean := Random_Projection_Hash (Empty, Valid); begin Check ("11.2 Empty Data", False); end;
      exception
         when Empty_Input => Check ("11.2 Caught Empty_Input", True);
      end;

      begin
         declare Dummy : Boolean := Random_Projection_Hash (Valid, [1 => 1.0]); begin Check ("11.3 Dimension mismatch", False); end;
      exception
         when Dimension_Mismatch => Check ("11.3 Caught Dimension_Mismatch", True);
      end;
   end;

   --  TEST 12 — Cosine Signature Generation
   Put_Line ("TEST 12 — Cosine Signature Generation");
   declare
      Data_A : constant Float_Vector := [1.0, 0.0, 0.0];
      Data_B : constant Float_Vector := [-1.0, 0.0, 0.0];
      Matrix : constant Float_Matrix := [[1.0, 1.0, 1.0],
                                         [-1.0, 1.0, -1.0]];
      Sig_A  : constant Bit_Vector := Cosine_Signature (Data_A, Matrix);
      Sig_B  : constant Bit_Vector := Cosine_Signature (Data_B, Matrix);
   begin
      Check ("12.1 Correct length", Sig_A'Length = 2);
      Check ("12.2 Output consistency", Sig_A (1) = True and Sig_A (2) = False);
      Check ("12.3 Opposing vectors have flipped sigs", Sig_A (1) = not Sig_B (1));
   end;

   --  TEST 13 — Cosine Signature Exceptions
   Put_Line ("TEST 13 — Cosine Signature Exceptions");
   declare
      Valid_D : constant Float_Vector := [1.0, 2.0];
      Empty_D : constant Float_Vector (1 .. 0) := [others => 0.0];
      Valid_M : constant Float_Matrix := [[1.0, 1.0], [2.0, 2.0]];
      Empty_M : constant Float_Matrix (1 .. 0, 1 .. 2) := [others => [others => 0.0]];
      Bad_M   : constant Float_Matrix := [[1.0, 1.0, 1.0], [2.0, 2.0, 2.0]];
   begin
      begin
         declare Dummy : Bit_Vector := Cosine_Signature (Empty_D, Valid_M); begin Check ("13.1 Empty Data", False); end;
      exception
         when Empty_Input => Check ("13.1 Caught Empty_Input Data", True);
      end;

      begin
         declare Dummy : Bit_Vector := Cosine_Signature (Valid_D, Empty_M); begin Check ("13.2 Empty Matrix", False); end;
      exception
         when Empty_Input => Check ("13.2 Caught Empty_Input Matrix", True);
      end;

      begin
         declare Dummy : Bit_Vector := Cosine_Signature (Valid_D, Bad_M); begin Check ("13.3 Dimension mismatch", False); end;
      exception
         when Dimension_Mismatch => Check ("13.3 Caught Dimension_Mismatch", True);
      end;
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
