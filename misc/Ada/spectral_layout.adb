with Ada.Numerics.Elementary_Functions; use Ada.Numerics.Elementary_Functions;

package body Spectral_Layout is

   -- Internal matrix types for numerical computations
   type Matrix is array (Positive range <>, Positive range <>) of Float;
   type Vector is array (Positive range <>) of Float;

   type Sort_Direction is (Ascending, Descending);

   -- Helper: Verify matrix is square
   procedure Validate_Square (Graph : Adjacency_Matrix) is
   begin
      if Graph'Length (1) /= Graph'Length (2) then
         raise Invalid_Graph_Format with "Adjacency matrix must be square";
      end if;
   end Validate_Square;

   -- Helper: Compute degree of a specific node
   function Node_Degree (Graph : Adjacency_Matrix; Node : Node_Id) return Float is
      Deg : Float := 0.0;
   begin
      for J in Graph'Range (2) loop
         Deg := Deg + Graph (Node, J);
      end loop;
      return Deg;
   end Node_Degree;

   -- Helper: Jacobi Eigenvalue Algorithm for symmetric matrices
   -- Finds eigenvalues (Vals) and eigenvectors (Vecs) without external dependencies
   procedure Jacobi_Eigen (A : in Matrix; Vals : out Vector; Vecs : out Matrix) is
      N        : constant Natural := A'Length (1);
      Cur_A    : Matrix (1 .. N, 1 .. N);
      Max_Iter : constant := 2000;
      Eps      : constant Float := 1.0e-7;
      Max_Val  : Float;
      P, Q     : Positive;
      Angle, S, C : Float;
      Temp_A, Temp_V : Float;
   begin
      if N = 0 then
         return;
      end if;
      
      Cur_A := A;
      
      -- Initialize Eigenvectors to Identity matrix
      for I in 1 .. N loop
         for J in 1 .. N loop
            if I = J then
               Vecs (I, J) := 1.0;
            else
               Vecs (I, J) := 0.0;
            end if;
         end loop;
      end loop;

      -- Handle 1-node graphs safely
      if N = 1 then
         Vals (1) := Cur_A (1, 1);
         return;
      end if;

      -- Iterate to eliminate off-diagonal elements
      for Iter in 1 .. Max_Iter loop
         Max_Val := 0.0;
         P := 1; Q := 2;

         -- Find max off-diagonal element
         for I in 1 .. N - 1 loop
            for J in I + 1 .. N loop
               if abs (Cur_A (I, J)) > Max_Val then
                  Max_Val := abs (Cur_A (I, J));
                  P := I;
                  Q := J;
               end if;
            end loop;
         end loop;

         exit when Max_Val < Eps; -- Converged

         -- Calculate rotation angle (Fixed denominator mapping A_qq - A_pp)
         Angle := 0.5 * Arctan (2.0 * Cur_A (P, Q), Cur_A (Q, Q) - Cur_A (P, P));
         S := Sin (Angle);
         C := Cos (Angle);

         -- Apply Jacobi rotation to A
         for I in 1 .. N loop
            if I /= P and I /= Q then
               Temp_A := Cur_A (I, P);
               Cur_A (I, P) := C * Temp_A - S * Cur_A (I, Q);
               Cur_A (P, I) := Cur_A (I, P);
               Cur_A (I, Q) := S * Temp_A + C * Cur_A (I, Q);
               Cur_A (Q, I) := Cur_A (I, Q);
            end if;
         end loop;

         Temp_A := Cur_A (P, P);
         Cur_A (P, P) := C * C * Temp_A - 2.0 * S * C * Cur_A (P, Q) + S * S * Cur_A (Q, Q);
         Cur_A (Q, Q) := S * S * Temp_A + 2.0 * S * C * Cur_A (P, Q) + C * C * Cur_A (Q, Q);
         Cur_A (P, Q) := 0.0;
         Cur_A (Q, P) := 0.0;

         -- Apply rotation to Eigenvectors
         for I in 1 .. N loop
            Temp_V := Vecs (I, P);
            Vecs (I, P) := C * Temp_V - S * Vecs (I, Q);
            Vecs (I, Q) := S * Temp_V + C * Vecs (I, Q);
         end loop;
      end loop;

      -- Extract eigenvalues
      for I in 1 .. N loop
         Vals (I) := Cur_A (I, I);
      end loop;
   end Jacobi_Eigen;

   -- Helper: Sort eigenvalues and their corresponding eigenvectors
   procedure Sort_Eigen (Vals : in out Vector; Vecs : in out Matrix; Dir : Sort_Direction) is
      N : constant Natural := Vals'Length;
      Temp_Val : Float;
      Temp_Vec : Float;
      Swap_Needed : Boolean;
   begin
      if N < 2 then
         return;
      end if;

      for I in 1 .. N - 1 loop
         for J in I + 1 .. N loop
            Swap_Needed := False;
            if Dir = Ascending and then Vals (J) < Vals (I) then
               Swap_Needed := True;
            elsif Dir = Descending and then Vals (J) > Vals (I) then
               Swap_Needed := True;
            end if;

            if Swap_Needed then
               -- Swap Eigenvalues
               Temp_Val := Vals (I);
               Vals (I) := Vals (J);
               Vals (J) := Temp_Val;
               -- Swap Eigenvectors (Columns)
               for K in 1 .. N loop
                  Temp_Vec := Vecs (K, I);
                  Vecs (K, I) := Vecs (K, J);
                  Vecs (K, J) := Temp_Vec;
               end loop;
            end if;
         end loop;
      end loop;
   end Sort_Eigen;


   -- Variant 1: Unnormalized Laplacian (L = D - A)
   procedure Layout_Unnormalized_Laplacian (
      Graph  : in  Adjacency_Matrix;
      Layout : out Layout_Array
   ) is
      N : constant Natural := Graph'Length (1);
      L : Matrix (1 .. N, 1 .. N) := (others => (others => 0.0));
      Vals : Vector (1 .. N);
      Vecs : Matrix (1 .. N, 1 .. N);
      G_Idx, G_Jdx : Node_Id;
   begin
      Validate_Square (Graph);
      if N = 0 then return; end if;

      -- Build Unnormalized Laplacian Matrix
      for I in 1 .. N loop
         G_Idx := Node_Id (Integer (Graph'First (1)) + I - 1);
         L (I, I) := Node_Degree (Graph, G_Idx);
         for J in 1 .. N loop
            if I /= J then
               G_Jdx := Node_Id (Integer (Graph'First (2)) + J - 1);
               L (I, J) := -Graph (G_Idx, G_Jdx);
            end if;
         end loop;
      end loop;

      Jacobi_Eigen (L, Vals, Vecs);
      Sort_Eigen (Vals, Vecs, Ascending);

      -- Extract Coordinates
      for I in 1 .. N loop
         G_Idx := Node_Id (Integer (Layout'First) + I - 1);
         if N = 1 then
            Layout (G_Idx) := (0.0, 0.0);
         elsif N = 2 then
            Layout (G_Idx) := (Vecs (I, 2), 0.0);
         else
            Layout (G_Idx) := (Vecs (I, 2), Vecs (I, 3));
         end if;
      end loop;
   end Layout_Unnormalized_Laplacian;


   -- Variant 2: Normalized Laplacian
   procedure Layout_Normalized_Laplacian (
      Graph  : in  Adjacency_Matrix;
      Layout : out Layout_Array
   ) is
      N : constant Natural := Graph'Length (1);
      L_Norm : Matrix (1 .. N, 1 .. N) := (others => (others => 0.0));
      Vals : Vector (1 .. N);
      Vecs : Matrix (1 .. N, 1 .. N);
      Deg_I, Deg_J : Float;
      G_I, G_J : Node_Id;
   begin
      Validate_Square (Graph);
      if N = 0 then return; end if;

      -- Build Normalized Laplacian Matrix
      for I in 1 .. N loop
         G_I := Node_Id (Integer (Graph'First (1)) + I - 1);
         Deg_I := Node_Degree (Graph, G_I);
         for J in 1 .. N loop
            G_J := Node_Id (Integer (Graph'First (2)) + J - 1);
            Deg_J := Node_Degree (Graph, G_J);
            
            if I = J and then Deg_I > 0.0 then
               L_Norm (I, J) := 1.0;
            elsif I /= J and then Graph (G_I, G_J) > 0.0 then
               L_Norm (I, J) := -Graph (G_I, G_J) / Sqrt (Deg_I * Deg_J);
            end if;
         end loop;
      end loop;

      Jacobi_Eigen (L_Norm, Vals, Vecs);
      Sort_Eigen (Vals, Vecs, Ascending);

      -- Extract Coordinates
      for I in 1 .. N loop
         G_I := Node_Id (Integer (Layout'First) + I - 1);
         if N = 1 then
            Layout (G_I) := (0.0, 0.0);
         elsif N = 2 then
            Layout (G_I) := (Vecs (I, 2), 0.0);
         else
            Layout (G_I) := (Vecs (I, 2), Vecs (I, 3));
         end if;
      end loop;
   end Layout_Normalized_Laplacian;


   -- Variant 3: Adjacency Matrix
   procedure Layout_Adjacency (
      Graph  : in  Adjacency_Matrix;
      Layout : out Layout_Array
   ) is
      N : constant Natural := Graph'Length (1);
      A : Matrix (1 .. N, 1 .. N);
      Vals : Vector (1 .. N);
      Vecs : Matrix (1 .. N, 1 .. N);
      G_I, G_J : Node_Id;
   begin
      Validate_Square (Graph);
      if N = 0 then return; end if;

      for I in 1 .. N loop
         G_I := Node_Id (Integer (Graph'First (1)) + I - 1);
         for J in 1 .. N loop
            G_J := Node_Id (Integer (Graph'First (2)) + J - 1);
            A (I, J) := Graph (G_I, G_J);
         end loop;
      end loop;

      Jacobi_Eigen (A, Vals, Vecs);
      Sort_Eigen (Vals, Vecs, Descending); -- Descending for Adjacency

      for I in 1 .. N loop
         G_I := Node_Id (Integer (Layout'First) + I - 1);
         if N = 1 then
            Layout (G_I) := (0.0, 0.0);
         else
            Layout (G_I) := (Vecs (I, 1), Vecs (I, 2));
         end if;
      end loop;
   end Layout_Adjacency;

end Spectral_Layout;
