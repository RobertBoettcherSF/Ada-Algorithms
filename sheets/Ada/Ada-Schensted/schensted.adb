--  Schensted row insertion implementation

package body Schensted is

   --------------------------------------------------------------------
   --  Local helpers
   --------------------------------------------------------------------

   procedure Validate_Permutation (W : Word) is
      N     : constant Natural := W'Length;
      Seen  : array (1 .. Max_N) of Boolean := [others => False];
      V     : Positive;
   begin
      if N = 0 or else N > Max_N then
         raise Invalid_Argument;
      end if;
      for I in W'Range loop
         V := W (I);
         if V > N or else Seen (V) then
            raise Invalid_Argument;
         end if;
         Seen (V) := True;
      end loop;
      --  Distinct values in 1 .. N imply the set is exactly {1..N}.
   end Validate_Permutation;

   --  Row-insert X into T; return the (Row, Col) of the newly created box
   --  (1-based). Used by RSK to place the recording entry.
   procedure Row_Insert
     (T          : in out Tableau;
      X          : Positive;
      New_Row    : out Positive;
      New_Col    : out Positive)
   is
      Current : Positive := X;
      R       : Positive := 1;
      Pos     : Natural;
      Bumped  : Positive;
      Found   : Boolean;
   begin
      loop
         --  Ensure row R exists in the length array sense.
         if R > Max_N then
            raise Invalid_Argument;
         end if;

         if R > T.Row_Count then
            --  Append a brand-new row containing only Current.
            T.Row_Count := R;
            T.Lengths (R) := 1;
            T.Data (R)(1) := Current;
            New_Row := R;
            New_Col := 1;
            return;
         end if;

         --  Find leftmost entry strictly greater than Current.
         Found := False;
         Pos := 0;
         for C in 1 .. T.Lengths (R) loop
            if T.Data (R)(C) > Current then
               Found := True;
               Pos := C;
               exit;
            end if;
         end loop;

         if not Found then
            --  Append to this row.
            if T.Lengths (R) >= Max_N then
               raise Invalid_Argument;
            end if;
            T.Lengths (R) := T.Lengths (R) + 1;
            Pos := T.Lengths (R);
            T.Data (R)(Pos) := Current;
            New_Row := R;
            New_Col := Pos;
            return;
         else
            --  Bump and cascade to the next row.
            Bumped := T.Data (R)(Pos);
            T.Data (R)(Pos) := Current;
            Current := Bumped;
            R := R + 1;
         end if;
      end loop;
   end Row_Insert;

   --------------------------------------------------------------------
   --  Public API
   --------------------------------------------------------------------

   function Empty_Tableau return Tableau is
      T : Tableau;
   begin
      return T;
   end Empty_Tableau;

   function Insert (T : Tableau; X : Positive) return Tableau is
      Result  : Tableau := T;
      New_Row : Positive;
      New_Col : Positive;
   begin
      if Num_Boxes (Result) >= Max_N then
         raise Invalid_Argument;
      end if;
      Row_Insert (Result, X, New_Row, New_Col);
      return Result;
   end Insert;

   function Insert_Word (W : Word) return Tableau is
      T       : Tableau := Empty_Tableau;
      New_Row : Positive;
      New_Col : Positive;
   begin
      Validate_Permutation (W);
      for I in W'Range loop
         Row_Insert (T, W (I), New_Row, New_Col);
      end loop;
      return T;
   end Insert_Word;

   procedure Insert_Word_RSK
     (W : Word; P : out Tableau; Q : out Tableau)
   is
      New_Row : Positive;
      New_Col : Positive;
      Step    : Positive;
   begin
      Validate_Permutation (W);
      P := Empty_Tableau;
      Q := Empty_Tableau;
      Step := 1;
      for I in W'Range loop
         Row_Insert (P, W (I), New_Row, New_Col);
         --  Grow Q's shape to match; place the step number.
         if New_Row > Q.Row_Count then
            Q.Row_Count := New_Row;
         end if;
         if New_Col > Q.Lengths (New_Row) then
            Q.Lengths (New_Row) := New_Col;
         end if;
         Q.Data (New_Row)(New_Col) := Step;
         Step := Step + 1;
      end loop;
   end Insert_Word_RSK;

   function Num_Rows (T : Tableau) return Natural is
   begin
      return T.Row_Count;
   end Num_Rows;

   function Num_Boxes (T : Tableau) return Natural is
      Total : Natural := 0;
   begin
      for R in 1 .. T.Row_Count loop
         Total := Total + T.Lengths (R);
      end loop;
      return Total;
   end Num_Boxes;

   function Row_Length (T : Tableau; R : Positive) return Natural is
   begin
      if R > T.Row_Count then
         return 0;
      end if;
      return T.Lengths (R);
   end Row_Length;

   function Element (T : Tableau; R, C : Positive) return Positive is
   begin
      if R > T.Row_Count or else C > T.Lengths (R) then
         raise Invalid_Argument;
      end if;
      return T.Data (R)(C);
   end Element;

   function First_Row_Length (T : Tableau) return Natural is
   begin
      return Row_Length (T, 1);
   end First_Row_Length;

   function LIS_Length (W : Word) return Natural is
   begin
      return First_Row_Length (Insert_Word (W));
   end LIS_Length;

   function Is_Valid_Tableau (T : Tableau) return Boolean is
   begin
      if T.Row_Count > Max_N then
         return False;
      end if;

      --  Shape must be a partition: weakly decreasing row lengths,
      --  each length in 0 .. Max_N, and trailing rows unused.
      for R in 1 .. T.Row_Count loop
         if T.Lengths (R) = 0 or else T.Lengths (R) > Max_N then
            return False;
         end if;
         if R > 1 and then T.Lengths (R) > T.Lengths (R - 1) then
            return False;
         end if;
      end loop;
      for R in T.Row_Count + 1 .. Max_N loop
         if T.Lengths (R) /= 0 then
            return False;
         end if;
      end loop;

      --  Strictly increasing rows.
      for R in 1 .. T.Row_Count loop
         for C in 1 .. T.Lengths (R) - 1 loop
            if T.Data (R)(C) >= T.Data (R)(C + 1) then
               return False;
            end if;
         end loop;
      end loop;

      --  Strictly increasing columns (where both entries exist).
      for R in 1 .. T.Row_Count - 1 loop
         for C in 1 .. T.Lengths (R + 1) loop
            if T.Data (R)(C) >= T.Data (R + 1)(C) then
               return False;
            end if;
         end loop;
      end loop;

      return True;
   end Is_Valid_Tableau;

   function Shape_Equal (A, B : Tableau) return Boolean is
   begin
      if A.Row_Count /= B.Row_Count then
         return False;
      end if;
      for R in 1 .. A.Row_Count loop
         if A.Lengths (R) /= B.Lengths (R) then
            return False;
         end if;
      end loop;
      return True;
   end Shape_Equal;

   function Equal (A, B : Tableau) return Boolean is
   begin
      if not Shape_Equal (A, B) then
         return False;
      end if;
      for R in 1 .. A.Row_Count loop
         for C in 1 .. A.Lengths (R) loop
            if A.Data (R)(C) /= B.Data (R)(C) then
               return False;
            end if;
         end loop;
      end loop;
      return True;
   end Equal;

   function Image (T : Tableau) return String is
      --  Fixed buffer large enough for Max_N x Max_N small integers.
      Buf  : String (1 .. Max_N * Max_N * 6 + Max_N);
      Last : Natural := 0;

      procedure Put (S : String) is
      begin
         Buf (Last + 1 .. Last + S'Length) := S;
         Last := Last + S'Length;
      end Put;

      procedure Put_Nat (N : Natural) is
         Tmp : String (1 .. 12);
         L   : Natural := Tmp'Last;
         V   : Natural := N;
      begin
         if V = 0 then
            Put ("0");
            return;
         end if;
         while V > 0 loop
            Tmp (L) := Character'Val (Character'Pos ('0') + V mod 10);
            V := V / 10;
            L := L - 1;
         end loop;
         Put (Tmp (L + 1 .. Tmp'Last));
      end Put_Nat;
   begin
      if T.Row_Count = 0 then
         return "(empty)";
      end if;
      for R in 1 .. T.Row_Count loop
         if R > 1 then
            Put ([1 => Character'Val (10)]);
         end if;
         for C in 1 .. T.Lengths (R) loop
            if C > 1 then
               Put (" ");
            end if;
            Put_Nat (T.Data (R)(C));
         end loop;
      end loop;
      return Buf (1 .. Last);
   end Image;

end Schensted;
