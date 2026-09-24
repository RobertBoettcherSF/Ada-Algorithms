--  Unit tests for package Schensted (row insertion / RSK / LIS)

with Ada.Text_IO;
with Schensted; use Schensted;

procedure Tests is
   use Ada.Text_IO;

   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Cond : Boolean; Label : String) is
   begin
      if Cond then
         Pass_Count := Pass_Count + 1;
      else
         Fail_Count := Fail_Count + 1;
         Put_Line ("FAIL: " & Label);
      end if;
   end Check;


   --  Build a tableau by successive Insert for expected-value checks
   --  when we assert shape/entries from a known P.

   function Row1 (T : Tableau) return Natural renames First_Row_Length;

   --------------------------------------------------------------------
   --  Individual test groups
   --------------------------------------------------------------------

   procedure Test_Empty is
      T : constant Tableau := Empty_Tableau;
   begin
      Check (Num_Rows (T) = 0, "empty rows");
      Check (Num_Boxes (T) = 0, "empty boxes");
      Check (First_Row_Length (T) = 0, "empty first row");
      Check (Is_Valid_Tableau (T), "empty is valid");
      Check (Image (T) = "(empty)", "empty image");
   end Test_Empty;

   procedure Test_Identity is
      W : constant Word := [1, 2, 3, 4, 5];
      P : constant Tableau := Insert_Word (W);
   begin
      Check (Is_Valid_Tableau (P), "id valid");
      Check (Num_Rows (P) = 1, "id one row");
      Check (Row_Length (P, 1) = 5, "id row len 5");
      Check (LIS_Length (W) = 5, "id LIS=5");
      Check (Element (P, 1, 1) = 1, "id e11");
      Check (Element (P, 1, 5) = 5, "id e15");
   end Test_Identity;

   procedure Test_Reverse is
      W : constant Word := [5, 4, 3, 2, 1];
      P : constant Tableau := Insert_Word (W);
   begin
      Check (Is_Valid_Tableau (P), "rev valid");
      Check (Num_Rows (P) = 5, "rev five rows");
      Check (First_Row_Length (P) = 1, "rev first row 1");
      Check (LIS_Length (W) = 1, "rev LIS=1");
      Check (Element (P, 1, 1) = 1, "rev e11=1");
      Check (Element (P, 5, 1) = 5, "rev e51=5");
      Check (Num_Boxes (P) = 5, "rev boxes");
   end Test_Reverse;

   procedure Test_Classic_2431 is
      --  w = 2 4 3 1 → P = [[1,3],[2],[4]], LIS = 2
      W : constant Word := [2, 4, 3, 1];
      P : constant Tableau := Insert_Word (W);
   begin
      Check (Is_Valid_Tableau (P), "2431 valid");
      Check (Num_Rows (P) = 3, "2431 rows");
      Check (Row_Length (P, 1) = 2, "2431 r1");
      Check (Row_Length (P, 2) = 1, "2431 r2");
      Check (Row_Length (P, 3) = 1, "2431 r3");
      Check (Element (P, 1, 1) = 1, "2431 e11");
      Check (Element (P, 1, 2) = 3, "2431 e12");
      Check (Element (P, 2, 1) = 2, "2431 e21");
      Check (Element (P, 3, 1) = 4, "2431 e31");
      Check (LIS_Length (W) = 2, "2431 LIS");
   end Test_Classic_2431;

   procedure Test_13542 is
      --  w = 1 3 5 4 2 → P = [[1,2,4],[3],[5]], LIS = 3
      W : constant Word := [1, 3, 5, 4, 2];
      P : constant Tableau := Insert_Word (W);
   begin
      Check (Is_Valid_Tableau (P), "13542 valid");
      Check (Row1 (P) = 3, "13542 first row");
      Check (Num_Rows (P) = 3, "13542 rows");
      Check (Element (P, 1, 1) = 1, "13542 e11");
      Check (Element (P, 1, 2) = 2, "13542 e12");
      Check (Element (P, 1, 3) = 4, "13542 e13");
      Check (Element (P, 2, 1) = 3, "13542 e21");
      Check (Element (P, 3, 1) = 5, "13542 e31");
      Check (LIS_Length (W) = 3, "13542 LIS");
   end Test_13542;

   procedure Test_Single is
      W : constant Word := [1 => 1];
      P : constant Tableau := Insert_Word (W);
   begin
      Check (Num_Boxes (P) = 1, "single box");
      Check (LIS_Length (W) = 1, "single LIS");
      Check (Element (P, 1, 1) = 1, "single entry");
      Check (Is_Valid_Tableau (P), "single valid");
   end Test_Single;

   procedure Test_Two_Asc is
      W : constant Word := [1, 2];
      P : constant Tableau := Insert_Word (W);
   begin
      Check (Row1 (P) = 2, "12 row");
      Check (Num_Rows (P) = 1, "12 rows");
      Check (LIS_Length (W) = 2, "12 LIS");
   end Test_Two_Asc;

   procedure Test_Two_Desc is
      W : constant Word := [2, 1];
      P : constant Tableau := Insert_Word (W);
   begin
      Check (Row1 (P) = 1, "21 row");
      Check (Num_Rows (P) = 2, "21 rows");
      Check (Element (P, 1, 1) = 1, "21 e11");
      Check (Element (P, 2, 1) = 2, "21 e21");
      Check (LIS_Length (W) = 1, "21 LIS");
   end Test_Two_Desc;

   procedure Test_3142 is
      --  3 1 4 2
      --  Insert 3: [[3]]
      --  Insert 1: bump 3 → [[1],[3]]
      --  Insert 4: [[1,4],[3]]
      --  Insert 2: bump 4 → [[1,2],[3],[4]]? 
      --    row1 [1,4]: leftmost >2 is 4 → [1,2], bump 4
      --    row2 [3]: leftmost >4? none → append → [3,4]
      --  P = [[1,2],[3,4]], LIS = 2 (e.g. 3,4 or 1,2 or 1,4)
      W : constant Word := [3, 1, 4, 2];
      P : constant Tableau := Insert_Word (W);
   begin
      Check (Is_Valid_Tableau (P), "3142 valid");
      Check (Row1 (P) = 2, "3142 r1");
      Check (Row_Length (P, 2) = 2, "3142 r2");
      Check (Num_Rows (P) = 2, "3142 rows");
      Check (Element (P, 1, 1) = 1, "3142 e11");
      Check (Element (P, 1, 2) = 2, "3142 e12");
      Check (Element (P, 2, 1) = 3, "3142 e13");
      Check (Element (P, 2, 2) = 4, "3142 e22");
      Check (LIS_Length (W) = 2, "3142 LIS");
   end Test_3142;

   procedure Test_2413 is
      --  2 4 1 3
      --  2: [[2]]
      --  4: [[2,4]]
      --  1: bump 2 → [[1,4],[2]]
      --  3: bump 4 → [[1,3],[2],[4]]? 
      --    row1 [1,4]: >3 is 4 → [1,3], bump 4
      --    row2 [2]: >4? none → [2,4]
      --  P = [[1,3],[2,4]], LIS=2
      W : constant Word := [2, 4, 1, 3];
      P : constant Tableau := Insert_Word (W);
   begin
      Check (Is_Valid_Tableau (P), "2413 valid");
      Check (Row1 (P) = 2, "2413 r1");
      Check (Element (P, 1, 1) = 1 and then Element (P, 1, 2) = 3, "2413 row1");
      Check (Element (P, 2, 1) = 2 and then Element (P, 2, 2) = 4, "2413 row2");
      Check (LIS_Length (W) = 2, "2413 LIS");
   end Test_2413;

   procedure Test_RSK_Recording is
      W : constant Word := [2, 4, 3, 1];
      P, Q : Tableau;
   begin
      Insert_Word_RSK (W, P, Q);
      Check (Is_Valid_Tableau (P), "RSK P valid");
      Check (Is_Valid_Tableau (Q), "RSK Q valid");
      Check (Shape_Equal (P, Q), "RSK same shape");
      Check (Equal (P, Insert_Word (W)), "RSK P matches Insert_Word");
      --  New boxes appear at steps: after each insert the new box location
      --  2 → (1,1) step1; 4 → (1,2) step2; 3 bumps → new at (2,1) step3;
      --  1 cascades → new at (3,1) step4
      Check (Element (Q, 1, 1) = 1, "Q11=1");
      Check (Element (Q, 1, 2) = 2, "Q12=2");
      Check (Element (Q, 2, 1) = 3, "Q21=3");
      Check (Element (Q, 3, 1) = 4, "Q31=4");
   end Test_RSK_Recording;

   procedure Test_RSK_Identity is
      W : constant Word := [1, 2, 3];
      P, Q : Tableau;
   begin
      Insert_Word_RSK (W, P, Q);
      Check (Shape_Equal (P, Q), "RSK id shape");
      Check (Element (Q, 1, 1) = 1, "RSK id Q1");
      Check (Element (Q, 1, 2) = 2, "RSK id Q2");
      Check (Element (Q, 1, 3) = 3, "RSK id Q3");
   end Test_RSK_Identity;

   procedure Test_Incremental_Insert is
      T : Tableau := Empty_Tableau;
   begin
      T := Insert (T, 3);
      T := Insert (T, 1);
      T := Insert (T, 2);
      --  Same as word 3,1,2 which is perm of 1..3
      Check (Equal (T, Insert_Word ([3, 1, 2])), "incremental vs word");
      Check (Is_Valid_Tableau (T), "incremental valid");
      Check (LIS_Length ([3, 1, 2]) = First_Row_Length (T), "inc LIS");
   end Test_Incremental_Insert;

   procedure Test_Equal_and_Shape is
      A : constant Tableau := Insert_Word ([1, 2, 3]);
      B : constant Tableau := Insert_Word ([1, 2, 3]);
      C : constant Tableau := Insert_Word ([3, 2, 1]);
   begin
      Check (Equal (A, B), "equal same");
      Check (not Equal (A, C), "equal different");
      Check (not Shape_Equal (A, C), "shape different");
      Check (Shape_equal (A, B), "shape same");
   end Test_Equal_and_Shape;

   procedure Test_Longer_Perm is
      --  6 2 4 1 5 3 — compute LIS via first row
      W : constant Word := [6, 2, 4, 1, 5, 3];
      P : constant Tableau := Insert_Word (W);
      L : constant Natural := LIS_Length (W);
   begin
      Check (Is_Valid_Tableau (P), "624153 valid");
      Check (Num_Boxes (P) = 6, "624153 boxes");
      Check (L = First_Row_Length (P), "624153 LIS link");
      Check (L >= 1 and then L <= 6, "624153 LIS range");
      --  Known increasing: 2,4,5 length 3; 2,4,5 or 2,1,5 no; 2,4,5 = 3
      --  2,4,5 and 2,4,3 no — LIS is 3 (e.g. 2,4,5)
      Check (L = 3, "624153 LIS=3");
   end Test_Longer_Perm;

   procedure Test_N8_Identity is
      W : constant Word := [1, 2, 3, 4, 5, 6, 7, 8];
   begin
      Check (LIS_Length (W) = 8, "n8 id LIS");
      Check (Num_Rows (Insert_Word (W)) = 1, "n8 id rows");
   end Test_N8_Identity;

   procedure Test_N8_Reverse is
      W : constant Word := [8, 7, 6, 5, 4, 3, 2, 1];
   begin
      Check (LIS_Length (W) = 1, "n8 rev LIS");
      Check (Num_Rows (Insert_Word (W)) = 8, "n8 rev rows");
   end Test_N8_Reverse;

   procedure Test_Invalids is
   begin
      begin
         declare
            W : Word (1 .. 0);
            T : Tableau;
         begin
            T := Insert_Word (W);
            pragma Unreferenced (T);
            Fail_Count := Fail_Count + 1;
            Put_Line ("FAIL: empty word");
         end;
      exception
         when Invalid_Argument =>
            Pass_Count := Pass_Count + 1;
      end;

      begin
         declare
            T : constant Tableau := Insert_Word ([1, 2, 2]);
         begin
            pragma Unreferenced (T);
            Fail_Count := Fail_Count + 1;
            Put_Line ("FAIL: duplicate");
         end;
      exception
         when Invalid_Argument =>
            Pass_Count := Pass_Count + 1;
      end;

      begin
         declare
            T : constant Tableau := Insert_Word ([1, 2, 4]);
         begin
            pragma Unreferenced (T);
            Fail_Count := Fail_Count + 1;
            Put_Line ("FAIL: out of range");
         end;
      exception
         when Invalid_Argument =>
            Pass_Count := Pass_Count + 1;
      end;

      begin
         declare
            T : constant Tableau := Insert_Word ([1, 3]);
         begin
            pragma Unreferenced (T);
            Fail_Count := Fail_Count + 1;
            Put_Line ("FAIL: gap");
         end;
      exception
         when Invalid_Argument =>
            Pass_Count := Pass_Count + 1;
      end;

      begin
         declare
            U : constant Tableau := Insert_Word ([1, 2]);
            Y : constant Positive := Element (U, 2, 1);
         begin
            Fail_Count := Fail_Count + 1;
            Put_Line ("FAIL: bad element" & Positive'Image (Y));
         end;
      exception
         when Invalid_Argument =>
            Pass_Count := Pass_Count + 1;
      end;

      begin
         declare
            T : constant Tableau := Insert_Word ([2, 2]);
         begin
            pragma Unreferenced (T);
            Fail_Count := Fail_Count + 1;
            Put_Line ("FAIL: dup2");
         end;
      exception
         when Invalid_Argument =>
            Pass_Count := Pass_Count + 1;
      end;

      begin
         declare
            --  Zero is not Positive, so use a value that fails uniqueness
            --  via Insert_Word_RSK as well
            P, Q : Tableau;
         begin
            Insert_Word_RSK ([1, 1], P, Q);
            pragma Unreferenced (P, Q);
            Fail_Count := Fail_Count + 1;
            Put_Line ("FAIL: RSK dup");
         end;
      exception
         when Invalid_Argument =>
            Pass_Count := Pass_Count + 1;
      end;
   end Test_Invalids;

   procedure Test_Row_Length_OOB is
      T : constant Tableau := Insert_Word ([1, 2]);
   begin
      Check (Row_Length (T, 99) = 0, "row length oob");
   end Test_Row_Length_OOB;

   procedure Test_Permutation_4321_Partial is
      W : constant Word := [4, 3, 2, 1];
      P : constant Tableau := Insert_Word (W);
   begin
      Check (Is_Valid_Tableau (P), "4321 valid");
      Check (First_Row_Length (P) = 1, "4321 LIS");
      Check (Element (P, 1, 1) = 1, "4321 top");
      Check (Element (P, 4, 1) = 4, "4321 bottom");
   end Test_Permutation_4321_Partial;

   procedure Test_231 is
      --  2 3 1 → [[1,3],[2]], LIS=2
      W : constant Word := [2, 3, 1];
      P : constant Tableau := Insert_Word (W);
   begin
      Check (Row1 (P) = 2, "231 r1");
      Check (Element (P, 1, 1) = 1, "231 e11");
      Check (Element (P, 1, 2) = 3, "231 e12");
      Check (Element (P, 2, 1) = 2, "231 e21");
   end Test_231;

   procedure Test_312 is
      --  3 1 2 → [[1,2],[3]], LIS=2
      W : constant Word := [3, 1, 2];
      P : constant Tableau := Insert_Word (W);
   begin
      Check (Row1 (P) = 2, "312 r1");
      Check (Element (P, 1, 1) = 1 and then Element (P, 1, 2) = 2, "312 row1");
      Check (Element (P, 2, 1) = 3, "312 e21");
   end Test_312;

   procedure Test_All_S3_LIS is
      --  All 6 perms of S3: LIS values
   begin
      Check (LIS_Length ([1, 2, 3]) = 3, "S3 123");
      Check (LIS_Length ([1, 3, 2]) = 2, "S3 132");
      Check (LIS_Length ([2, 1, 3]) = 2, "S3 213");
      Check (LIS_Length ([2, 3, 1]) = 2, "S3 231");
      Check (LIS_Length ([3, 1, 2]) = 2, "S3 312");
      Check (LIS_Length ([3, 2, 1]) = 1, "S3 321");
   end Test_All_S3_LIS;

begin
   Test_Empty;
   Test_Identity;
   Test_Reverse;
   Test_Classic_2431;
   Test_13542;
   Test_Single;
   Test_Two_Asc;
   Test_Two_Desc;
   Test_3142;
   Test_2413;
   Test_RSK_Recording;
   Test_RSK_Identity;
   Test_Incremental_Insert;
   Test_Equal_and_Shape;
   Test_Longer_Perm;
   Test_N8_Identity;
   Test_N8_Reverse;
   Test_Invalids;
   Test_Row_Length_OOB;
   Test_Permutation_4321_Partial;
   Test_231;
   Test_312;
   Test_All_S3_LIS;

   declare
      function Trim_Img (N : Natural) return String is
         S : constant String := Natural'Image (N);
      begin
         if S'Length > 0 and then S (S'First) = ' ' then
            return S (S'First + 1 .. S'Last);
         end if;
         return S;
      end Trim_Img;
   begin
      Put_Line
        ("Results: " & Trim_Img (Pass_Count) & " PASS, " &
         Trim_Img (Fail_Count) & " FAIL");
   end;

   if Fail_Count /= 0 then
      raise Program_Error with "test failures";
   end if;
end Tests;
