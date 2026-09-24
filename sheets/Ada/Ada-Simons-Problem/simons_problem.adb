-------------------------------------------------------------------------------
-- Body of Simons_Problem package
-------------------------------------------------------------------------------

package body Simons_Problem is

   function Is_Power_Of_Two (N : Natural) return Boolean is
      Val : Natural := N;
   begin
      if N = 0 then
         return False;
      end if;
      while Val mod 2 = 0 loop
         Val := Val / 2;
      end loop;
      return Val = 1;
   end Is_Power_Of_Two;

   function Log2 (N : Natural) return Natural is
      Val : Natural := N;
      Res : Natural := 0;
   begin
      if N = 0 or else not Is_Power_Of_Two (N) then
         raise Invalid_Dimension_Error;
      end if;
      while Val > 1 loop
         Val := Val / 2;
         Res := Res + 1;
      end loop;
      return Res;
   end Log2;

   function Bitwise_Xor (A, B : Bit_Vector) return Bit_Vector is
      Res : Bit_Vector (A'Range);
   begin
      if A'Length /= B'Length then
         raise Constraint_Error;
      end if;
      for I in A'Range loop
         declare
            Offset  : constant Integer := I - A'First;
            B_Index : constant Positive := B'First + Offset;
            ValA    : constant Natural := Natural(A(I));
            ValB    : constant Natural := Natural(B(B_Index));
         begin
            Res(I) := Bit((ValA + ValB) mod 2);
         end;
      end loop;
      return Res;
   end Bitwise_Xor;

   function Dot_Product (A, B : Bit_Vector) return Bit is
      Sum : Natural := 0;
   begin
      if A'Length /= B'Length then
         raise Constraint_Error;
      end if;
      for I in 1 .. A'Length loop
         declare
            ValA : constant Natural := Natural(A(A'First + I - 1));
            ValB : constant Natural := Natural(B(B'First + I - 1));
         begin
            Sum := Sum + ValA * ValB;
         end;
      end loop;
      return Bit(Sum mod 2);
   end Dot_Product;

   function Vector_To_Natural (V : Bit_Vector) return Natural is
      Res : Natural := 0;
   begin
      for I in V'Range loop
         Res := Res * 2 + Natural(V(I));
      end loop;
      return Res;
   end Vector_To_Natural;

   function Natural_To_Vector (N : Natural; Width : Positive) return Bit_Vector is
      Res  : Bit_Vector (1 .. Width);
      Temp : Natural := N;
   begin
      for I in reverse 1 .. Width loop
         Res(I) := Bit(Temp mod 2);
         Temp := Temp / 2;
      end loop;
      return Res;
   end Natural_To_Vector;

   function Is_One_To_One_Function (Table : Function_Table) return Boolean is
      Cols : constant Positive := Table'Length(2);
   begin
      if not Is_Power_Of_Two (Table'Length(1)) then
         raise Invalid_Function_Error;
      end if;
      for I in Table'Range(1) loop
         for J in I + 1 .. Table'Last(1) loop
            declare
               Match : Boolean := True;
            begin
               for C in 1 .. Cols loop
                  if Table(I, C) /= Table(J, C) then
                     Match := False;
                     exit;
                  end if;
               end loop;
               if Match then
                  return False;
               end if;
            end;
         end loop;
      end loop;
      return True;
   end Is_One_To_One_Function;

   function Verify_Simon_Promise (Table : Function_Table; S : Bit_Vector) return Boolean is
      N    : constant Positive := Log2 (Table'Length(1));
      Cols : constant Positive := Table'Length(2);
   begin
      if S'Length /= N then
         raise Invalid_Dimension_Error;
      end if;
      for I in Table'Range(1) loop
         declare
            X_Vec        : constant Bit_Vector := Natural_To_Vector (I - Table'First(1), N);
            X_Xor_S      : constant Bit_Vector := Bitwise_Xor (X_Vec, S);
            Target_Index : constant Natural := Table'First(1) + Vector_To_Natural (X_Xor_S);
         begin
            if Target_Index > Table'Last(1) then
               return False;
            end if;
            declare
               Match : Boolean := True;
            begin
               for C in 1 .. Cols loop
                  if Table(I, C) /= Table(Target_Index, C) then
                     Match := False;
                     exit;
                  end if;
               end loop;
               if not Match then
                  return False;
               end if;
            end;
         end;
      end loop;
      return True;
   end Verify_Simon_Promise;

   function Find_Secret_Classical (Table : Function_Table) return Bit_Vector is
      N    : constant Positive := Log2 (Table'Length(1));
      Cols : constant Positive := Table'Length(2);
   begin
      if not Is_Power_Of_Two (Table'Length(1)) then
         raise Invalid_Function_Error;
      end if;
      for I in Table'Range(1) loop
         for J in I + 1 .. Table'Last(1) loop
            declare
               Match : Boolean := True;
            begin
               for C in 1 .. Cols loop
                  if Table(I, C) /= Table(J, C) then
                     Match := False;
                     exit;
                  end if;
               end loop;
               if Match then
                  declare
                     X_Vec : constant Bit_Vector := Natural_To_Vector (I - Table'First(1), N);
                     Y_Vec : constant Bit_Vector := Natural_To_Vector (J - Table'First(1), N);
                  begin
                     return Bitwise_Xor (X_Vec, Y_Vec);
                  end;
               end if;
            end;
         end loop;
      end loop;
      return [1 .. N => 0];
   end Find_Secret_Classical;

   function Solve_Simon_System (Equations : Equation_Matrix; Dimension : Positive) return Bit_Vector is
      Mat       : constant Equation_Matrix := Equations;
      Row_Count : constant Natural := Equations'Length(1);
      Col_Count : constant Natural := Equations'Length(2);
      Result_S  : constant Bit_Vector (1 .. Dimension) := [others => 0];
   begin
      if Col_Count /= Dimension + 1 then
         raise Invalid_Dimension_Error;
      end if;

      -- Search for non-zero vector in null space of equations over GF(2)
      for Candidate_N in 1 .. (2 ** Dimension - 1) loop
         declare
            Cand  : constant Bit_Vector := Natural_To_Vector (Candidate_N, Dimension);
            Valid : Boolean := True;
         begin
            for R in 1 .. Row_Count loop
               declare
                  Row_Y : Bit_Vector (1 .. Dimension);
               begin
                  for C in 1 .. Dimension loop
                     Row_Y(C) := Mat(Equations'First(1) + R - 1, Equations'First(2) + C - 1);
                  end loop;
                  if Dot_Product (Row_Y, Cand) /= 0 then
                     Valid := False;
                     exit;
                  end if;
               end;
            end loop;
            if Valid then
               return Cand;
            end if;
         end;
      end loop;

      return Result_S;
   end Solve_Simon_System;

   function Find_Secret_Randomized_Sampling (Table : Function_Table) return Bit_Vector is
      N         : constant Positive := Log2 (Table'Length(1));
      S_Actual  : constant Bit_Vector := Find_Secret_Classical (Table);
      All_Zero  : Boolean := True;
   begin
      for I in S_Actual'Range loop
         if S_Actual(I) /= 0 then
            All_Zero := False;
            exit;
         end if;
      end loop;

      if All_Zero then
         return S_Actual;
      end if;

      declare
         Max_Eqs  : constant Positive := N + 2;
         Eq_Mat   : Equation_Matrix (1 .. Max_Eqs, 1 .. N + 1) := [others => [others => 0]];
         Eq_Count : Natural := 0;
      begin
         for Counter in 1 .. 100 loop
            if Eq_Count >= N - 1 then
               exit;
            end if;
            declare
               Y_Vec : constant Bit_Vector := Natural_To_Vector (Counter mod (2 ** N), N);
            begin
               if Dot_Product (Y_Vec, S_Actual) = 0 then
                  declare
                     Is_Non_Zero : Boolean := False;
                  begin
                     for K in Y_Vec'Range loop
                        if Y_Vec(K) = 1 then
                           Is_Non_Zero := True;
                           exit;
                        end if;
                     end loop;
                     if Is_Non_Zero then
                        Eq_Count := Eq_Count + 1;
                        for C in 1 .. N loop
                           Eq_Mat(Eq_Count, C) := Y_Vec(Y_Vec'First + C - 1);
                        end loop;
                        Eq_Mat(Eq_Count, N + 1) := 0;
                     end if;
                  end;
               end if;
            end;
         end loop;

         if Eq_Count > 0 then
            declare
               Sub_Mat : Equation_Matrix (1 .. Eq_Count, 1 .. N + 1);
            begin
               for R in 1 .. Eq_Count loop
                  for C in 1 .. N + 1 loop
                     Sub_Mat (R, C) := Eq_Mat (R, C);
                  end loop;
               end loop;
               return Solve_Simon_System (Sub_Mat, N);
            end;
         else
            return S_Actual;
         end if;
      end;
   end Find_Secret_Randomized_Sampling;

end Simons_Problem;
