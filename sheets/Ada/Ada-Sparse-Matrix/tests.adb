--  Standalone test suite for Sparse_Matrix (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Sparse_Matrix; use Sparse_Matrix;

procedure Tests is

   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check
     (Condition : Boolean;
      Message   : String)
   is
   begin
      if Condition then
         Pass_Count := Pass_Count + 1;
         Ada.Text_IO.Put_Line ("  PASS: " & Message);
      else
         Fail_Count := Fail_Count + 1;
         Ada.Text_IO.Put_Line ("  FAIL: " & Message);
      end if;
   end Check;

   procedure Section (Title : String) is
   begin
      Ada.Text_IO.New_Line;
      Ada.Text_IO.Put_Line ("=== " & Title & " ===");
   end Section;

begin
   Ada.Text_IO.Put_Line ("Sparse_Matrix test suite");
   Ada.Text_IO.Put_Line ("========================");

   ---------------------------------------------------------------------
   Section ("1. Caps / density / empty / Get-Set dense");
   ---------------------------------------------------------------------
   declare
      Z  : constant Dense_Matrix := Zero_Dense (0, 0);
      Z3 : Dense_Matrix := Zero_Dense (3, 3);
      V0 : constant Vector := Zero_Vector (0);
      V4 : constant Vector := Zero_Vector (4);
   begin
      Check (Dim'Last = 64, "Max_N / Dim last = 64");
      Check (Nnz_Count'Last = 512, "Max_Nnz / Nnz_Count last = 512");
      Check (Z'Length (1) = 0 and then Z'Length (2) = 0, "Zero_Dense 0x0");
      Check (V0'Length = 0, "Zero_Vector 0");
      Check (V4'Length = 4 and then Near (V4 (1), 0.0), "Zero_Vector 4");
      Check (Count_Nnz (Z3) = 0, "Count_Nnz zeros");
      Check (Near (Density (Z3), 0.0), "Density zeros");
      Check (Near (Sparsity (Z3), 1.0), "Sparsity zeros");
      Check (Near (Density (0, 3, 3), 0.0), "Density helper 0");
      Check (Near (Sparsity (3, 3, 3), 1.0 - 1.0 / 3.0), "Sparsity helper");
      Set (Z3, 1, 2, 5.0);
      Set (Z3, 3, 3, -1.0);
      Check (Near (Get (Z3, 1, 2), 5.0), "Get/Set dense");
      Check (Count_Nnz (Z3) = 2, "Count_Nnz after Set");
      Check (Near (Density (Z3), 2.0 / 9.0), "Density 2/9");
   end;

   ---------------------------------------------------------------------
   Section ("2. From_Dense / To_Dense / COO Get");
   ---------------------------------------------------------------------
   declare
      A : Dense_Matrix := Zero_Dense (3, 3);
      C : COO;
      D : Dense_Matrix (1 .. 3, 1 .. 3);
   begin
      Set (A, 1, 1, 1.0);
      Set (A, 1, 3, 2.0);
      Set (A, 2, 2, 3.0);
      Set (A, 3, 1, 4.0);
      C := From_Dense (A);
      Check (C.Nnz = 4, "From_Dense nnz");
      Check (C.Rows = 3 and then C.Cols = 3, "From_Dense dims");
      Check (Near (Get (C, 1, 3), 2.0), "COO Get (1,3)");
      Check (Near (Get (C, 2, 1), 0.0), "COO Get missing");
      D := To_Dense (C);
      Check (Mat_Near (A, D), "To_Dense round-trip dense");
      Check (Near (Density (C), 4.0 / 9.0), "COO Density");
      Check (Near (Sparsity (C), 1.0 - 4.0 / 9.0), "COO Sparsity");
   end;

   ---------------------------------------------------------------------
   Section ("3. COO -> CSR round-trip / Is_Valid / Get");
   ---------------------------------------------------------------------
   declare
      A   : Dense_Matrix := Zero_Dense (4, 4);
      M_Coo : COO;
      Sr  : CSR;
      Back : COO;
      D1, D2 : Dense_Matrix (1 .. 4, 1 .. 4);
   begin
      Set (A, 1, 1, 10.0);
      Set (A, 1, 4, 1.0);
      Set (A, 2, 2, 20.0);
      Set (A, 3, 1, 3.0);
      Set (A, 3, 3, 30.0);
      Set (A, 4, 4, 40.0);
      M_Coo := From_Dense (A);
      Sr  := To_CSR (M_Coo);
      Check (Is_Valid_CSR (Sr), "Is_Valid_CSR");
      Check (Sr.Nnz = 6, "CSR nnz");
      Check (Sr.Row_Ptr (1) = 1, "Row_Ptr(1)=1");
      Check (Sr.Row_Ptr (5) = 7, "Row_Ptr(Rows+1)=Nnz+1");
      Check (Near (Get (Sr, 3, 1), 3.0), "CSR Get");
      Check (Near (Get (Sr, 2, 4), 0.0), "CSR Get zero");
      Back := To_COO (Sr);
      D1 := To_Dense (M_Coo);
      D2 := To_Dense (Sr);
      Check (Mat_Near (D1, D2), "COO->CSR densifies equal");
      Check (Mat_Near (A, To_Dense (Back)), "CSR->COO->dense");
      Check (Near (Density (Sr), 6.0 / 16.0), "CSR Density");
   end;

   ---------------------------------------------------------------------
   Section ("4. COO -> CSC / CSR <-> CSC");
   ---------------------------------------------------------------------
   declare
      A  : Dense_Matrix := Zero_Dense (3, 4);
      Co : COO;
      Sc : CSC;
      Sr : CSR;
   begin
      Set (A, 1, 2, 1.0);
      Set (A, 2, 1, 2.0);
      Set (A, 2, 4, 3.0);
      Set (A, 3, 3, 4.0);
      Co := From_Dense (A);
      Sc := To_CSC (Co);
      Check (Is_Valid_CSC (Sc), "Is_Valid_CSC");
      Check (Sc.Nnz = 4, "CSC nnz");
      Check (Sc.Col_Ptr (1) = 1, "Col_Ptr(1)=1");
      Check (Sc.Col_Ptr (5) = 5, "Col_Ptr(Cols+1)");
      Check (Near (Get (Sc, 2, 4), 3.0), "CSC Get");
      Check (Mat_Near (A, To_Dense (Sc)), "CSC To_Dense");
      Sr := To_CSR (Sc);
      Check (Is_Valid_CSR (Sr), "CSC->CSR valid");
      Check (Mat_Near (A, To_Dense (Sr)), "CSC->CSR dense");
      Sc := To_CSC (Sr);
      Check (Mat_Near (A, To_Dense (Sc)), "CSR->CSC dense");
   end;

   ---------------------------------------------------------------------
   Section ("5. Duplicate coalesce in To_CSR");
   ---------------------------------------------------------------------
   declare
      Co : COO (3, 2, 2);
      Sr : CSR;
   begin
      Co.Entries (1) := (1, 1, 1.0);
      Co.Entries (2) := (1, 1, 2.0);  -- duplicate
      Co.Entries (3) := (2, 2, 5.0);
      Sr := To_CSR (Co);
      Check (Sr.Nnz = 2, "coalesce nnz");
      Check (Near (Get (Sr, 1, 1), 3.0), "coalesce sum");
      Check (Near (Get (Sr, 2, 2), 5.0), "coalesce other");
   end;

   ---------------------------------------------------------------------
   Section ("6. SpMV_CSR / CSC / COO vs dense");
   ---------------------------------------------------------------------
   declare
      A  : Dense_Matrix := Zero_Dense (3, 3);
      X  : constant Vector := [1.0, 2.0, 3.0];
      Yd, Ys, Yc, Yo : Vector (1 .. 3);
      Co : COO;
      Sr : CSR;
      Sc : CSC;
   begin
      --  [[2,0,1],[0,3,0],[4,0,5]]
      Set (A, 1, 1, 2.0); Set (A, 1, 3, 1.0);
      Set (A, 2, 2, 3.0);
      Set (A, 3, 1, 4.0); Set (A, 3, 3, 5.0);
      Yd := Dense_Mat_Vec (A, X);
      Check (Near (Yd (1), 2.0 * 1.0 + 1.0 * 3.0), "dense y1");
      Check (Near (Yd (2), 3.0 * 2.0), "dense y2");
      Check (Near (Yd (3), 4.0 * 1.0 + 5.0 * 3.0), "dense y3");
      Co := From_Dense (A);
      Sr := To_CSR (Co);
      Sc := To_CSC (Co);
      Ys := SpMV_CSR (Sr, X);
      Yc := SpMV_CSC (Sc, X);
      Yo := SpMV_COO (Co, X);
      Check (Vec_Near (Yd, Ys), "SpMV_CSR = dense");
      Check (Vec_Near (Yd, Yc), "SpMV_CSC = dense");
      Check (Vec_Near (Yd, Yo), "SpMV_COO = dense");
   end;

   ---------------------------------------------------------------------
   Section ("7. SpMV rectangular + empty rows");
   ---------------------------------------------------------------------
   declare
      A  : Dense_Matrix := Zero_Dense (4, 2);
      X  : constant Vector := [10.0, -1.0];
      Co : COO;
      Sr : CSR;
   begin
      Set (A, 1, 1, 1.0);
      Set (A, 3, 2, 2.0);
      Set (A, 4, 1, 3.0);
      --  row 2 empty
      Co := From_Dense (A);
      Sr := To_CSR (Co);
      Check (Sr.Row_Ptr (2) = Sr.Row_Ptr (3), "empty row ptr");
      Check (Vec_Near (Dense_Mat_Vec (A, X), SpMV_CSR (Sr, X)),
             "rect SpMV_CSR");
      Check (Vec_Near (Dense_Mat_Vec (A, X), SpMV_CSC (To_CSC (Co), X)),
             "rect SpMV_CSC");
   end;

   ---------------------------------------------------------------------
   Section ("8. Diagonal / Identity / Tridiagonal builders");
   ---------------------------------------------------------------------
   declare
      D  : constant Vector := [2.0, 0.0, 5.0, 1.0];
      Co : constant COO := Diagonal (D);
      Sr : constant CSR := Diagonal_CSR (D);
      Id : constant CSR := Identity (3);
      Lo : constant Vector := [-1.0, -1.0, -1.0];
      Md : constant Vector := [2.0, 2.0, 2.0, 2.0];
      Up : constant Vector := [-1.0, -1.0, -1.0];
      Tr : constant CSR := Tridiagonal_CSR (Lo, Md, Up);
      X  : constant Vector := [1.0, 1.0, 1.0, 1.0];
      Ye : constant Vector := [1.0, 0.0, 0.0, 1.0];  -- Poisson Tx
   begin
      Check (Co.Nnz = 3, "Diagonal skips zero");
      Check (Co.Rows = 4, "Diagonal n");
      Check (Near (Get (Sr, 1, 1), 2.0), "Diagonal_CSR (1,1)");
      Check (Near (Get (Sr, 2, 2), 0.0), "Diagonal_CSR skipped 0");
      Check (Near (Get (Sr, 3, 3), 5.0), "Diagonal_CSR (3,3)");
      Check (Id.Nnz = 3, "Identity nnz");
      Check (Is_Valid_CSR (Id), "Identity valid");
      Check (Near (Get (Id, 2, 2), 1.0), "Identity diag");
      Check (Near (Get (Id, 1, 2), 0.0), "Identity off");
      Check (Vec_Near (SpMV_CSR (Id, [1.0, 2.0, 3.0]), [1.0, 2.0, 3.0]),
             "Identity SpMV");
      Check (Tr.Nnz = 10, "Tridiagonal nnz (4+3+3)");
      Check (Is_Valid_CSR (Tr), "Tridiagonal valid");
      Check (Vec_Near (SpMV_CSR (Tr, X), Ye), "Tridiagonal SpMV Poisson");
   end;

   ---------------------------------------------------------------------
   Section ("9. Random_COO fixed seed + SpMV");
   ---------------------------------------------------------------------
   declare
      R1 : constant COO := Random_COO (5, 5, 8, Seed => 42);
      R2 : constant COO := Random_COO (5, 5, 8, Seed => 42);
      R3 : constant COO := Random_COO (5, 5, 8, Seed => 99);
      Sr : constant CSR := To_CSR (R1);
      X  : constant Vector (1 .. 5) := [1.0, 2.0, 3.0, 4.0, 5.0];
      Same : Boolean := True;
   begin
      Check (R1.Nnz = 8, "Random nnz");
      Check (R1.Rows = 5, "Random dims");
      for K in 1 .. R1.Nnz loop
         if R1.Entries (K).Row /= R2.Entries (K).Row
           or else R1.Entries (K).Col /= R2.Entries (K).Col
           or else not Near (R1.Entries (K).Value, R2.Entries (K).Value)
         then
            Same := False;
         end if;
      end loop;
      Check (Same, "Random seed reproducible");
      Same := R1.Entries (1).Row = R3.Entries (1).Row
        and then R1.Entries (1).Col = R3.Entries (1).Col
        and then Near (R1.Entries (1).Value, R3.Entries (1).Value);
      Check (not Same, "different seed differs");
      Check (Is_Valid_CSR (Sr), "Random CSR valid");
      Check (Vec_Near (Dense_Mat_Vec (To_Dense (R1), X), SpMV_CSR (Sr, X)),
             "Random SpMV_CSR");
      Check (Vec_Near (Dense_Mat_Vec (To_Dense (R1), X),
                       SpMV_CSC (To_CSC (R1), X)),
             "Random SpMV_CSC");
   end;

   ---------------------------------------------------------------------
   Section ("10. Empty / edge cases");
   ---------------------------------------------------------------------
   declare
      E0 : constant COO := From_Dense (Zero_Dense (0, 0));
      E3 : constant COO := From_Dense (Zero_Dense (3, 2));
      S0 : constant CSR := To_CSR (E0);
      S3 : constant CSR := To_CSR (E3);
      C3 : constant CSC := To_CSC (E3);
      Id0 : constant CSR := Identity (0);
   begin
      Check (E0.Nnz = 0, "empty 0x0 nnz");
      Check (S0.Nnz = 0 and then S0.Rows = 0, "CSR empty 0");
      Check (E3.Nnz = 0, "all-zero dense -> COO nnz 0");
      Check (Is_Valid_CSR (S3), "CSR all-zero valid");
      Check (S3.Row_Ptr (1) = 1 and then S3.Row_Ptr (4) = 1, "zero Row_Ptr");
      Check (Is_Valid_CSC (C3), "CSC all-zero valid");
      Check (Id0.Nnz = 0, "Identity 0");
      Check (SpMV_CSR (S3, Zero_Vector (2))'Length = 3, "SpMV zero matrix");
      Check (Vec_Near (SpMV_CSR (S3, [1.0, 2.0]), [0.0, 0.0, 0.0]),
             "SpMV zeros");
   end;

   ---------------------------------------------------------------------
   Section ("11. Taxonomy Format_Kind");
   ---------------------------------------------------------------------
   declare
      Impl : Natural := 0;
      Forth : Natural := 0;
   begin
      for F in Format_Kind loop
         if Implemented (F) then
            Impl := Impl + 1;
            Check (not Forthcoming (F), "Impl not Forthcoming " & F'Image);
         else
            Forth := Forth + 1;
            Check (Forthcoming (F), "Forthcoming " & F'Image);
         end if;
         Check (Format_Name (F)'Length > 0, "Format_Name non-empty");
      end loop;
      Check (Implemented (Coordinate_COO), "COO implemented");
      Check (Implemented (Compressed_Row_CSR), "CSR implemented");
      Check (Implemented (Compressed_Column_CSC), "CSC implemented");
      Check (Forthcoming (Diagonal_DIA), "DIA forthcoming");
      Check (Forthcoming (ELLPACK_ELL), "ELL forthcoming");
      Check (Forthcoming (Blocked_BSR), "Blocked forthcoming");
      Check (Impl = 3, "exactly 3 implemented formats");
      Check (Forth = 3, "exactly 3 forthcoming formats");
   end;

   ---------------------------------------------------------------------
   Section ("12. Larger SpMV / Near helpers / Vec_Near");
   ---------------------------------------------------------------------
   declare
      N  : constant := 8;
      A  : Dense_Matrix := Zero_Dense (N, N);
      X  : constant Vector :=
        [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0];
      Co : COO;
      Sr : CSR;
      Sc : CSC;
   begin
      for I in 1 .. N loop
         Set (A, I, I, 2.0);
         if I > 1 then
            Set (A, I, I - 1, -1.0);
         end if;
         if I < N then
            Set (A, I, I + 1, -1.0);
         end if;
      end loop;
      Co := From_Dense (A);
      Sr := To_CSR (Co);
      Sc := To_CSC (Co);
      Check (Co.Nnz = 8 + 7 + 7, "band8 nnz");
      Check (Vec_Near (Dense_Mat_Vec (A, X), SpMV_CSR (Sr, X)),
             "band SpMV_CSR");
      Check (Vec_Near (Dense_Mat_Vec (A, X), SpMV_CSC (Sc, X)),
             "band SpMV_CSC");
      Check (Vec_Near (Dense_Mat_Vec (A, X), SpMV_COO (Co, X)),
             "band SpMV_COO");
      Check (Mat_Near (A, To_Dense (To_CSR (To_COO (Sr)))),
             "CSR->COO->CSR dense");
      Check (Near (1.0, 1.0 + 1.0E-8, 1.0E-6), "Near tol");
      Check (not Near (1.0, 2.0), "Near reject");
      Check (Vec_Near ([1.0, 2.0], [1.0, 2.0]), "Vec_Near ok");
      Check (not Vec_Near ([1.0, 2.0], [1.0, 9.0]), "Vec_Near reject");
   end;

   ---------------------------------------------------------------------
   Section ("13. Unsorted COO input / rectangular Identity-ish");
   ---------------------------------------------------------------------
   declare
      Co : COO (4, 3, 3);
      Sr : CSR;
   begin
      --  deliberately unsorted / not row-major
      Co.Entries (1) := (3, 3, 9.0);
      Co.Entries (2) := (1, 2, 1.0);
      Co.Entries (3) := (2, 1, 2.0);
      Co.Entries (4) := (1, 1, 4.0);
      Sr := To_CSR (Co);
      Check (Is_Valid_CSR (Sr), "unsorted -> CSR valid");
      Check (Sr.Col_Ind (1) = 1 and then Sr.Col_Ind (2) = 2,
             "row1 cols sorted");
      Check (Near (Get (Sr, 3, 3), 9.0), "unsorted Get");
      Check (Vec_Near
               (SpMV_CSR (Sr, [1.0, 1.0, 1.0]),
                Dense_Mat_Vec (To_Dense (Co), [1.0, 1.0, 1.0])),
             "unsorted SpMV");
   end;

   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line
     ("Result: Pass_Count =" & Pass_Count'Image
      & "  Fail_Count =" & Fail_Count'Image);
   if Fail_Count = 0 and then Pass_Count >= 80 then
      Ada.Text_IO.Put_Line ("ALL PASSED");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   else
      Ada.Text_IO.Put_Line ("FAILED");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Tests;
